// supabase/functions/admin-auth/index.ts
//
// Exchanges a verified Firebase ID token for a short-lived Supabase JWT that
// carries an admin identity.
//
// WHY THIS EXISTS
//   The student app authenticates to Supabase ANONYMOUSLY
//   (lib/data/services/ensure_supabase_auth.dart), so auth.uid() is a
//   throwaway uuid with no relationship to users.id (a Firebase UID). RLS
//   therefore cannot express "only your own row", and there is no admin role
//   concept anywhere in the codebase.
//
//   This function is the fix. It verifies a real Firebase ID token against
//   Google's public certs, checks the email against the `admins` table, and
//   mints a Supabase JWT signed with the project's JWT secret. That token is
//   what makes is_admin() (migration 0001) return true.
//
//   The admin Flutter app must NOT call ensureSupabaseAuth(). It calls this.
//
// Deploy with:
//   supabase functions deploy admin-auth --no-verify-jwt
//
//   --no-verify-jwt is required: the caller presents a FIREBASE token, not a
//   Supabase one, so the platform's own JWT check would reject it before this
//   code runs. Authentication is performed here instead, in full.
//
// Secrets required:
//   SUPABASE_URL              — auto-provided
//   SUPABASE_SERVICE_ROLE_KEY — auto-provided
//   SUPABASE_JWT_SECRET       — Project Settings -> API -> JWT Secret
//   FIREBASE_PROJECT_ID       — e.g. "matricmate-a1bf6"; must equal the token's
//                               `aud` and the tail of its `iss`

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const JWT_SECRET = Deno.env.get("SUPABASE_JWT_SECRET")!;
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

const GOOGLE_CERTS_URL =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

// ── Generic failure ──────────────────────────────────────────────────────
// Every rejection returns exactly this. Never leak whether an email exists,
// whether the password was wrong, or whether the account is merely inactive —
// that difference is a user-enumeration oracle.
function denied(): Response {
  return new Response(
    JSON.stringify({ error: "Access denied." }),
    { status: 403, headers: { "Content-Type": "application/json" } },
  );
}

// ── Google public cert handling ──────────────────────────────────────────

interface CertCache {
  certs: Record<string, string>;
  expiresAt: number;
}

let certCache: CertCache | null = null;

/** Fetches Google's x509 signing certs, honouring the Cache-Control max-age. */
async function fetchGoogleCerts(): Promise<Record<string, string>> {
  const now = Date.now();
  if (certCache && certCache.expiresAt > now) return certCache.certs;

  const res = await fetch(GOOGLE_CERTS_URL);
  if (!res.ok) throw new Error(`cert fetch failed: ${res.status}`);

  const certs = await res.json() as Record<string, string>;

  const cacheControl = res.headers.get("cache-control") ?? "";
  const maxAge = Number(/max-age=(\d+)/.exec(cacheControl)?.[1] ?? "3600");
  certCache = { certs, expiresAt: now + maxAge * 1000 };

  return certs;
}

function base64urlToUint8Array(input: string): Uint8Array {
  const b64 = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = b64.padEnd(b64.length + ((4 - (b64.length % 4)) % 4), "=");
  const raw = atob(padded);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}

function pemBodyToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN CERTIFICATE-----/, "")
    .replace(/-----END CERTIFICATE-----/, "")
    .replace(/\s/g, "");
  const raw = atob(b64);
  const buf = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buf);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buf;
}

/**
 * Extracts the RSA SubjectPublicKeyInfo from an x509 certificate.
 *
 * WebCrypto cannot import an x509 cert directly, only an SPKI key. Rather
 * than write a DER parser, locate the RSA SPKI prefix that precedes the
 * public key in every RS256 Firebase signing cert and import from there.
 */
