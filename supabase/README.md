# MatricMate Supabase Backend

Unified Supabase backend foundation for MatricMate, featuring native **Supabase Auth**, strict **Row-Level Security (RLS)**, automated account provisioning, single-device session control, and anti-cheating challenge mechanisms.

---

## 1. Directory Structure

```
supabase/
├── migrations/
│   └── 0001_initial_schema.sql  # Baseline unified database migration
├── functions/
│   ├── admin-auth/              # Admin JWT & authentication verification
│   ├── challenge-scheduler/     # Automated challenge status & reward transitions
│   ├── send-push/               # FCM push notification webhook
│   └── deno.json                # Deno configuration for edge functions
├── schema.sql                   # Master SQL schema for fresh setup
└── README.md                    # Architecture and schema documentation
```

---

## 2. Core Architecture

### Native Supabase Auth & Foreign Key Integrity
* `public.users.id` is typed as `uuid` and references `auth.users(id) ON DELETE CASCADE`.
* All user-related tables (`user_sessions`, `bookmarks`, `test_attempts`, `challenge_attempts`, `notifications`, `notification_reads`, `payment_requests`, `payment_receipts`) reference `public.users(id) ON DELETE CASCADE`.
* Deleting a user in `auth.users` automatically cascades and deletes all associated profile and relational rows.

### Automatic Profile Provisioning
* Trigger `on_auth_user_created` calls `handle_new_user()` on `AFTER INSERT ON auth.users`.
* Extracts `first_name`, `last_name`, `stream` from user metadata passed during signup and synchronizes with `public.users`.

### Self-Service Account Deletion
* Secure RPC `delete_own_account()` executes `DELETE FROM auth.users WHERE id = auth.uid()`.
* Cascades through the entire database to wipe all student data cleanly.

### Single-Device Session Enforcement
* `public.user_sessions` maps `user_id` to `device_id` and tracks remaining allowed device transfers.
* Realtime postgres changes notify the active client immediately if an unauthorized device logs in.

### Challenge Subsystem & Anti-Cheating Protection
* `challenge_questions` hides `correct_choice` and explanations during active competitions.
* `rpc_start_attempt` generates attempts and delivers questions without answer keys.
* `rpc_submit_answer` and `rpc_submit_attempt` strictly authorize `auth.uid()` against the attempt owner.
* `rpc_get_challenge_answers` only reveals answers once an attempt is submitted or the challenge is archived.

---

## 3. Row-Level Security (RLS) Overview

All 22 public tables have Row-Level Security enabled:

| Table Category | Tables | Policies |
|---|---|---|
| **User & Profile** | `users`, `user_sessions`, `bookmarks`, `test_attempts` | Scoped to `auth.uid() = user_id` or admin |
| **Admin** | `admins`, `admin_audit_log` | Restricted to `is_admin()` |
| **Payments** | `payment_requests`, `payment_receipts` | Students insert/view own; admins review/manage |
| **Notifications** | `notifications`, `notification_reads` | Targeted to `auth.uid() = user_id` or global broadcasts |
| **Public Content** | `subjects`, `chapters`, `passages`, `question_sections`, `tests`, `questions`, `app_config` | Public `SELECT`; Admin-only mutations |
| **Challenges** | `leaderboard_challenges`, `challenge_question_sets`, `challenge_questions`, `challenge_attempts`, `challenge_answers`, `challenge_rewards` | Strict anti-cheating, privacy for in-progress attempts, public leaderboards for submitted attempts |
| **Storage** | `storage.objects` (`receipts` bucket) | Prefix restricted to `(auth.uid())::text = foldername[1]` |
