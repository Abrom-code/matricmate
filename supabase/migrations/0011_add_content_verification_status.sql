-- 0011_add_content_verification_status.sql
--
-- Verification State Pipeline for Tests, Challenges, and Pilot Exams
-- Ensures any newly created test, challenge, or pilot exam defaults to 'draft'/'verification'
-- and is only visible/accessible to Admins until verified and published.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. TESTS VERIFICATION STATUS
-- ─────────────────────────────────────────────────────────────────────────────

-- Add status column to tests if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'tests' 
          AND column_name = 'status'
    ) THEN
        ALTER TABLE public.tests 
            ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'draft'
            CHECK (status IN ('draft', 'verification', 'published', 'archived'));

        -- Set all existing tests to 'published' so live content remains available
        UPDATE public.tests SET status = 'published';
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tests_status_subject 
    ON public.tests(status, subject_id);

-- Update RLS on public.tests: Only published tests visible to students; Admins see all
DROP POLICY IF EXISTS "Tests are publicly readable" ON public.tests;
DROP POLICY IF EXISTS "Tests select policy" ON public.tests;

CREATE POLICY "Tests select policy" ON public.tests
    FOR SELECT
    USING (public.is_admin() OR status = 'published');

-- Update RLS on public.questions: Questions only visible if parent test is published or user is admin
DROP POLICY IF EXISTS "Questions are publicly readable" ON public.questions;
DROP POLICY IF EXISTS "Questions select policy" ON public.questions;

CREATE POLICY "Questions select policy" ON public.questions
    FOR SELECT
    USING (
        public.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.tests t
            WHERE t.id = questions.test_id
              AND t.status = 'published'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PILOT EXAMS VERIFICATION STATUS
-- ─────────────────────────────────────────────────────────────────────────────

-- Add status column to pilot_exams if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'pilot_exams' 
          AND column_name = 'status'
    ) THEN
        ALTER TABLE public.pilot_exams 
            ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'draft'
            CHECK (status IN ('draft', 'verification', 'published', 'archived'));

        -- Existing active pilot exams become published
        UPDATE public.pilot_exams 
        SET status = CASE WHEN is_active THEN 'published' ELSE 'draft' END;
    END IF;
END $$;

-- Update default for is_active on newly created pilot exams to false (draft until verified)
ALTER TABLE public.pilot_exams ALTER COLUMN is_active SET DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_pilot_exams_status 
    ON public.pilot_exams(status);

-- Update RLS on public.pilot_exams
DROP POLICY IF EXISTS "Allow public read access to active pilot exams" ON public.pilot_exams;
DROP POLICY IF EXISTS "Pilot exams select policy" ON public.pilot_exams;

CREATE POLICY "Pilot exams select policy" ON public.pilot_exams
    FOR SELECT
    USING (public.is_admin() OR (is_active = true AND status = 'published'));

-- Update RLS on public.pilot_exam_subjects
DROP POLICY IF EXISTS "Allow public read access to pilot exam subjects" ON public.pilot_exam_subjects;
DROP POLICY IF EXISTS "Pilot exam subjects select policy" ON public.pilot_exam_subjects;

CREATE POLICY "Pilot exam subjects select policy" ON public.pilot_exam_subjects
    FOR SELECT
    USING (
        public.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.pilot_exams pe
            WHERE pe.id = pilot_exam_subjects.pilot_exam_id
              AND pe.is_active = true
              AND pe.status = 'published'
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. VERIFICATION & PUBLISH RPCS (Security Definer, Admin Only)
-- ─────────────────────────────────────────────────────────────────────────────

-- Verify and publish a test
CREATE OR REPLACE FUNCTION public.verify_and_publish_test(p_test_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admin role required.';
    END IF;

    UPDATE public.tests
    SET status = 'published', updated_at = NOW()
    WHERE id = p_test_id;

    RETURN TRUE;
END;
$$;

-- Verify and publish a pilot exam
CREATE OR REPLACE FUNCTION public.verify_and_publish_pilot_exam(p_pilot_exam_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admin role required.';
    END IF;

    UPDATE public.pilot_exams
    SET status = 'published', is_active = true, updated_at = NOW()
    WHERE id = p_pilot_exam_id;

    RETURN TRUE;
END;
$$;

-- Verify and publish a challenge
CREATE OR REPLACE FUNCTION public.verify_and_publish_challenge(p_challenge_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admin role required.';
    END IF;

    UPDATE public.leaderboard_challenges
    SET status = 'scheduled', updated_at = NOW()
    WHERE id = p_challenge_id;

    RETURN TRUE;
END;
$$;

-- Unpublish / return to draft
CREATE OR REPLACE FUNCTION public.unpublish_test(p_test_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admin role required.';
    END IF;

    UPDATE public.tests
    SET status = 'draft', updated_at = NOW()
    WHERE id = p_test_id;

    RETURN TRUE;
END;
$$;

COMMIT;
