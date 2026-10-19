-- 0017_fix_challenge_submission_schema.sql
-- Fix: Prevent Error 42P01 ("The requested resource could not be found on the server")
-- and avoid deadlocks (40P01) by removing heavy foreign key locks on live active tables.
-- Reads passages directly from public.passages table.

-- 1. Ensure challenge_answers exists without heavy foreign key locks
CREATE TABLE IF NOT EXISTS public.challenge_answers (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id      uuid NOT NULL,
    question_id     uuid NOT NULL,
    selected_choice text,
    is_correct      boolean NOT NULL DEFAULT false,
    answered_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (attempt_id, question_id)
);

CREATE INDEX IF NOT EXISTS challenge_answers_attempt_idx ON public.challenge_answers (attempt_id);
ALTER TABLE public.challenge_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage challenge answers" ON public.challenge_answers;
CREATE POLICY "Users manage challenge answers" ON public.challenge_answers
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. Ensure review_policy column exists on leaderboard_challenges (simple column, no FK lock)
ALTER TABLE public.leaderboard_challenges
ADD COLUMN IF NOT EXISTS review_policy text DEFAULT 'on_completion';

-- 3. Deploy updated rpc_submit_attempt (reads directly from public.passages!)
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
                  OR (coalesce(v_challenge.review_policy, 'on_completion') NOT IN ('when_closed', 'closed'));

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
          'passage', CASE 
            WHEN p.id IS NOT NULL THEN jsonb_build_object(
              'id', p.id,
              'title', p.title,
              'content', p.content,
              'image_url', p.image_url
            )
            ELSE NULL 
          END
        ) ORDER BY q.order_index ASC
      ) INTO v_questions
      FROM public.challenge_questions q
      LEFT JOIN public.passages p ON p.id::text = q.passage_id::text
      WHERE (q.challenge_id = v_challenge.id
         OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id)
         OR q.set_id = v_challenge.id);
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'score', coalesce(v_attempt.score, 0),
      'total_time_seconds', coalesce(v_attempt.total_time_seconds, 0),
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

  IF coalesce(v_challenge.duration_seconds, 0) > 0 AND v_time > (v_challenge.duration_seconds + 30) THEN
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
        'passage', CASE 
          WHEN p.id IS NOT NULL THEN jsonb_build_object(
            'id', p.id,
            'title', p.title,
            'content', p.content,
            'image_url', p.image_url
          )
          ELSE NULL 
        END
      ) ORDER BY q.order_index ASC
    ) INTO v_questions
    FROM public.challenge_questions q
    LEFT JOIN public.passages p ON p.id::text = q.passage_id::text
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

GRANT EXECUTE ON FUNCTION public.rpc_submit_attempt TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_submit_attempt TO anon;

-- 4. Deploy updated rpc_get_challenge_answers (reads directly from public.passages!)
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
      'passage', CASE 
        WHEN p.id IS NOT NULL THEN jsonb_build_object(
          'id', p.id,
          'title', p.title,
          'content', p.content,
          'image_url', p.image_url
        )
        ELSE NULL 
      END
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  LEFT JOIN public.passages p ON p.id::text = q.passage_id::text
  WHERE (q.challenge_id = v_challenge.id
     OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id)
     OR q.set_id = v_challenge.id);

  RETURN coalesce(v_questions, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_get_challenge_answers TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_challenge_answers TO anon;

-- 5. Deploy rpc_batch_submit_answers
CREATE OR REPLACE FUNCTION public.rpc_batch_submit_answers(
  p_attempt_id uuid,
  p_answers jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_attempt record;
  v_key text;
  v_choice text;
  v_question record;
  v_is_correct boolean;
  v_count integer := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_attempt FROM public.challenge_attempts WHERE id = p_attempt_id;
  IF NOT FOUND OR v_attempt.status != 'in_progress' THEN
    RAISE EXCEPTION 'invalid_or_completed_attempt';
  END IF;

  IF auth.uid() != v_attempt.user_id AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  FOR v_key, v_choice IN SELECT * FROM jsonb_each_text(p_answers)
  LOOP
    SELECT * INTO v_question FROM public.challenge_questions WHERE id = v_key::uuid;
    IF FOUND THEN
      v_is_correct := (trim(lower(coalesce(v_question.correct_choice, ''))) = trim(lower(coalesce(v_choice, ''))));
      INSERT INTO public.challenge_answers (attempt_id, question_id, selected_choice, is_correct, answered_at)
      VALUES (p_attempt_id, v_key::uuid, v_choice, v_is_correct, now())
      ON CONFLICT (attempt_id, question_id)
      DO UPDATE SET
        selected_choice = EXCLUDED.selected_choice,
        is_correct = EXCLUDED.is_correct,
        answered_at = EXCLUDED.answered_at;
      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('success', true, 'saved', v_count);
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_batch_submit_answers TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_batch_submit_answers TO anon;
