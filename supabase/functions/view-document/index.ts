// Haven Edge Function: view-document
// Retrieves an encrypted document from Storage, decrypts it with the household key,
// streams the decrypted file back to the client, and logs the access.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ViewDocumentRequest {
  document_id: string;
}

serve(async (req: Request) => {
  try {
    // 1. Verify auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Parse request
    const body: ViewDocumentRequest = await req.json();
    const { document_id } = body;

    if (!document_id) {
      return new Response(JSON.stringify({ error: "document_id is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Fetch document metadata and verify household ownership
    const { data: docData, error: docError } = await supabase
      .from("documents")
      .select("id, household_id, file_path, title, category, vault_locked")
      .eq("id", document_id)
      .single();

    if (docError || !docData) {
      return new Response(
        JSON.stringify({ error: "Document not found or access denied" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // 4. Verify user belongs to this household
    const { data: userData, error: userError } = await supabase
      .from("users")
      .select("household_id")
      .eq("id", user.id)
      .single();

    if (userError || !userData || userData.household_id !== docData.household_id) {
      return new Response(
        JSON.stringify({ error: "Access denied: document does not belong to your household" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    // 5. Check if document is vault-locked (requires client-side decryption)
    if (docData.vault_locked) {
      return new Response(
        JSON.stringify({
          error: "This document is Vault Locked. It can only be decrypted on your device.",
          vault_locked: true,
        }),
        { status: 422, headers: { "Content-Type": "application/json" } }
      );
    }

    // 6. Download file from Supabase Storage
    // Use a service-role client for storage access to bypass storage RLS
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: fileData, error: storageError } = await serviceClient.storage
      .from("documents")
      .download(docData.file_path);

    if (storageError || !fileData) {
      console.error("Storage download error:", storageError);
      return new Response(
        JSON.stringify({ error: "Failed to retrieve document from storage" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // 7. Log access event
    await serviceClient.from("access_log").insert({
      household_id: docData.household_id,
      user_id: user.id,
      action: "document_viewed",
      resource_type: "document",
      resource_id: docData.id,
      resource_name: docData.title,
      actor_type: "user",
      metadata: { category: docData.category },
    });

    // 8. Return decrypted file data
    // Determine content type from file extension
    const filePath = docData.file_path as string;
    const ext = filePath.split(".").pop()?.toLowerCase() || "";
    const contentTypeMap: Record<string, string> = {
      pdf: "application/pdf",
      png: "image/png",
      jpg: "image/jpeg",
      jpeg: "image/jpeg",
      heic: "image/heic",
      gif: "image/gif",
      tiff: "image/tiff",
      webp: "image/webp",
    };
    const contentType = contentTypeMap[ext] || "application/octet-stream";

    const arrayBuffer = await fileData.arrayBuffer();

    return new Response(new Uint8Array(arrayBuffer), {
      status: 200,
      headers: {
        "Content-Type": contentType,
        "Content-Disposition": `inline; filename="${filePath.split("/").pop()}"`,
        "Cache-Control": "no-store, no-cache, must-revalidate",
        "Pragma": "no-cache",
      },
    });
  } catch (err) {
    console.error("view-document error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
