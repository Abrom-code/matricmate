-- 0016_challenge_review_policy.sql
-- Migration: Add review_policy to leaderboard_challenges and enforce question review permissions.
-- Policies:
--   1. 'when_closed' (or 'closed'): questions/answers can ONLY be reviewed after the challenge time has closed/ended.
--   2. 'on_completion' (or 'completed'): [DEFAULT] questions/answers can be reviewed immediately after completing the attempt.

-- 1. Add review_policy column to public.leaderboard_challenges
ALTER TABLE public.leaderboard_challenges
ADD COLUMN IF NOT EXISTS review_policy text NOT NULL DEFAULT 'on_completion';

-- 2. Add check constraint to ensure only valid review policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'leaderboard_challenges_review_policy_check'
  ) THEN
    ALTER TABLE public.leaderboard_challenges
    ADD CONSTRAINT leaderboard_challenges_review_policy_check
    CHECK (review_policy IN ('on_completion', 'when_closed', 'completed', 'closed'));
  END IF;
END $$;

COMMENT ON COLUMN public.leaderboard_challenges.review_policy IS
'Policy for reviewing questions and correct answers: "on_completion" (default: review immediately after submitting attempt) or "when_closed" (review only after challenge time has closed/ended).';

-- 3. Update RLS policy on public.challenge_questions to respect review_policy
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
                    OR (lc.ends_at IS NOT NULL AND lc.ends_at <= now())
                    OR (
                        (lc.review_policy NOT IN ('when_closed', 'closed'))
                        AND EXISTS (
                            SELECT 1 FROM public.challenge_attempts a
                            WHERE a.challenge_id = lc.id
                              AND a.user_id = auth.uid()
                              AND a.status = 'submitted'
                        )
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
                    OR (lc.ends_at IS NOT NULL AND lc.ends_at <= now())
                    OR (
                        (lc.review_policy NOT IN ('when_closed', 'closed'))
                        AND EXISTS (
                            SELECT 1 FROM public.challenge_attempts a
                            WHERE a.challenge_id = lc.id
                              AND a.user_id = auth.uid()
                              AND a.status = 'submitted'
                        )
                    )
                  )
            )
        )
    );

-- 4. Update rpc_get_challenge_answers to enforce review_policy
CREATE OR REPLACE FUNCTION public.rpc_get_challenge_answers(
  p_challenge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge record;
  v_questions jsonb;
  v_is_submitted boolean := false;
  v_is_closed boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = p_challenge_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'challenge_not_found';
  END IF;

  v_is_closed := (v_challenge.status IN ('closed', 'archived'))
                 OR (v_challenge.ends_at IS NOT NULL AND v_challenge.ends_at <= now());

  SELECT EXISTS (
    SELECT 1 FROM public.challenge_attempts
    WHERE challenge_id = p_challenge_id AND user_id = auth.uid() AND status = 'submitted'
  ) INTO v_is_submitted;

  -- If not admin and challenge is not closed:
  -- If review_policy is 'when_closed' / 'closed', block access until challenge ends.
  -- If review_policy is 'on_completion', require submitted attempt.
  IF NOT public.is_admin() AND NOT v_is_closed THEN
    IF (v_challenge.review_policy IN ('when_closed', 'closed')) OR NOT v_is_submitted THEN
      RAISE EXCEPTION 'challenge_answers_restricted';
    END IF;
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'challenge_id', q.challenge_id,
      'order_index', q.order_index,
      'question_text', q.question_text,
      'choices', q.choices,
      'correct_choice', q.correct_choice,
      'explanation', coalesce(q.explanation_en, q.explanation, ''),
      'explanation_en', coalesce(q.explanation_en, q.explanation, ''),
      'explanation_am', coalesce(q.explanation_am, ''),
      'image_url', q.image_url,
      'passage_id', q.passage_id,
      'passage', CASE WHEN cp.id IS NOT NULL THEN jsonb_build_object(
        'id', -1,
        'title', cp.title,
        'content', cp.content,
        'image_url', cp.image_url
      ) ELSE NULL END
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  LEFT JOIN public.challenge_passages cp ON cp.id = q.passage_id
  WHERE (q.challenge_id = v_challenge.id
     OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id)
     OR q.set_id = v_challenge.id);

  RETURN coalesce(v_questions, '[]'::jsonb);
END;
$$;

