-- Add optional description column to tests (especially useful for model exams)
ALTER TABLE public.tests 
ADD COLUMN IF NOT EXISTS description text;

COMMENT ON COLUMN public.tests.description IS 
'Optional description, context, or instructions, specially for model exams to indicate regional bureau, year, school, or syllabus details.';
