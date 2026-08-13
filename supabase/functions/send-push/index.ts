// supabase/functions/send-push/index.ts
//
// Deploy with:
//   supabase functions deploy send-push
//
// Secrets required (set via `supabase secrets set` or the dashboard):
//   FCM_SERVICE_ACCOUNT_JSON  — full JSON of the Firebase service account key
//                               (Project Settings → Service Accounts → Generate new private key)
//   FCM_PROJECT_ID            — e.g. "matricmate-a1bf6"
//   SUPABASE_URL              — auto-provided by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-provided by Supabase
//   PUSH_WEBHOOK_SECRET       — shared secret required in the
//                               `x-webhook-secret` request header
//
// Called by Postgres triggers (see sql/notifications_schema.sql) with a
// body like:
//   { "event": "new_test", "test_id": 512, "subject_id": 7, "title": "...", "test_type": "entrance", ... }
//   { "event": "payment_status", "user_id": "uuid", "status": "active" }
//   { "event": "announcement", "title": "...", "body": "...", "audience": "all" }
//
// ⚠️ BREAKING CHANGE — every caller must now send the header
//        x-webhook-secret: <PUSH_WEBHOOK_SECRET>
//    Any existing Postgres trigger that calls this function WILL START
//    401-ing until it is updated to send the header. The function's original
//    header comment references `sql/notifications_schema.sql`, which does not
//    exist in the repository — if those triggers live only in the remote
//    database, find them before deploying this:
//
//      SELECT p.proname, pg_get_functiondef(p.oid)
//      FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
//      WHERE n.nspname = 'public'
//        AND (p.prosrc ILIKE '%send-push%' OR p.prosrc ILIKE '%net.http_post%');
//
//    Why this gate exists: Deno.serve previously acted on ANY POST, and
//    Supabase's default verify_jwt is satisfied by the anon key that ships
//    inside the student APK. Anyone could forge
//        {"event":"payment_status","user_id":"<any>","status":"active"}
//    and grant themselves premium.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT = JSON.parse(
  Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!,
);

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// ── Google OAuth2 token for FCM HTTP v1 (service-account JWT flow) ─────────

/** Base64url-encodes a Uint8Array without using spread (avoids stack overflow
 *  on large buffers) and without relying on btoa's Latin-1 limitation. */
function base64urlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
}

/** Safely encodes any JSON-serialisable object to base64url via UTF-8. */
function encodeJsonBase64url(obj: unknown): string {
  return base64urlEncode(new TextEncoder().encode(JSON.stringify(obj)));
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const unsigned = `${encodeJsonBase64url(header)}.${encodeJsonBase64url(claim)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(FCM_SERVICE_ACCOUNT.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );

  // Use the loop-based encoder to avoid stack overflow on large signatures.
  const encodedSig = base64urlEncode(new Uint8Array(signature));

  const jwt = `${unsigned}.${encodedSig}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  return data.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const raw = atob(b64);
  const buf = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buf);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buf;
}

// ── FCM senders ──────────────────────────────────────────────────────────

async function sendFcmToToken(
  token: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
) {
  const accessToken = await getAccessToken();
  const res = await fetch(
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
          notification,
          data,
          android: {
            priority: "high",
            notification: {
              channel_id: "matricmate_default",
              notification_priority: "PRIORITY_MAX",
              default_sound: true,
              default_vibrate_timings: true,
            },
          },
          apns: {
            headers: {
              // apns-priority 10 = immediate delivery (required for visible alerts)
              "apns-priority": "10",
            },
            payload: {
              aps: {
                alert: {
                  title: notification.title,
                  body: notification.body,
                },
                sound: "default",
                // NOTE: do NOT set content-available:1 here — that flag tells
                // iOS to treat the push as silent/background-only, which
                // suppresses the banner even when a notification object is present.
              },
            },
          },
        },
      }),
    },
  );
  if (!res.ok) {
    const errText = await res.text();
    console.error(`FCM token send failed [${res.status}]:`, errText);
  }
}

