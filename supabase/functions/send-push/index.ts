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
//
// Called by Postgres triggers (see sql/notifications_schema.sql) with a
// body like:
//   { "event": "new_test", "test_id": 512, "subject_id": 7, "title": "...", "test_type": "entrance", ... }
//   { "event": "payment_status", "user_id": "uuid", "status": "active" }

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

async function sendFcmToTopic(
  topic: string,
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
        message: { topic, notification, data },
      }),
    },
  );
  if (!res.ok) {
    const errText = await res.text();
    console.error(`FCM topic send failed [${res.status}]:`, errText);
  }
}

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
        message: { token, notification, data },
      }),
    },
  );
  if (!res.ok) {
    const errText = await res.text();
    console.error(`FCM token send failed [${res.status}]:`, errText);
  }
}

// ── Event handlers ──────────────────────────────────────────────────────

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

  const topic = subject.is_common
    ? "all_users"
    : `stream_${targetStream}`;

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

  await sendFcmToTopic(
    topic,
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
}

async function handlePaymentStatus(body: PaymentStatusBody) {
  const { data: user } = await supabase
    .from("users")
    .select("fcm_token")
    .eq("id", body.user_id)
    .single();

  const { title, notifBody } = buildPaymentNotificationCopy(body.status);

  await supabase.from("notifications").insert({
    user_id: body.user_id,
    title,
    body: notifBody,
    type: "payment",
    target_stream: null,
    payload: { status: body.status },
  });

  if (user?.fcm_token) {
    await sendFcmToToken(
      user.fcm_token,
      { title, body: notifBody },
      { type: "payment", status: body.status },
    );
  }
}

// ── Entry point ──────────────────────────────────────────────────────────

interface EventBody {
  event: string;
  [key: string]: unknown;
}

Deno.serve(async (req: Request) => {
  try {
    const body = await req.json() as EventBody;

    switch (body.event) {
      case "new_test":
        await handleNewTest(body as unknown as NewTestBody);
        break;
      case "payment_status":
        await handlePaymentStatus(body as unknown as PaymentStatusBody);
        break;
      default:
        return new Response(JSON.stringify({ error: "unknown event" }), { status: 400 });
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
