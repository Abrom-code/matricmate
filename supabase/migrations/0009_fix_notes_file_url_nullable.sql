-- 0009_fix_notes_file_url_nullable.sql
--
-- Drops NOT NULL constraint on file_url since notes now use Cloudflare R2 file_key.
-- Ensures inserts only providing file_key succeed seamlessly.

ALTER TABLE public.notes ALTER COLUMN file_url DROP NOT NULL;
ALTER TABLE public.notes ALTER COLUMN file_url SET DEFAULT '';

-- Update trigger to populate file_url fallback from file_key
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

    -- Ensure file_url has a fallback so legacy queries never get null
    NEW.file_url := COALESCE(NEW.file_url, NEW.file_key, '');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
