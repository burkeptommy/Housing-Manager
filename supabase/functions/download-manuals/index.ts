// Haven Edge Function: download-manuals
// Downloads equipment manual PDFs from manufacturer source URLs and uploads
// them to the equipment-manuals storage bucket. Updates file_size_bytes and
// last_verified_at on success. Designed to run as a batch job (cron monthly)
// or on-demand for specific models.
//
// Usage:
//   POST /functions/v1/download-manuals
//   Body: { "batch_size": 50 }                    — process next 50 undownloaded manuals
//   Body: { "manufacturer_slug": "carrier" }      — process all manuals for a brand
//   Body: { "manual_id": "uuid" }                 — process a single manual
//   Body: { "verify_only": true, "batch_size": 100 } — just verify URLs, don't download

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface DownloadResult {
  manual_id: string;
  model_number: string;
  manufacturer: string;
  manual_type: string;
  status: "downloaded" | "failed" | "skipped" | "verified";
  file_size_bytes?: number;
  error?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch(() => ({}));
    const batchSize = body.batch_size ?? 25;
    const manufacturerSlug = body.manufacturer_slug ?? null;
    const manualId = body.manual_id ?? null;
    const verifyOnly = body.verify_only ?? false;

    // Build query for manuals to process
    let query = supabase
      .from("equipment_manuals")
      .select(`
        id,
        manual_type,
        title,
        source_url,
        file_path,
        file_size_bytes,
        last_verified_at,
        catalog_entry_id,
        equipment_catalog!inner (
          model_number,
          model_name,
          manufacturer_id,
          equipment_manufacturers!inner (
            name,
            slug
          )
        )
      `);

    if (manualId) {
      query = query.eq("id", manualId);
    } else if (manufacturerSlug) {
      query = query.eq(
        "equipment_catalog.equipment_manufacturers.slug",
        manufacturerSlug
      );
    }

    // Only process manuals that haven't been downloaded yet (no file_size_bytes)
    // or that haven't been verified recently (older than 30 days)
    if (!manualId) {
      if (verifyOnly) {
        // Re-verify manuals that were last checked > 30 days ago
        const thirtyDaysAgo = new Date(
          Date.now() - 30 * 24 * 60 * 60 * 1000
        ).toISOString();
        query = query.or(
          `last_verified_at.is.null,last_verified_at.lt.${thirtyDaysAgo}`
        );
      } else {
        // Download manuals that don't have file_size_bytes yet
        query = query.is("file_size_bytes", null);
      }
    }

    query = query.limit(batchSize);

    const { data: manuals, error: queryError } = await query;

    if (queryError) {
      throw new Error(`Query error: ${queryError.message}`);
    }

    if (!manuals || manuals.length === 0) {
      return new Response(
        JSON.stringify({
          message: "No manuals to process",
          processed: 0,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`[download-manuals] Processing ${manuals.length} manuals...`);

    const results: DownloadResult[] = [];

    for (const manual of manuals) {
      const catalog = (manual as any).equipment_catalog;
      const manufacturer = catalog?.equipment_manufacturers;
      const modelNumber = catalog?.model_number ?? "unknown";
      const manufacturerName = manufacturer?.name ?? "unknown";
      const manufacturerSlugVal = manufacturer?.slug ?? "unknown";

      try {
        // Skip if source_url is just a generic support page (no direct PDF)
        const sourceUrl = manual.source_url;
        if (!sourceUrl || sourceUrl.length < 10) {
          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: "skipped",
            error: "No source URL",
          });
          continue;
        }

        if (verifyOnly) {
          // Just check if the URL is still accessible
          const headResp = await fetch(sourceUrl, {
            method: "HEAD",
            signal: AbortSignal.timeout(10000),
          });

          await supabase
            .from("equipment_manuals")
            .update({ last_verified_at: new Date().toISOString() })
            .eq("id", manual.id);

          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: headResp.ok ? "verified" : "failed",
            error: headResp.ok
              ? undefined
              : `HTTP ${headResp.status}`,
          });
          continue;
        }

        // Download the PDF
        console.log(
          `[download-manuals] Downloading: ${manufacturerSlugVal}/${modelNumber}/${manual.manual_type}`
        );

        const response = await fetch(sourceUrl, {
          signal: AbortSignal.timeout(30000),
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Haven/1.0",
            Accept: "application/pdf,*/*",
          },
        });

        if (!response.ok) {
          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: "failed",
            error: `HTTP ${response.status} from ${new URL(sourceUrl).hostname}`,
          });

          // Update last_verified_at even on failure so we don't retry immediately
          await supabase
            .from("equipment_manuals")
            .update({ last_verified_at: new Date().toISOString() })
            .eq("id", manual.id);

          continue;
        }

        const contentType = response.headers.get("content-type") ?? "";
        const pdfData = await response.arrayBuffer();
        const fileSize = pdfData.byteLength;

        // Skip if response is too small (likely an error page, not a PDF)
        if (fileSize < 1000) {
          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: "failed",
            error: `Response too small (${fileSize} bytes) — likely not a PDF`,
          });
          continue;
        }

        // Verify it's actually a PDF by checking magic bytes (%PDF-)
        const header = new Uint8Array(pdfData.slice(0, 5));
        const isPdf = header[0] === 0x25 && header[1] === 0x50 &&
                      header[2] === 0x44 && header[3] === 0x46;

        if (!isPdf) {
          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: "failed",
            error: `Response is not a PDF (content-type: ${contentType})`,
          });

          await supabase
            .from("equipment_manuals")
            .update({ last_verified_at: new Date().toISOString() })
            .eq("id", manual.id);

          continue;
        }

        // Upload to storage bucket — always use application/pdf
        const storagePath = manual.file_path;
        const { error: uploadError } = await supabase.storage
          .from("equipment-manuals")
          .upload(storagePath, pdfData, {
            contentType: "application/pdf",
            upsert: true,
          });

        if (uploadError) {
          results.push({
            manual_id: manual.id,
            model_number: modelNumber,
            manufacturer: manufacturerName,
            manual_type: manual.manual_type,
            status: "failed",
            error: `Upload failed: ${uploadError.message}`,
          });
          continue;
        }

        // Update the manual record with file size and verification timestamp
        await supabase
          .from("equipment_manuals")
          .update({
            file_size_bytes: fileSize,
            last_verified_at: new Date().toISOString(),
          })
          .eq("id", manual.id);

        results.push({
          manual_id: manual.id,
          model_number: modelNumber,
          manufacturer: manufacturerName,
          manual_type: manual.manual_type,
          status: "downloaded",
          file_size_bytes: fileSize,
        });

        console.log(
          `[download-manuals] ✓ ${manufacturerSlugVal}/${modelNumber}/${manual.manual_type} (${(fileSize / 1024).toFixed(0)} KB)`
        );
      } catch (err) {
        const errorMessage =
          err instanceof Error ? err.message : "Unknown error";
        results.push({
          manual_id: manual.id,
          model_number: modelNumber,
          manufacturer: manufacturerName,
          manual_type: manual.manual_type,
          status: "failed",
          error: errorMessage,
        });
      }
    }

    const downloaded = results.filter((r) => r.status === "downloaded").length;
    const failed = results.filter((r) => r.status === "failed").length;
    const skipped = results.filter((r) => r.status === "skipped").length;
    const verified = results.filter((r) => r.status === "verified").length;

    console.log(
      `[download-manuals] Complete: ${downloaded} downloaded, ${failed} failed, ${skipped} skipped, ${verified} verified`
    );

    return new Response(
      JSON.stringify({
        processed: results.length,
        downloaded,
        failed,
        skipped,
        verified,
        results,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error(`[download-manuals] Error: ${err}`);
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
