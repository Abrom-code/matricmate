-- 0012_create_note_ratings.sql
--
-- Note ratings table to allow students to rate notes from 1 to 5 stars upon completion.

CREATE TABLE IF NOT EXISTS public.note_ratings (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    note_id     BIGINT NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
    rating      INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, note_id)
);

CREATE INDEX IF NOT EXISTS idx_note_ratings_note ON public.note_ratings(note_id);
CREATE INDEX IF NOT EXISTS idx_note_ratings_user ON public.note_ratings(user_id);

ALTER TABLE public.note_ratings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'note_ratings' 
          AND policyname = 'Allow users to read their own note ratings'
    ) THEN
        CREATE POLICY "Allow users to read their own note ratings"
        ON public.note_ratings FOR SELECT
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'note_ratings' 
          AND policyname = 'Allow users to insert or update their own note rating'
    ) THEN
        CREATE POLICY "Allow users to insert or update their own note rating"
        ON public.note_ratings FOR ALL
        TO authenticated
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;
