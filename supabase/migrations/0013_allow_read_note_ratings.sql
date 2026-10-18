-- 0013_allow_read_note_ratings.sql
-- Allow public/authenticated read access to note_ratings so admin console and apps can aggregate student reviews.

DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow users to read their own note ratings" ON public.note_ratings;
    DROP POLICY IF EXISTS "Allow public read access to note ratings" ON public.note_ratings;

    CREATE POLICY "Allow public read access to note ratings"
        ON public.note_ratings FOR SELECT
        TO public
        USING (true);
END $$;
