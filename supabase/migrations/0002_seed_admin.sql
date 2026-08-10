-- =====================================================================
-- 0002_seed_admin.sql
--
-- Provisions the first admin account. Run AFTER 0001_admin_foundation.sql.
--
-- TWO STEPS ARE REQUIRED — this file is only the second one.
--
--   1. Create the account in FIREBASE AUTH first (Firebase console ->
--      Authentication -> Users -> Add user, with email + password).
--      Copy the generated User UID.
--
--   2. Run this file with that UID and email substituted below.
--
-- The admin app has no signup screen by design: admin accounts are
-- provisioned by SQL only. An admins row without a matching Firebase Auth
-- account can never log in (there is nothing to authenticate against), and a
-- Firebase account without an admins row is rejected with "Access Denied".
-- =====================================================================

INSERT INTO public.admins (firebase_uid, email, display_name, role, is_active)
VALUES (
    'REPLACE_WITH_FIREBASE_UID',   -- Firebase console -> Authentication -> User UID
    'REPLACE_WITH_EMAIL',          -- must match the Firebase account's email exactly
    'REPLACE_WITH_NAME',
    'superadmin',                  -- the first admin should be a superadmin
    true
)
ON CONFLICT (firebase_uid) DO UPDATE
SET email        = EXCLUDED.email,
    display_name = EXCLUDED.display_name,
    role         = EXCLUDED.role,
    is_active    = EXCLUDED.is_active;


-- Verify the row landed and that is_admin() will match it.
-- (is_admin() compares lower(email) against the JWT email claim, so a
-- case mismatch between Firebase and this row is harmless.)
SELECT firebase_uid, email, role, is_active, created_at
FROM public.admins;