/**
 * Sends an FCM push to every user whose `stream` column matches [stream],
 * or to ALL users when [stream] is null/undefined (global broadcast).
 *
 * This replaces topic-based delivery (stream_natural / stream_social /
 * all_users), which only works if every student's app calls
 * subscribeToTopic() — something we cannot rely on.
 *
 * Tokens are fetched directly from the `users` table and each message is
 * sent individually. Failed/invalid tokens are logged but do not abort the
 * rest of the fan-out.
 *
 * NOTE: stream value in the DB is whatever the admin/student saves —
 * this function queries case-insensitively by lowercasing both sides
 * using Postgres ilike, but the simplest approach is to query for both
 * capitalisation variants or use ilike via a raw filter.
 * We use .ilike() which is Postgres ILIKE — works regardless of case.
 */
async function sendFcmToStream(
  stream: string | null,
  notification: { title: string; body: string },
  data: Record<string, string>,
) {
  let query = supabase
    .from("users")
    .select("fcm_token")
    .not("fcm_token", "is", null);

  if (stream) {
    // Use ilike for case-insensitive match — covers 'natural', 'Natural', 'NATURAL'
    query = query.ilike("stream", stream);
  }

  const { data: users, error } = await query;
  if (error) {
    console.error("sendFcmToStream: failed to fetch tokens", error);
    return;
  }

  const tokens: string[] = (users ?? [])
    .map((u: { fcm_token?: string | null }) => u.fcm_token ?? "")
    .filter(Boolean);

  console.log(`sendFcmToStream: stream=${stream ?? "all"} → ${tokens.length} token(s)`);

  if (tokens.length === 0) return;

  // Get the access token once and reuse it across all sends.
  const accessToken = await getAccessToken();

  const results = await Promise.allSettled(
    tokens.map((token) =>
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
              notification,
              data,
              android: {
                priority: "high",
                notification: {
                  channel_id: "matricmate_default",
                  notification_priority: "PRIORITY_MAX",
                  default_sound: true,
                  default_vibrate_timings: true,
                },
              },
              apns: {
                headers: {
                  "apns-priority": "10",
                },
                payload: {
                  aps: {
                    alert: {
                      title: notification.title,
                      body: notification.body,
                    },
                    sound: "default",
                    // No content-available — keeps it a visible push, not silent.
                  },
                },
              },
            },
          }),
        },
      ).then(async (res) => {
        if (!res.ok) {
          const errText = await res.text();
          console.error(`FCM token send failed [${res.status}] token=${token.slice(0, 20)}...:`, errText);
        }
      }),
    ),
  );

  const failed = results.filter((r) => r.status === "rejected").length;
  if (failed > 0) {
    console.warn(`sendFcmToStream: ${failed}/${tokens.length} sends failed`);
  }
}

function buildNewTestNotificationCopy(
  testType: string,
  subjectName: string,
  testTitle: string,
): { title: string; notifBody: string } {
  switch (testType) {
    case "chapter":
      return {
        title: "New chapter test",
        notifBody: `A new chapter test for ${subjectName} is now available`,
      };
    case "grade":
      return {
        title: "New grade test",
        notifBody: `A new grade test for ${subjectName} is now available`,
      };
    case "entrance":
      return {
        title: "New entrance exam",
        notifBody: `A new entrance exam for ${subjectName} is now available`,
      };
    case "model":
      return {
        title: "New model exam",
        notifBody: `A new model exam for ${subjectName} is now available`,
      };
    default:
      return {
        title: "New exam added",
        notifBody: `${testTitle} is now available for ${subjectName}`,
      };
  }
}

interface NewTestBody {
  test_id: number;
  subject_id: number;
  test_type: string;
  title?: string;
  grade?: number | string;
  chapter_id?: number | string;
  chapter?: string;
  chapter_number?: number | string;
}

