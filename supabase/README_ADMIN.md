# MatricET admin backend — migrations and edge functions

Everything the admin console (`../../m_admin`) depends on server-side.

## Order of operations

1. Apply `migrations/0001_admin_foundation.sql`
2. Apply `migrations/0002_seed_admin.sql` (after creating the Firebase Auth account)
3. Set secrets, then deploy both edge functions

---

## 1. Migrations

There is no `supabase/config.toml` in this repo and the CLI link is stale
(`.temp/linked-project.json` exists but the CLI reports
`LegacyProjectNotLinkedError`). Either re-link:

```bash
supabase link --project-ref gcscoitnhdrqsibkxrit
supabase db push
```

…or paste the files into the Supabase SQL editor in order. `0001` is
idempotent and non-destructive, so a partial run can safely be re-run.

### Before applying 0001 — what to check in the dashboard

`0001` is additive and safe, but these facts were reconstructed from Dart call
sites (this repo has never had migrations), so confirm them first:

| Check | Why it matters |
|---|---|
| `users.id` is `text` | It holds a Firebase UID. Any policy using `auth.uid() = id` would lock the student app out. |
| `notifications.user_id` accepts a Firebase UID string | `send-push` inserts one at `index.ts:301`. If the column is really `uuid` as assumed, payment notifications are already failing in production. |
| `user_sessions.firebase_uid` is UNIQUE | `session_service.dart:17` uses `.maybeSingle()`, which throws `PGRST116` on duplicates. |
| `questions.section_id → question_sections.id` FK exists | Seven sync call sites use the PostgREST embed `question_sections(title)`, which resolves only through a declared FK. |
| RLS on `users` | **The important one.** If `anon` has UPDATE, a student can self-grant premium with the key inside the APK and the whole approval workflow is theatre. |

`0001` deliberately does not change RLS on any pre-existing table — most of
the student app runs as `anon` with no session at all, so enabling RLS blindly
would take it down. See the review block at the end of that file.

---

## 2. Edge function secrets

```bash
# Shared secret gating send-push (generate a strong random value)
supabase secrets set PUSH_WEBHOOK_SECRET="$(openssl rand -hex 32)"

# Needed by admin-auth
supabase secrets set SUPABASE_JWT_SECRET="<Project Settings -> API -> JWT Secret>"
supabase secrets set FIREBASE_PROJECT_ID="<e.g. matricmate-a1bf6>"
```

Already set for `send-push` (unchanged): `FCM_SERVICE_ACCOUNT_JSON`,
`FCM_PROJECT_ID`. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided
by the platform.

The same `PUSH_WEBHOOK_SECRET` value goes into `m_admin/.env`.

## 3. Deploy

```bash
supabase functions deploy send-push
supabase functions deploy admin-auth --no-verify-jwt
```

`--no-verify-jwt` on `admin-auth` is required: the caller presents a *Firebase*
ID token, not a Supabase one, so the platform's own JWT check would reject the
request before the function runs. The function performs full verification
itself — RS256 signature against Google's public certs, plus `aud`, `iss` and
`exp`.

## 4. ⚠️ Breaking change in `send-push`

`send-push` now returns **401** unless the request carries:

```
x-webhook-secret: <PUSH_WEBHOOK_SECRET>
```

Any existing Postgres trigger that calls it will start failing until updated.
The function's header comment references `sql/notifications_schema.sql`, which
does not exist anywhere in this repository — so if those triggers exist, they
live only in the remote database. Find them before deploying:

```sql
SELECT p.proname, pg_get_functiondef(p.oid)
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND (p.prosrc ILIKE '%send-push%' OR p.prosrc ILIKE '%net.http_post%');
```

Verify the gate is live (this 401 is also what the Phase 11 diagnostics screen
pings for):

```bash
curl -i -X POST "$SUPABASE_URL/functions/v1/send-push" \
  -H "Content-Type: application/json" \
  -d '{"event":"announcement","title":"t","body":"b","audience":"all"}'
# expect: HTTP/1.1 401 unauthorized
```

## Events accepted by `send-push`

| event | body | delivery |
|---|---|---|
| `new_test` | `{test_id, subject_id, test_type, title?, grade?, chapter_id?, chapter?, chapter_number?}` | broadcast row + topic |
| `payment_status` | `{user_id, status}` | personal row + token |
| `announcement` *(new)* | `{title, body, audience: all\|stream\|user, target_stream?, user_id?, payload?, created_by?}` | per audience |

`announcement` inserts `payload` as a jsonb **object** and `is_read` as a real
**boolean**. Do not reuse the student app's `AppNotification.toMap()` for
writes — it emits payload as a JSON *string* and is_read as `0`/`1`, which is
SQLite-shaped and wrong for Postgres.