async function importCertPublicKey(pem: string): Promise<CryptoKey> {
  const der = new Uint8Array(pemBodyToArrayBuffer(pem));

  // DER for: SEQUENCE { OID 1.2.840.113549.1.1.1 (rsaEncryption), NULL }
  const marker = [
    0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00,
  ];

  let idx = -1;
  outer:
  for (let i = 0; i + marker.length <= der.length; i++) {
    for (let j = 0; j < marker.length; j++) {
      if (der[i + j] !== marker[j]) continue outer;
    }
    idx = i;
    break;
  }
  if (idx === -1) throw new Error("no RSA OID in certificate");

  // The BIT STRING holding the key follows the algorithm identifier.
  let p = idx + marker.length;
  if (der[p] !== 0x03) throw new Error("expected BIT STRING");
  p++;

  // Read the DER length of the BIT STRING.
  let bitStringLen: number;
  if (der[p] < 0x80) {
    bitStringLen = der[p];
    p += 1;
  } else {
    const lenBytes = der[p] & 0x7f;
    p += 1;
    bitStringLen = 0;
    for (let i = 0; i < lenBytes; i++) bitStringLen = (bitStringLen << 8) | der[p + i];
    p += lenBytes;
  }

  // Skip the unused-bits octet.
  const keyStart = p + 1;
  const keyBytes = der.slice(keyStart, keyStart + bitStringLen - 1);

  // Rebuild a minimal SPKI: SEQUENCE { AlgorithmIdentifier, BIT STRING }.
  const bitString = new Uint8Array(keyBytes.length + 1);
  bitString[0] = 0x00;
  bitString.set(keyBytes, 1);

  const encodeLength = (len: number): number[] => {
    if (len < 0x80) return [len];
    const bytes: number[] = [];
    let n = len;
    while (n > 0) {
      bytes.unshift(n & 0xff);
      n >>= 8;
    }
    return [0x80 | bytes.length, ...bytes];
  };

  const bitStringTlv = [0x03, ...encodeLength(bitString.length), ...bitString];
  const inner = [...marker, ...bitStringTlv];
  const spki = new Uint8Array([0x30, ...encodeLength(inner.length), ...inner]);

  return crypto.subtle.importKey(
    "spki",
    spki.buffer as ArrayBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
}

interface FirebaseClaims {
  sub: string;
  email?: string;
  email_verified?: boolean;
  aud: string;
  iss: string;
  exp: number;
  iat: number;
  auth_time?: number;
}

/**
 * Verifies a Firebase ID token: RS256 signature against Google's certs, plus
 * the aud / iss / exp / sub checks Firebase documents as mandatory.
 *
 * Returns null on any failure — the caller maps that to a generic 403.
 */
async function verifyFirebaseIdToken(
  idToken: string,
): Promise<FirebaseClaims | null> {
  try {
    const parts = idToken.split(".");
    if (parts.length !== 3) return null;

    const header = JSON.parse(
      new TextDecoder().decode(base64urlToUint8Array(parts[0])),
    ) as { alg: string; kid: string };

    if (header.alg !== "RS256" || !header.kid) return null;

    const certs = await fetchGoogleCerts();
    const pem = certs[header.kid];
    if (!pem) return null;

    const key = await importCertPublicKey(pem);

    const valid = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      key,
      base64urlToUint8Array(parts[2]),
      new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
    );
    if (!valid) return null;

    const claims = JSON.parse(
      new TextDecoder().decode(base64urlToUint8Array(parts[1])),
    ) as FirebaseClaims;

    const now = Math.floor(Date.now() / 1000);

    if (claims.aud !== FIREBASE_PROJECT_ID) return null;
    if (claims.iss !== `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`) {
      return null;
    }
    if (claims.exp <= now) return null;
    if (claims.iat > now + 60) return null; // small clock-skew allowance
    if (!claims.sub) return null;
    if (!claims.email) return null;

    return claims;
  } catch (e) {
    console.error("verifyFirebaseIdToken failed:", e);
    return null;
  }
}

// ── Supabase JWT minting ─────────────────────────────────────────────────

/**
 * Mints a Supabase-compatible HS256 JWT.
 *
 * `role: "authenticated"` is what PostgREST switches the database role on.
 * `email` is what is_admin() matches. `app_role` carries admin vs superadmin
 * so the client can gate destructive UI without another round trip — but it
 * is advisory only: the database re-derives privilege from the `admins` table
 * on every call, so a forged app_role grants nothing.
 */
async function mintSupabaseJwt(
  firebaseUid: string,
  email: string,
  appRole: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(JWT_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );

  return await create(
    { alg: "HS256", typ: "JWT" },
    {
      sub: firebaseUid,
      email,
      role: "authenticated",
      app_role: appRole,
      aud: "authenticated",
      iss: "matricmate-admin-auth",
      iat: getNumericDate(0),
      exp: getNumericDate(60 * 60), // 1 hour
    },
    key,
  );
}

// ── Entry point ──────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }

  try {
    // Accept the token from either the Authorization header or the body.
    let idToken: string | null = null;

    const authHeader = req.headers.get("authorization") ?? "";
    if (authHeader.toLowerCase().startsWith("bearer ")) {
      idToken = authHeader.slice(7).trim();
    }

    if (!idToken) {
      const body = await req.json().catch(() => ({})) as {
        id_token?: string;
        idToken?: string;
      };
      idToken = body.id_token ?? body.idToken ?? null;
    }

    if (!idToken) return denied();

    const claims = await verifyFirebaseIdToken(idToken);
    if (!claims) return denied();

    // Look the email up in `admins`. Case-insensitive, matching is_admin().
    const { data: admin, error } = await supabase
      .from("admins")
      .select("firebase_uid, email, display_name, role, is_active")
      .ilike("email", claims.email!)
      .maybeSingle();

    if (error) {
      console.error("admin lookup failed:", error);
      return denied();
    }

    // Not an admin, or deactivated — indistinguishable to the caller.
    if (!admin || admin.is_active !== true) return denied();

    const token = await mintSupabaseJwt(claims.sub, admin.email, admin.role);

    // Best-effort; a failed timestamp write must not block a valid login.
    const { error: touchError } = await supabase
      .from("admins")
      .update({ last_login_at: new Date().toISOString() })
      .eq("firebase_uid", admin.firebase_uid);

    if (touchError) console.error("last_login_at update failed:", touchError);

    return new Response(
      JSON.stringify({
        access_token: token,
        expires_in: 3600,
        admin: {
          firebase_uid: admin.firebase_uid,
          email: admin.email,
          display_name: admin.display_name,
          role: admin.role,
          is_active: admin.is_active,
        },
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("admin-auth error:", e);
    return denied();
  }
});