async function handleNewTest(body: NewTestBody) {
  // Guard against malformed trigger payloads.
  if (!body.test_id || !body.subject_id) {
    console.error("handleNewTest: missing test_id or subject_id", body);
    return;
  }

  const { data: subject } = await supabase
    .from("subjects")
    .select("name, is_natural, is_common")
    .eq("id", body.subject_id)
    .single();

  if (!subject) return;

  const targetStream = subject.is_common
    ? null
    : (subject.is_natural ? "natural" : "social");

  const { title, notifBody } = buildNewTestNotificationCopy(
    body.test_type,
    subject.name,
    body.title ?? "",
  );

  // Build payload with conditional spread — no undefined values so
  // JSON.stringify never silently drops keys.
  const payload: Record<string, string> = {
    test_type: body.test_type,
    test_id: String(body.test_id),
    subject_id: String(body.subject_id),
    subject: subject.name,
    ...(body.grade != null && { grade: String(body.grade) }),
    ...(body.chapter_id != null && { chapter_id: String(body.chapter_id) }),
    ...(body.chapter != null && { chapter: String(body.chapter) }),
    ...(body.chapter_number != null && { chapter_number: String(body.chapter_number) }),
  };

  await supabase.from("notifications").insert({
    user_id: null,
    title,
    body: notifBody,
    type: "new_content",
    target_stream: targetStream,
    payload,
  });

  // Fan-out to individual tokens — topic subscription not required on client.
  // null targetStream means common subject → send to all users.
  await sendFcmToStream(
    targetStream,
    { title, body: notifBody },
    { type: "new_content", ...payload },
  );
}

function buildPaymentNotificationCopy(
  status: string,
): { title: string; notifBody: string } {
  switch (status) {
    case "active":
      return {
        title: "Payment Approved! 🎉",
        notifBody: "Your premium access is now active. Enjoy full access to all tests!",
      };
    case "pending":
      return {
        title: "Payment Pending",
        notifBody: "Your payment is still being processed. We'll notify you once it's confirmed.",
      };
    case "rejected":
      return {
        title: "Payment Rejected",
        notifBody: "Your payment could not be processed. Please try again or contact support.",
      };
    default:
      return {
        title: "Payment Update",
        notifBody: `Your payment status has been updated to "${status}".`,
      };
  }
}

interface PaymentStatusBody {
  user_id: string;
  status: string;
  title?: string;          // optional override from admin — uses default if absent
  body?: string;           // optional override from admin — uses default if absent
  rejection_reason?: string; // shown in-app notification payload
}

async function handlePaymentStatus(body: PaymentStatusBody) {
  const { data: user } = await supabase
    .from("users")
    .select("fcm_token")
    .eq("id", body.user_id)
    .single();

  // Use admin-supplied copy if provided, otherwise fall back to defaults.
  const defaults = buildPaymentNotificationCopy(body.status);
  const title    = (body.title?.trim())  || defaults.title;
  const notifBody = (body.body?.trim())  || defaults.notifBody;

  // Build notification payload — include rejection reason if present.
  const notifPayload: Record<string, unknown> = { status: body.status };
  if (body.rejection_reason?.trim()) {
    notifPayload.rejection_reason = body.rejection_reason.trim();
  }

  await supabase.from("notifications").insert({
    user_id: body.user_id,
    title,
    body: notifBody,
    type: "payment",
    target_stream: null,
    payload: notifPayload,
  });

  if (user?.fcm_token) {
    const data: Record<string, string> = {
      type: "payment",
      status: body.status,
    };
    if (body.rejection_reason?.trim()) {
      data.rejection_reason = body.rejection_reason.trim();
    }
    await sendFcmToToken(
      user.fcm_token,
      { title, body: notifBody },
      data,
    );
  }
}

// ── Announcement ─────────────────────────────────────────────────────────

interface AnnouncementBody {
  title: string;
  body: string;
  audience: "all" | "stream" | "user";
  target_stream?: string | null;
  user_id?: string | null;
  payload?: Record<string, unknown> | null;
  created_by?: string | null;
}

/**
 * Free-form announcements from the admin console.
 *
 * Delivery strategy — no FCM topic subscriptions required on the client:
 *
 *   all    -> user_id NULL, target_stream NULL   -> sendFcmToStream(null)   → all tokens
 *   stream -> user_id NULL, target_stream set    -> sendFcmToStream(stream) → matching stream tokens
 *   user   -> user_id set,  target_stream NULL   -> sendFcmToToken          → single token
 *
 * The inserted row deliberately uses a jsonb OBJECT for `payload` and a real
 * BOOLEAN for `is_read`. The student app's AppNotification.toMap() emits
 * payload as a JSON *string* and is_read as 0/1, which is SQLite-shaped and
 * wrong for Postgres — do not reuse it for writes here.
 */
