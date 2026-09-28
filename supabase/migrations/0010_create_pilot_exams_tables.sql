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
--
-- Includes an AUTO-FILL TRIGGER that automatically derives `subject_name`,
-- `stream`, `question_count`, and `time_minutes` from `public.subjects` and `public.tests`!

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PILOT EXAMS MASTER TABLE
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pilot_exams (
    id          BIGSERIAL PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,                           -- e.g. "1st Semester Model Exam"
    description TEXT,                                            -- e.g. "Full-length nationwide pre-matric trial covering all 6 curriculum subjects."
    edition     VARCHAR(50) NOT NULL DEFAULT '2019 E.C.',        -- Academic year / edition
    is_active   BOOLEAN NOT NULL DEFAULT true,                   -- Set to false to archive or hide from students
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
    subject_name    VARCHAR(100) DEFAULT '',                     -- Auto-filled by trigger from public.subjects
    stream          VARCHAR(20) DEFAULT '' CHECK (stream IN ('natural', 'social', 'common', 'both', '')), -- Auto-filled by trigger
    test_id         INT REFERENCES public.tests(id) ON DELETE SET NULL,  -- Links to existing test in tests table
    order_index     INT NOT NULL DEFAULT 1,                     -- Display order 1 to 6
    question_count  INT NOT NULL DEFAULT 60,                    -- Expected question count (auto-filled if test_id given)
    time_minutes    INT NOT NULL DEFAULT 90,                    -- Exam duration in minutes (auto-filled if test_id given)
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. AUTO-FILL TRIGGER: DERIVES subject_name, stream, question_count, time
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_auto_fill_pilot_exam_subject_details()
RETURNS TRIGGER AS $$
DECLARE
    v_name         TEXT;
    v_is_natural   BOOLEAN;
    v_is_common    BOOLEAN;
    v_test_q_count INT;
    v_test_time    INT;
    v_test_sub_id  INT;
BEGIN
    -- 1. If subject_id is provided, auto-fetch name and stream from public.subjects
    IF NEW.subject_id IS NOT NULL THEN
        SELECT name, is_natural, is_common
        INTO v_name, v_is_natural, v_is_common
        FROM public.subjects
        WHERE id = NEW.subject_id;

        IF FOUND THEN
            -- Only auto-fill if not already manually provided
            IF NEW.subject_name IS NULL OR TRIM(NEW.subject_name) = '' THEN
                NEW.subject_name := v_name;
            END IF;

            IF NEW.stream IS NULL OR TRIM(NEW.stream) = '' THEN
                IF v_is_common = true THEN
                    NEW.stream := 'common';
                ELSIF v_is_natural = true THEN
                    NEW.stream := 'natural';
                ELSE
                    NEW.stream := 'social';
                END IF;
            END IF;
        END IF;
    END IF;

    -- 2. If test_id is provided, auto-fetch metadata from public.tests
    IF NEW.test_id IS NOT NULL THEN
        SELECT question_count, time, subject_id
        INTO v_test_q_count, v_test_time, v_test_sub_id
        FROM public.tests
        WHERE id = NEW.test_id;

        IF FOUND THEN
            -- If subject_id was omitted, infer it from the test
            IF NEW.subject_id IS NULL AND v_test_sub_id IS NOT NULL THEN
                NEW.subject_id := v_test_sub_id;
                SELECT name, is_natural, is_common
                INTO v_name, v_is_natural, v_is_common
                FROM public.subjects
                WHERE id = NEW.subject_id;

                IF FOUND THEN
                    NEW.subject_name := COALESCE(NULLIF(NEW.subject_name, ''), v_name);
                    IF NEW.stream IS NULL OR TRIM(NEW.stream) = '' THEN
                        IF v_is_common = true THEN NEW.stream := 'common';
                        ELSIF v_is_natural = true THEN NEW.stream := 'natural';
                        ELSE NEW.stream := 'social'; END IF;
                    END IF;
                END IF;
            END IF;

            -- Auto-fill question count from test if not explicitly customized
            IF (NEW.question_count IS NULL OR NEW.question_count = 0) AND v_test_q_count > 0 THEN
                NEW.question_count := v_test_q_count;
            END IF;

            -- Auto-fill time in minutes from test if not explicitly customized
            IF (NEW.time_minutes IS NULL OR NEW.time_minutes = 0) AND v_test_time > 0 THEN
                NEW.time_minutes := v_test_time;
            END IF;
        END IF;
    END IF;

    -- 3. Fallback safety defaults
    NEW.subject_name   := COALESCE(NULLIF(NEW.subject_name, ''), 'Subject');
    NEW.stream         := COALESCE(NULLIF(NEW.stream, ''), 'natural');
    NEW.question_count := COALESCE(NEW.question_count, 60);
    NEW.time_minutes   := COALESCE(NEW.time_minutes, 90);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_fill_pilot_exam_subject_details ON public.pilot_exam_subjects;
CREATE TRIGGER trg_auto_fill_pilot_exam_subject_details
BEFORE INSERT OR UPDATE ON public.pilot_exam_subjects
FOR EACH ROW
EXECUTE FUNCTION fn_auto_fill_pilot_exam_subject_details();
