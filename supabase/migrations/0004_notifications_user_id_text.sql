-- =====================================================================
-- 0004_notifications_user_id_text.sql
--
-- WHY THIS EXISTS
--   notifications.user_id was declared as uuid, but users.id is a
--   Firebase UID (plain text, e.g. "uXk3pQ...28 chars").
--   Firebase UIDs are NOT valid UUIDs, so every INSERT from the
--   send-push edge function that sets user_id fails with a Postgres
--   type-cast error. Personal notifications were never persisted.
--
-- FIX
--   1. Drop the FK constraint (notifications.user_id -> users.id).
--      It was always type-mismatched (uuid vs text) and only survived
--      because no personal row was ever successfully inserted.
--   2. Cast the column to text.
--
-- SAFETY
--   NULL rows (broadcasts) survive unchanged.
--   Idempotent: checks current type before acting.
-- =====================================================================

BEGIN;

DO $$
DECLARE
  v_fk_name text;
BEGIN
  -- Step 1: find and drop any FK from notifications.user_id
  SELECT c.conname INTO v_fk_name
  FROM pg_constraint c
  JOIN pg_attribute a ON a.attnum = ANY(c.conkey)
    AND a.attrelid = c.conrelid
  WHERE c.conrelid = 'public.notifications'::regclass
    AND c.contype  = 'f'
    AND a.attname  = 'user_id';

  IF v_fk_name IS NOT NULL THEN
    EXECUTE format(
      'ALTER TABLE public.notifications DROP CONSTRAINT %I',
      v_fk_name
    );
    RAISE NOTICE 'Dropped FK: %', v_fk_name;
  ELSE
    RAISE NOTICE 'No FK on notifications.user_id found';
  END IF;

  -- Step 2: change uuid -> text (no-op if already text)
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'notifications'
      AND column_name  = 'user_id'
      AND data_type    = 'uuid'
  ) THEN
    ALTER TABLE public.notifications
      ALTER COLUMN user_id TYPE text USING user_id::text;
    RAISE NOTICE 'notifications.user_id changed uuid -> text';
  ELSE
    RAISE NOTICE 'notifications.user_id already text, nothing to do';
  END IF;
END $$;

COMMIT;


-- =====================================================================
-- ROLLBACK (only safe if no text Firebase-UID rows were inserted yet)
-- =====================================================================
-- BEGIN;
-- ALTER TABLE public.notifications
--   ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
-- ALTER TABLE public.notifications
--   ADD CONSTRAINT notifications_user_id_fkey
--   FOREIGN KEY (user_id) REFERENCES public.users(id);
-- COMMIT;
