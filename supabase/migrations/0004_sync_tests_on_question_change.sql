-- =====================================================================
-- Migration: Auto-sync tests.question_count and tests.updated_at
-- Triggered whenever questions are inserted, updated, or deleted
-- =====================================================================

BEGIN;

-- 1. Create trigger function to keep test metadata fresh
CREATE OR REPLACE FUNCTION public.sync_test_on_question_change()
RETURNS TRIGGER AS $$
DECLARE
    target_test_id INTEGER;
BEGIN
    -- Determine which test_id was affected
    IF (TG_OP = 'DELETE') THEN
        target_test_id := OLD.test_id;
    ELSE
        target_test_id := NEW.test_id;
    END IF;

    IF target_test_id IS NOT NULL THEN
        UPDATE public.tests
        SET 
            question_count = (
                SELECT COUNT(*) 
                FROM public.questions 
                WHERE test_id = target_test_id
            ),
            updated_at = NOW()
        WHERE id = target_test_id;
    END IF;

    -- If a question's test_id was changed (moved across tests)
    IF (TG_OP = 'UPDATE' AND OLD.test_id IS DISTINCT FROM NEW.test_id AND OLD.test_id IS NOT NULL) THEN
        UPDATE public.tests
        SET 
            question_count = (
                SELECT COUNT(*) 
                FROM public.questions 
                WHERE test_id = OLD.test_id
            ),
            updated_at = NOW()
        WHERE id = OLD.test_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach trigger to public.questions
DROP TRIGGER IF EXISTS trg_sync_test_on_question_change ON public.questions;

CREATE TRIGGER trg_sync_test_on_question_change
AFTER INSERT OR UPDATE OR DELETE ON public.questions
FOR EACH ROW
EXECUTE FUNCTION public.sync_test_on_question_change();

-- 3. One-time sync for all existing tests
UPDATE public.tests t
SET 
    question_count = (SELECT COUNT(*) FROM public.questions q WHERE q.test_id = t.id),
    updated_at = NOW();

COMMIT;