-- 5. Update rpc_submit_attempt to respect review_policy on attempt completion
CREATE OR REPLACE FUNCTION public.rpc_submit_attempt(
  p_attempt_id uuid,
  p_total_time_seconds int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_attempt record;
  v_challenge record;
  v_score int := 0;
  v_time int := 0;
  v_questions jsonb := '[]'::jsonb;
  v_is_closed boolean := false;
  v_can_review boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_attempt FROM public.challenge_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'attempt_not_found';
  END IF;

  IF auth.uid() != v_attempt.user_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = v_attempt.challenge_id;

  v_is_closed := (v_challenge.status IN ('closed', 'archived'))
                 OR (v_challenge.ends_at IS NOT NULL AND v_challenge.ends_at <= now());

  v_can_review := public.is_admin()
                  OR v_is_closed
                  OR (v_challenge.review_policy NOT IN ('when_closed', 'closed'));

  IF v_attempt.status = 'submitted' THEN
    IF v_can_review THEN
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', q.id,
          'order_index', q.order_index,
          'question_text', q.question_text,
          'choices', q.choices,
          'correct_choice', q.correct_choice,
          'explanation', coalesce(q.explanation_en, q.explanation, ''),
          'explanation_en', coalesce(q.explanation_en, q.explanation, ''),
          'explanation_am', coalesce(q.explanation_am, ''),
          'image_url', q.image_url,
          'passage_id', q.passage_id,
          'passage', CASE WHEN cp.id IS NOT NULL THEN jsonb_build_object(
            'id', -1,
            'title', cp.title,
            'content', cp.content,
            'image_url', cp.image_url
          ) ELSE NULL END
        ) ORDER BY q.order_index ASC
      ) INTO v_questions
      FROM public.challenge_questions q
      LEFT JOIN public.challenge_passages cp ON cp.id = q.passage_id
      WHERE (q.challenge_id = v_challenge.id
         OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id)
         OR q.set_id = v_challenge.id);
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'score', v_attempt.score,
      'total_time_seconds', v_attempt.total_time_seconds,
      'status', v_attempt.status,
      'can_review', v_can_review,
      'review_policy', coalesce(v_challenge.review_policy, 'on_completion'),
      'questions', coalesce(v_questions, '[]'::jsonb)
    );
  END IF;

  SELECT count(*)::int INTO v_score
  FROM public.challenge_answers
  WHERE attempt_id = p_attempt_id AND is_correct = true;

  IF p_total_time_seconds IS NOT NULL AND p_total_time_seconds > 0 THEN
    v_time := p_total_time_seconds;
  ELSE
    v_time := EXTRACT(EPOCH FROM (now() - v_attempt.started_at))::int;
  END IF;

  IF v_challenge.duration_seconds > 0 AND v_time > (v_challenge.duration_seconds + 30) THEN
    v_time := v_challenge.duration_seconds;
  END IF;

  UPDATE public.challenge_attempts
  SET
    score = v_score,
    total_time_seconds = v_time,
    submitted_at = coalesce(submitted_at, now()),
    status = 'submitted'
  WHERE id = p_attempt_id;

  IF v_can_review THEN
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'order_index', q.order_index,
        'question_text', q.question_text,
        'choices', q.choices,
        'correct_choice', q.correct_choice,
        'explanation', coalesce(q.explanation_en, q.explanation, ''),
        'explanation_en', coalesce(q.explanation_en, q.explanation, ''),
        'explanation_am', coalesce(q.explanation_am, ''),
        'image_url', q.image_url,
        'passage_id', q.passage_id,
        'passage', CASE WHEN cp.id IS NOT NULL THEN jsonb_build_object(
          'id', -1,
          'title', cp.title,
          'content', cp.content,
          'image_url', cp.image_url
        ) ELSE NULL END
      ) ORDER BY q.order_index ASC
    ) INTO v_questions
    FROM public.challenge_questions q
    LEFT JOIN public.challenge_passages cp ON cp.id = q.passage_id
    WHERE (q.challenge_id = v_challenge.id
       OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id)
       OR q.set_id = v_challenge.id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'score', v_score,
    'total_time_seconds', v_time,
    'status', 'submitted',
    'can_review', v_can_review,
    'review_policy', coalesce(v_challenge.review_policy, 'on_completion'),
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
END;
$$;

-- 6. Helper RPC for Admins to easily configure challenge review policy
CREATE OR REPLACE FUNCTION public.set_challenge_review_policy(
  p_challenge_id uuid,
  p_review_policy text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied. Admin role required.';
  END IF;

  IF p_review_policy NOT IN ('on_completion', 'when_closed', 'completed', 'closed') THEN
    RAISE EXCEPTION 'Invalid review policy. Allowed values: on_completion, when_closed.';
  END IF;

  UPDATE public.leaderboard_challenges
  SET review_policy = p_review_policy,
      updated_at = now()
  WHERE id = p_challenge_id;

  RETURN true;
END;
$$;
