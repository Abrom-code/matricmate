-- 0010_create_pilot_exams_tables.sql
--
-- Pilot Exams (Pre-Matric / Entrance Model Exam Simulators)
--
-- Represents nationwide full-simulation model exams.
-- Each Pilot Exam contains 6 subjects tailored to the student's stream:
--   Natural Stream: 4 Natural subjects + 2 Common subjects (English + Aptitude)
--   Social Stream:  4 Social subjects  + 2 Common subjects (English + Aptitude)
--
-- Each subject links directly to an existing test in `public.tests(id)`
-- allowing complete reuse of existing question banks, timers, and scoring.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PILOT EXAMS MASTER TABLE
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pilot_exams (
    id          BIGSERIAL PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,                           -- e.g. "1st Semester Model Exam"
    description TEXT,                                            -- e.g. "Full-length nationwide pre-matric trial covering all 6 curriculum subjects."
    edition     VARCHAR(50) NOT NULL DEFAULT '2017 E.C.',        -- Academic year / edition
    is_active   BOOLEAN NOT NULL DEFAULT true,                   -- Set to false to archive or hide
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. PILOT EXAM SUBJECTS TABLE
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pilot_exam_subjects (
    id              BIGSERIAL PRIMARY KEY,
    pilot_exam_id   BIGINT NOT NULL REFERENCES public.pilot_exams(id) ON DELETE CASCADE,
    subject_id      INT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    subject_name    VARCHAR(100) NOT NULL,                       -- e.g. "Physics", "English"
    stream          VARCHAR(20) NOT NULL CHECK (stream IN ('natural', 'social', 'common', 'both')),
    test_id         INT REFERENCES public.tests(id) ON DELETE SET NULL,  -- Links to existing entrance/model test
    order_index     INT NOT NULL DEFAULT 1,                     -- Display order 1 to 6
    question_count  INT NOT NULL DEFAULT 60,                    -- Expected question count (standard 60)
    time_minutes    INT NOT NULL DEFAULT 90,                    -- Exam duration in minutes
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pilot_exam_subject_stream UNIQUE (pilot_exam_id, subject_id, stream)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_pilot_exams_active 
    ON public.pilot_exams(is_active);

CREATE INDEX IF NOT EXISTS idx_pilot_exam_subjects_exam_stream 
    ON public.pilot_exam_subjects(pilot_exam_id, stream, order_index);

CREATE INDEX IF NOT EXISTS idx_pilot_exam_subjects_test 
    ON public.pilot_exam_subjects(test_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.pilot_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pilot_exam_subjects ENABLE ROW LEVEL SECURITY;

-- Allow public read access to active pilot exams
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'pilot_exams' 
          AND policyname = 'Allow public read access to active pilot exams'
    ) THEN
        CREATE POLICY "Allow public read access to active pilot exams"
        ON public.pilot_exams FOR SELECT
        TO public
        USING (is_active = true);
    END IF;
END $$;

-- Allow public read access to pilot exam subjects
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'pilot_exam_subjects' 
          AND policyname = 'Allow public read access to pilot exam subjects'
    ) THEN
        CREATE POLICY "Allow public read access to pilot exam subjects"
        ON public.pilot_exam_subjects FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. UPDATED_AT TRIGGER
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_update_pilot_exam_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_pilot_exams_updated_at ON public.pilot_exams;
CREATE TRIGGER trg_pilot_exams_updated_at
BEFORE UPDATE ON public.pilot_exams
FOR EACH ROW
EXECUTE FUNCTION fn_update_pilot_exam_timestamp();
