// supabase/functions/get-note-url/index.ts
//
// Generates a temporary Cloudflare R2 presigned GET URL for a requested note.
//
// Deploy with:
//   supabase functions deploy get-note-url --no-verify-jwt
//
// Secrets required:
//   SUPABASE_URL              — auto-provided by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-provided by Supabase
//   R2_ACCOUNT_ID             — Cloudflare Account ID
//   R2_ACCESS_KEY_ID          — Cloudflare R2 API Token Access Key ID
//   R2_SECRET_ACCESS_KEY      — Cloudflare R2 API Token Secret Access Key
//   R2_BUCKET_NAME            — e.g. "matricet-notes" (default: "matricet-notes")

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  S3Client,
  GetObjectCommand,
  HeadObjectCommand,
} from "npm:@aws-sdk/client-s3@^3.600.0";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@^3.600.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const R2_ACCOUNT_ID = Deno.env.get("R2_ACCOUNT_ID") ?? "";
const R2_ACCESS_KEY_ID = Deno.env.get("R2_ACCESS_KEY_ID") ?? "";
const R2_SECRET_ACCESS_KEY = Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "";
const R2_BUCKET_NAME = Deno.env.get("R2_BUCKET_NAME") || "matricet-notes";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  try {
    // 1. Authenticate user via Supabase Bearer token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const supabaseAdmin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const {
      data: { user },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // 2. Parse and validate request body
    let body: { note_id?: number | string };
    try {
      body = await req.json();
    } catch (_) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const noteId = Number(body.note_id);
    if (!noteId || isNaN(noteId)) {
      return new Response(
        JSON.stringify({ error: "Valid note_id is required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // 3. Query note metadata from Supabase
    const { data: note, error: noteError } = await supabaseAdmin
      .from("notes")
      .select("id, title, file_key, is_premium")
      .eq("id", noteId)
      .single();

    if (noteError || !note) {
      return new Response(
        JSON.stringify({ error: "Note not found" }),
        { status: 404, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    if (!note.file_key || typeof note.file_key !== "string" || note.file_key.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "PDF object not found" }),
        { status: 404, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const sanitizedKey = note.file_key.trim();
    // Prevent directory traversal
    if (sanitizedKey.includes("..")) {
      return new Response(
        JSON.stringify({ error: "Invalid file key format" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // 4. Verify user subscription if note is premium
    if (note.is_premium) {
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("subscription_status, subscription_expires_at")
        .eq("id", user.id)
        .single();

      if (userError || !userData) {
        return new Response(
          JSON.stringify({ error: "User profile not found" }),
          { status: 403, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
        );
      }

      const isUserActive =
        userData.subscription_status === "active" &&
        (!userData.subscription_expires_at ||
          new Date(userData.subscription_expires_at) > new Date());

      if (!isUserActive) {
        return new Response(
          JSON.stringify({ error: "Premium subscription required" }),
          { status: 403, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
        );
      }
    }

    // 5. Check R2 credentials
    if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
      console.error("Storage configuration error: Missing R2 environment variables");
      return new Response(
        JSON.stringify({ error: "Unable to generate signed URL" }),
        { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // 6. Initialize S3 client for Cloudflare R2
    const s3 = new S3Client({
      region: "auto",
      endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId: R2_ACCESS_KEY_ID,
        secretAccessKey: R2_SECRET_ACCESS_KEY,
      },
    });

    // 7. Check R2 object existence
    try {
      await s3.send(
        new HeadObjectCommand({
          Bucket: R2_BUCKET_NAME,
          Key: sanitizedKey,
        }),
      );
    } catch (headError: unknown) {
      const err = headError as { name?: string; $metadata?: { httpStatusCode?: number } };
      if (err?.name === "NotFound" || err?.$metadata?.httpStatusCode === 404) {
        return new Response(
          JSON.stringify({ error: "PDF object not found" }),
          { status: 404, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
        );
      }
      // Non-404 errors (such as network or transient) don't necessarily mean file doesn't exist
    }

    // 8. Generate Presigned URL (15 minutes expiry)
    const command = new GetObjectCommand({
      Bucket: R2_BUCKET_NAME,
      Key: sanitizedKey,
    });

    const expiresInSeconds = 900; // 15 minutes
    const signedUrl = await getSignedUrl(s3, command, {
      expiresIn: expiresInSeconds,
    });

    // Return signed URL without logging credentials or complete URL
    return new Response(
      JSON.stringify({
        url: signedUrl,
        expires_in: expiresInSeconds,
      }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : "Internal server error";
    console.error("Error in get-note-url:", errorMsg);
    return new Response(
      JSON.stringify({ error: "Unable to generate signed URL" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
});