async function handleAnnouncement(body: AnnouncementBody) {
  if (!body.title || !body.body) {
    console.error("handleAnnouncement: missing title or body");
    return { ok: false, error: "missing title or body" };
  }

  const audience = body.audience ?? "all";

  let rowUserId: string | null = null;
  let targetStream: string | null = null;
  let token: string | null = null;

  if (audience === "stream") {
    if (body.target_stream !== "natural" && body.target_stream !== "social") {
      return { ok: false, error: "target_stream must be natural or social" };
    }
    targetStream = body.target_stream;
    // No topic — fan-out to individual tokens by stream column.
  } else if (audience === "user") {
    if (!body.user_id) {
      return { ok: false, error: "user_id is required for audience 'user'" };
    }
    rowUserId = body.user_id;

    const { data: user } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", body.user_id)
      .single();

    // No token is not an error — the row is still inserted so the student
    // sees it in-app the next time they open the notifications screen.
    token = user?.fcm_token ?? null;
  }
  // audience === "all": rowUserId and targetStream stay null — sendFcmToStream(null) fans out to everyone.

  const { data: inserted, error: insertError } = await supabase
    .from("notifications")
    .insert({
      user_id: rowUserId,
      title: body.title,
      body: body.body,
      type: "announcement",
      target_stream: targetStream,
      payload: body.payload ?? {},
      is_read: false,
      ...(body.created_by != null && { created_by: body.created_by }),
    })
    .select("id")
    .single();

  if (insertError) {
    console.error("handleAnnouncement: insert failed", insertError);
    return { ok: false, error: insertError.message };
  }

  // Every FCM data value must be a String. `type: "announcement"` routes the
  // client's _handleTap default branch to Routes.notifications.
  const data: Record<string, string> = {
    type: "announcement",
    notification_id: String(inserted?.id ?? ""),
  };

  let fcmSent = false;
  try {
    if (audience === "user" && token) {
      // Single user — send directly to their token.
      await sendFcmToToken(token, { title: body.title, body: body.body }, data);
      fcmSent = true;
    } else if (audience === "stream") {
      // Stream broadcast — fan-out to all tokens with matching stream column.
      await sendFcmToStream(targetStream, { title: body.title, body: body.body }, data);
      fcmSent = true;
    } else {
      // Global broadcast — fan-out to ALL tokens (stream = null means everyone).
      await sendFcmToStream(null, { title: body.title, body: body.body }, data);
      fcmSent = true;
    }
  } catch (e) {
    console.error("handleAnnouncement: FCM send failed", e);
  }

  return { ok: true, notification_id: inserted?.id ?? null, fcm_sent: fcmSent };
}

// ── Entry point ──────────────────────────────────────────────────────────

interface EventBody {
  event: string;
  [key: string]: unknown;
}

Deno.serve(async (req: Request) => {
  // Shared-secret gate — the very first statement, before the body is even
  // read, so an unauthorised caller cannot trigger any work.
  if (
    req.headers.get("x-webhook-secret") !== Deno.env.get("PUSH_WEBHOOK_SECRET")
  ) {
    return new Response("unauthorized", { status: 401 });
  }

  try {
    const body = await req.json() as EventBody;

    switch (body.event) {
      case "new_test":
        await handleNewTest(body as unknown as NewTestBody);
        break;
      case "payment_status":
        await handlePaymentStatus(body as unknown as PaymentStatusBody);
        break;
      case "announcement": {
        const result = await handleAnnouncement(
          body as unknown as AnnouncementBody,
        );
        return new Response(JSON.stringify(result), {
          status: result.ok ? 200 : 400,
          headers: { "Content-Type": "application/json" },
        });
      }
      default:
        return new Response(JSON.stringify({ error: "unknown event" }), { status: 400 });
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
