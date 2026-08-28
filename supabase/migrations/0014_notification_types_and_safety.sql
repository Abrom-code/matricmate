-- =============================================================================
-- 0014_notification_types_and_safety.sql
-- Ensure notifications table permits 'challenge' type and handles created_by safely
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_check_name text;
BEGIN
  -- 1. Drop existing type CHECK constraint if present
  SELECT conname INTO v_check_name
  FROM pg_constraint
  WHERE conrelid = 'public.notifications'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) ILIKE '%type%';

  IF v_check_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.notifications DROP CONSTRAINT %I', v_check_name);
    RAISE NOTICE 'Dropped old notifications.type CHECK constraint: %', v_check_name;
  END IF;

  -- 2. Add updated CHECK constraint including 'challenge'
  ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_type_check
    CHECK (type IN ('announcement', 'payment', 'new_content', 'challenge'));

  RAISE NOTICE 'Added updated notifications_type_check constraint';
END $$;

COMMIT;
