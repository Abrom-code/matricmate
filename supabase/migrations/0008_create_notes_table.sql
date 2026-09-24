-- 0008_create_notes_table.sql
--
-- Notes table for chapter notes and multi-grade resources.
-- The Cloudflare R2 object key is stored in `file_key`.
-- Access is granted via temporary signed URLs from the `get-note-url` Edge Function.

CREATE TABLE IF NOT EXISTS public.notes (
    id              BIGSERIAL PRIMARY KEY,
    subject_id      INT NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    chapter_id      INT REFERENCES public.chapters(id) ON DELETE SET NULL,     -- Optional (NULL for general notes)
    grade           INT NOT NULL CHECK (grade BETWEEN 0 AND 12),        -- 0 = General/Multi-grade, 9-12 = Specific grades
    chapter_number  INT NOT NULL DEFAULT 0,                             -- 0 for general notes, 1, 2, 3... for unit notes
    title           VARCHAR(255) NOT NULL,                              -- e.g. "Unit 1: Vectors & Kinematics"
    description     TEXT,                                               -- Short summary of key concepts
    file_key        TEXT,                                               -- Cloudflare R2 object key (e.g. "biology/11/bioG11C1_MatricET.pdf")
    file_url        TEXT,                                               -- Optional fallback
    file_type       VARCHAR(20) NOT NULL DEFAULT 'pdf',
    file_size_bytes BIGINT DEFAULT 0,                                   -- Size in bytes (optional)
    page_count      INT DEFAULT 0,                                      -- Page count (optional)
    is_premium      BOOLEAN NOT NULL DEFAULT true,                      -- Defaults to true (PRO only)
    order_index     INT DEFAULT 0,                                      -- Display sort order
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure file_key column and grade constraint exist if table already existed prior to this migration
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'notes' 
          AND column_name = 'file_key'
    ) THEN
        ALTER TABLE public.notes ADD COLUMN file_key TEXT;
    END IF;

    ALTER TABLE public.notes DROP CONSTRAINT IF EXISTS notes_grade_check;
    ALTER TABLE public.notes ADD CONSTRAINT notes_grade_check CHECK (grade BETWEEN 0 AND 12);
END $$;

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_notes_subject_grade ON public.notes(subject_id, grade);
CREATE INDEX IF NOT EXISTS idx_notes_chapter ON public.notes(chapter_id);
CREATE INDEX IF NOT EXISTS idx_notes_order ON public.notes(subject_id, grade, order_index);

-- Enable Row Level Security (RLS)
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- Allow public read access to note metadata (file binary is protected in private R2 bucket)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'notes' 
          AND policyname = 'Allow public read access to notes'
    ) THEN
        CREATE POLICY "Allow public read access to notes"
        ON public.notes FOR SELECT
        TO public
        USING (true);
    END IF;
END $$;

-- Auto-fill trigger: When chapter_id is provided, automatically populate subject_id, grade, and chapter_number
CREATE OR REPLACE FUNCTION fn_auto_fill_note_details()
RETURNS TRIGGER AS $$
DECLARE
    v_subject_id     INT;
    v_grade          INT;
    v_chapter_number INT;
BEGIN
    IF NEW.chapter_id IS NOT NULL THEN
        SELECT subject_id, grade, chapter_number 
        INTO v_subject_id, v_grade, v_chapter_number
        FROM public.chapters 
        WHERE id = NEW.chapter_id;

        IF FOUND THEN
            NEW.subject_id     := COALESCE(NEW.subject_id, v_subject_id);
            NEW.grade          := COALESCE(NEW.grade, v_grade);
            NEW.chapter_number := COALESCE(NEW.chapter_number, v_chapter_number);
        END IF;
    ELSE
        NEW.grade          := COALESCE(NEW.grade, 0);
        NEW.chapter_number := COALESCE(NEW.chapter_number, 0);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_fill_note_details ON public.notes;
CREATE TRIGGER trg_auto_fill_note_details
BEFORE INSERT OR UPDATE ON public.notes
FOR EACH ROW
EXECUTE FUNCTION fn_auto_fill_note_details();
