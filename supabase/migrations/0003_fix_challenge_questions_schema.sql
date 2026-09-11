-- 0003_fix_challenge_questions_schema.sql
-- Fix: Ensure both `challenge_id` and `set_id` exist on `public.challenge_questions`
-- and `set_id` exists on `public.leaderboard_challenges`, preventing Error 42703
-- ("One of the data fields is invalid or missing") during offline downloads and question queries.

-- 1. Ensure columns exist on public.challenge_questions
ALTER TABLE public.challenge_questions 
ADD COLUMN IF NOT EXISTS challenge_id uuid REFERENCES public.leaderboard_challenges(id) ON DELETE CASCADE;

ALTER TABLE public.challenge_questions 
ADD COLUMN IF NOT EXISTS set_id uuid REFERENCES public.challenge_question_sets(id) ON DELETE CASCADE;

-- 2. Ensure set_id exists on public.leaderboard_challenges
ALTER TABLE public.leaderboard_challenges 
ADD COLUMN IF NOT EXISTS set_id uuid REFERENCES public.challenge_question_sets(id) ON DELETE SET NULL;

-- 3. Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS challenge_questions_challenge_idx ON public.challenge_questions (challenge_id);
CREATE INDEX IF NOT EXISTS challenge_questions_set_idx       ON public.challenge_questions (set_id);

-- 4. Auto-heal / backfill relations between challenge_id and set_id
-- When questions have set_id but missing challenge_id:
UPDATE public.challenge_questions cq
SET challenge_id = lc.id
FROM public.leaderboard_challenges lc
WHERE cq.challenge_id IS NULL AND cq.set_id IS NOT NULL AND lc.set_id = cq.set_id;

-- When questions have challenge_id but missing set_id:
UPDATE public.challenge_questions cq
SET set_id = lc.set_id
FROM public.leaderboard_challenges lc
WHERE cq.set_id IS NULL AND cq.challenge_id IS NOT NULL AND lc.id = cq.challenge_id AND lc.set_id IS NOT NULL;

-- 5. Update RLS policy to safely check both relations
DROP POLICY IF EXISTS "Challenge questions view policy" ON public.challenge_questions;
CREATE POLICY "Challenge questions view policy" ON public.challenge_questions
    FOR SELECT TO authenticated
    USING (
        public.is_admin()
        OR (
            challenge_questions.challenge_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.leaderboard_challenges lc
                WHERE lc.id = challenge_questions.challenge_id
                  AND (
                    lc.status IN ('closed', 'archived')
                    OR EXISTS (
                        SELECT 1 FROM public.challenge_attempts a
                        WHERE a.challenge_id = lc.id
                          AND a.user_id = auth.uid()
                          AND a.status = 'submitted'
                    )
                  )
            )
        )
        OR (
            challenge_questions.set_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.challenge_question_sets cqs
                JOIN public.leaderboard_challenges lc ON lc.set_id = cqs.id
                WHERE cqs.id = challenge_questions.set_id
                  AND (
                    lc.status IN ('closed', 'archived')
                    OR EXISTS (
                        SELECT 1 FROM public.challenge_attempts a
                        WHERE a.challenge_id = lc.id
                          AND a.user_id = auth.uid()
                          AND a.status = 'submitted'
                    )
                  )
            )
        )
    );
