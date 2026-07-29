// Haven Edge Function: upload-manual
// Admin endpoint for manually uploading equipment manual PDFs.
// Accepts a PDF file + model number + manual type, uploads to storage,
// and updates the equipment_manuals record.
//
// Usage:
//   POST /functions/v1/upload-manual
//   Content-Type: multipart/form-data
//   Fields:
//     - file: PDF file
//     - model_number: "RF29DB9900QDAA"
//     - manual_type: "owners_manual" | "installation_guide" | "spec_sheet" | etc.
//     - title: "Optional custom title"

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { requireAdminOrInternal } from "../_shared/require-household.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // July 2026 security sweep (audit S9): these batch/admin utilities were
  // fully unauthenticated in prod (arbitrary uploads, batch-job triggers,
  // Claude spend). Admin JWT (CHEZ_ADMIN_EMAILS), the internal secret, or
  // the service-role bearer are now required.
  if (!(await requireAdminOrInternal(req))) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const formData = await req.formData();
    const file = formData.get("file") as File | null;
    const modelNumber = formData.get("model_number") as string | null;
    const manualType = formData.get("manual_type") as string | null;
    const customTitle = formData.get("title") as string | null;

    if (!file || !modelNumber || !manualType) {
      return new Response(
        JSON.stringify({
          error: "Required fields: file, model_number, manual_type",
          valid_manual_types: [
            "owners_manual",
            "installation_guide",
            "service_manual",
            "spec_sheet",
            "quick_start_guide",
            "warranty_info",
            "parts_diagram",
            "troubleshooting_guide",
            "energy_guide",
          ],
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify it's a PDF
    const fileBuffer = await file.arrayBuffer();
    const header = new Uint8Array(fileBuffer.slice(0, 5));
    const isPdf =
      header[0] === 0x25 &&
      header[1] === 0x50 &&
      header[2] === 0x44 &&
      header[3] === 0x46;

    if (!isPdf) {
      return new Response(
        JSON.stringify({ error: "File is not a valid PDF" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Find the catalog entry
    const { data: catalogEntry, error: catalogError } = await supabase
      .from("equipment_catalog")
      .select(
        `
        id,
        model_number,
        model_name,
        equipment_manufacturers!inner (
          name,
          slug
        )
      `
      )
      .eq("model_number", modelNumber)
      .limit(1)
      .single();

    if (catalogError || !catalogEntry) {
      return new Response(
        JSON.stringify({
          error: `Model number "${modelNumber}" not found in catalog`,
        }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const manufacturer = (catalogEntry as any).equipment_manufacturers;
    const manufacturerSlug = manufacturer.slug;
    const storagePath = `${manufacturerSlug}/${modelNumber}/${manualType}.pdf`;
    const title =
      customTitle ?? `${catalogEntry.model_name} — ${manualType.replace(/_/g, " ")}`;

    // Upload to storage
    const { error: uploadError } = await supabase.storage
      .from("equipment-manuals")
      .upload(storagePath, fileBuffer, {
        contentType: "application/pdf",
        upsert: true,
      });

    if (uploadError) {
      throw new Error(`Upload failed: ${uploadError.message}`);
    }

    // Get the public URL
    const {
      data: { publicUrl },
    } = supabase.storage.from("equipment-manuals").getPublicUrl(storagePath);

    // Upsert the manual record
    const { data: existingManual } = await supabase
      .from("equipment_manuals")
      .select("id")
      .eq("catalog_entry_id", catalogEntry.id)
      .eq("manual_type", manualType)
      .limit(1)
      .single();

    if (existingManual) {
      // Update existing
      await supabase
        .from("equipment_manuals")
        .update({
          title,
          file_path: storagePath,
          file_size_bytes: fileBuffer.byteLength,
          source_url: `manually_uploaded:${new Date().toISOString()}`,
          last_verified_at: new Date().toISOString(),
        })
        .eq("id", existingManual.id);
    } else {
      // Create new
      await supabase.from("equipment_manuals").insert({
        catalog_entry_id: catalogEntry.id,
        manual_type: manualType,
        title,
        file_path: storagePath,
        file_size_bytes: fileBuffer.byteLength,
        source_url: `manually_uploaded:${new Date().toISOString()}`,
        last_verified_at: new Date().toISOString(),
        language: "en",
      });
    }

    return new Response(
      JSON.stringify({
        status: "uploaded",
        model_number: modelNumber,
        manufacturer: manufacturer.name,
        manual_type: manualType,
        file_size_bytes: fileBuffer.byteLength,
        storage_path: storagePath,
        public_url: publicUrl,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
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
