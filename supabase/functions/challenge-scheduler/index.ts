// supabase/functions/challenge-scheduler/index.ts
// Cron job edge function: flips scheduled -> live at starts_at, and live -> closed at ends_at.
// - Challenge LIVE: sends Firebase FCM push to student devices (NO Supabase notification table insert).
// - Challenge CLOSED: flips status only (NO Supabase notification table insert, NO FCM push).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "matricmate-a1bf6";

function getSupabaseClient() {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
}

// ── Google OAuth2 Token for FCM (RS256 JWT Flow) ──────────────────────────────

function base64urlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/=+$/, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function encodeJsonBase64url(obj: unknown): string {
  return base64urlEncode(new TextEncoder().encode(JSON.stringify(obj)));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, "")
    .replace(/-----END[ A-Z0-9_-]+-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\r/g, "")
    .replace(/\n/g, "")
    .replace(/\s/g, "");
  const raw = atob(b64);
  const buf = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buf);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buf;
}

function parseJsonLenient(raw: string): any {
  const s = raw.trim();
  try {
    return JSON.parse(s);
  } catch (_) {}

  if (s.startsWith('"') && s.endsWith('"')) {
    try {
      return JSON.parse(JSON.parse(s));
    } catch (_) {}
  }

  if (!s.startsWith("{") && !s.startsWith("[")) {
    try {
      const decoded = atob(s);
      return JSON.parse(decoded);
    } catch (_) {}
  }

  try {
    const fixed = s
      .replace(/([{,]\s*)([a-zA-Z0-9_]+)\s*:/g, '$1"$2":')
      .replace(/'/g, '"');
    return JSON.parse(fixed);
  } catch (_) {}

  throw new Error(`SyntaxError parsing JSON (len: ${s.length})`);
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string | null> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }

  const rawSa = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!rawSa) {
    console.warn("FCM_SERVICE_ACCOUNT_JSON is not set in Supabase secrets");
    return null;
  }

  let serviceAccount: { client_email?: string; private_key?: string };
  try {
    serviceAccount = parseJsonLenient(rawSa);
  } catch (err) {
    console.error("Failed to parse FCM_SERVICE_ACCOUNT_JSON:", err);
    return null;
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    console.error("FCM_SERVICE_ACCOUNT_JSON is missing client_email or private_key");
    return null;
  }

  try {
    const header = { alg: "RS256", typ: "JWT" };
    const claim = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    };

    const unsigned = `${encodeJsonBase64url(header)}.${encodeJsonBase64url(claim)}`;
    const keyBuffer = pemToArrayBuffer(serviceAccount.private_key);
    const key = await crypto.subtle.importKey(
      "pkcs8",
      keyBuffer,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );

    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    );

    const jwt = `${unsigned}.${base64urlEncode(new Uint8Array(signature))}`;

    const res = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    if (!res.ok) {
      console.error(`Google OAuth2 token request failed [${res.status}]: ${await res.text()}`);
      return null;
    }

    const data = await res.json();
    if (!data.access_token) return null;

    cachedAccessToken = {
      token: data.access_token,
      expiresAt: now + (data.expires_in ?? 3600),
    };

    return data.access_token;
  } catch (err) {
    console.error("Scheduler FCM auth error:", err);
    return null;
  }
}

async function sendFcmToStream(
  stream: string | null,
  data: Record<string, string>,
) {
  try {
    const supabase = getSupabaseClient();
    let query = supabase
      .from("users")
      .select("fcm_token")
      .not("fcm_token", "is", null)
      .neq("fcm_token", "");

    if (stream && stream !== "both" && stream !== "common" && stream !== "all") {
      query = query.ilike("stream", stream);
    }

    const { data: users, error: userError } = await query;
    if (userError) {
      console.error("Scheduler FCM: failed to query users", userError);
      return;
    }

    const tokens: string[] = Array.from(
      new Set(
        (users ?? [])
          .map((u: { fcm_token?: string | null }) => u.fcm_token?.trim() ?? "")
          .filter((t) => t.length > 0)
      )
    );

    if (tokens.length === 0) {
      console.log(`Scheduler FCM: no valid tokens found for stream=${stream ?? "all"}`);
      return;
    }

    const accessToken = await getAccessToken();
    if (!accessToken) {
      console.error("Scheduler FCM: cannot send, failed to get access token");
      return;
    }

    console.log(`Scheduler FCM: sending to ${tokens.length} token(s), stream=${stream ?? "all"}`);

    // Data-only FCM messages — Flutter app displays foreground/background banner and handles navigation
    const batchSize = 50;
    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      await Promise.allSettled(
        batch.map((token) =>
          fetch(
            `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
            {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                message: {
                  token,
                  data,
                  android: {
                    priority: "high",
                  },
                  apns: {
                    headers: {
                      "apns-priority": "10",
                      "apns-push-type": "background",
                    },
                    payload: {
                      aps: {
                        "content-available": 1,
                        sound: "default",
                      },
                    },
                  },
                },
              }),
            },
          ),
        ),
      );
    }
  } catch (err) {
    console.error("Scheduler FCM broadcast error:", err);
  }
}

// ── Main Scheduler Entrypoint ─────────────────────────────────────────────────

Deno.serve(async (_req: Request) => {
  const supabase = getSupabaseClient();
  try {
    const now = new Date().toISOString();

    // 0. Expired scheduled challenges (ends_at <= now): flip directly to closed without notification/FCM
    await supabase
      .from("leaderboard_challenges")
      .update({ status: "closed" })
      .eq("status", "scheduled")
      .lte("ends_at", now);

    // 1. Flip scheduled -> live (Sends Firebase FCM push, NO Supabase notifications row inserted)
    const { data: newlyLive, error: liveErr } = await supabase
      .from("leaderboard_challenges")
      .update({ status: "live" })
      .eq("status", "scheduled")
      .lte("starts_at", now)
      .gt("ends_at", now)
      .select("id, title, audience, subject_id");

    if (liveErr) {
      console.error("Error flipping scheduled to live:", liveErr);
    } else if (newlyLive && newlyLive.length > 0) {
      console.log(`Flipped ${newlyLive.length} challenges to live`);

      for (const ch of newlyLive) {
        const { data: subject } = await supabase
          .from("subjects")
          .select("name")
          .eq("id", ch.subject_id)
          .single();

        const subjName = subject?.name ?? "Subject";
        const notifTitle = "🔥 Challenge is LIVE!";
        const notifBody = `${ch.title} (${subjName}) is now open. Test your skills and compete for the leaderboard!`;
        const targetStream = ch.audience === "both" ? null : ch.audience;

        // Broadcast high-priority FCM push notification to student devices
        await sendFcmToStream(
          targetStream,
          {
            type: "challenge_live",
            challenge_id: String(ch.id),
            title: notifTitle,
            body: notifBody,
          },
        );
      }
    }

    // 2. Flip live -> closed (no notification inserted, no FCM sent)
    const { data: newlyClosed, error: closeErr } = await supabase
      .from("leaderboard_challenges")
      .update({ status: "closed" })
      .eq("status", "live")
      .lte("ends_at", now)
      .select("id, title, audience, subject_id");

    if (closeErr) {
      console.error("Error flipping live to closed:", closeErr);
    } else if (newlyClosed && newlyClosed.length > 0) {
      console.log(`Flipped ${newlyClosed.length} challenges to closed (no notification, no FCM)`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        live_count: newlyLive?.length ?? 0,
        closed_count: newlyClosed?.length ?? 0,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err: any) {
    console.error("Scheduler error:", err);
    return new Response(
      JSON.stringify({ error: err.message ?? String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
