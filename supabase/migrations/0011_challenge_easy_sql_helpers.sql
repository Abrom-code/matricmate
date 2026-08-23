-- =============================================================================
-- 0011_challenge_easy_sql_helpers.sql
-- Direct `challenge_id` architecture (1 Challenge = Questions directly attached)
-- Supports bilingual explanations (explanation_en & explanation_am)
-- Returns full explanations upon submit/time expiry for post-attempt review.
-- =============================================================================

BEGIN;

-- 1. Add challenge_id, explanation_en, explanation_am columns
ALTER TABLE public.challenge_questions 
ADD COLUMN IF NOT EXISTS challenge_id uuid REFERENCES public.leaderboard_challenges(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS explanation_en text,
ADD COLUMN IF NOT EXISTS explanation_am text;

-- 2. Make set_id optional everywhere
ALTER TABLE public.challenge_questions ALTER COLUMN set_id DROP NOT NULL;
ALTER TABLE public.leaderboard_challenges ALTER COLUMN set_id DROP NOT NULL;

-- 3. Trigger: Auto-sync set_id <-> challenge_id and explanations
CREATE OR REPLACE FUNCTION public.trg_sync_challenge_question_ids()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.set_id IS NULL AND NEW.challenge_id IS NOT NULL THEN
    SELECT set_id INTO NEW.set_id FROM public.leaderboard_challenges WHERE id = NEW.challenge_id;
  END IF;

  IF NEW.challenge_id IS NULL AND NEW.set_id IS NOT NULL THEN
    SELECT id INTO NEW.challenge_id FROM public.leaderboard_challenges WHERE set_id = NEW.set_id LIMIT 1;
  END IF;

  IF NEW.explanation IS NULL AND NEW.explanation_en IS NOT NULL THEN
    NEW.explanation := NEW.explanation_en;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_challenge_questions ON public.challenge_questions;
CREATE TRIGGER trg_sync_challenge_questions
BEFORE INSERT OR UPDATE ON public.challenge_questions
FOR EACH ROW EXECUTE FUNCTION public.trg_sync_challenge_question_ids();

-- 4. Update rpc_start_attempt to match by challenge_id directly
CREATE OR REPLACE FUNCTION public.rpc_start_attempt(
  p_challenge_id uuid,
  p_user_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_challenge record;
  v_user record;
  v_attempt record;
  v_questions jsonb;
BEGIN
  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = p_challenge_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'challenge_not_found';
  END IF;

  IF v_challenge.status NOT IN ('live', 'scheduled') THEN
    RAISE EXCEPTION 'challenge_not_active';
  END IF;

  IF v_challenge.starts_at IS NOT NULL AND now() < v_challenge.starts_at THEN
    RAISE EXCEPTION 'challenge_not_started';
  END IF;

  IF v_challenge.ends_at IS NOT NULL AND now() > v_challenge.ends_at THEN
    RAISE EXCEPTION 'challenge_ended';
  END IF;

  SELECT * INTO v_user FROM public.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_challenge.audience != 'both' AND lower(v_challenge.audience) != lower(v_user.stream) THEN
    RAISE EXCEPTION 'stream_not_eligible';
  END IF;

  INSERT INTO public.challenge_attempts (
    challenge_id, user_id, stream, started_at, status
  )
  VALUES (
    v_challenge.id, v_user.id, v_user.stream, now(), 'in_progress'
  )
  ON CONFLICT (challenge_id, user_id)
  DO UPDATE SET started_at = challenge_attempts.started_at
  RETURNING * INTO v_attempt;

  IF v_attempt.status = 'submitted' THEN
    RAISE EXCEPTION 'already_submitted';
  END IF;

  -- Return test questions WITHOUT correct answers during active attempt
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'order_index', q.order_index,
      'question_text', q.question_text,
      'choices', q.choices,
      'image_url', q.image_url
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  WHERE q.challenge_id = v_challenge.id 
     OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id);

  RETURN jsonb_build_object(
    'attempt_id', v_attempt.id,
    'challenge_id', v_challenge.id,
    'title', v_challenge.title,
    'duration_seconds', v_challenge.duration_seconds,
    'started_at', v_attempt.started_at,
    'ends_at', v_challenge.ends_at,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
END;
$$;

-- 5. Update rpc_submit_attempt to return questions with full bilingual explanations
CREATE OR REPLACE FUNCTION public.rpc_submit_attempt(
  p_attempt_id uuid,
  p_total_time_seconds int DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_attempt record;
  v_challenge record;
  v_score int := 0;
  v_time int := 0;
  v_questions jsonb;
BEGIN
  SELECT * INTO v_attempt FROM public.challenge_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'attempt_not_found';
  END IF;

  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = v_attempt.challenge_id;

  -- Compute correct count
  SELECT count(*)::int INTO v_score
  FROM public.challenge_answers
  WHERE attempt_id = p_attempt_id AND is_correct = true;

  -- Compute total time
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

  -- Load complete questions with correct choices & explanations for post-attempt review
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
      'image_url', q.image_url
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  WHERE q.challenge_id = v_challenge.id 
     OR (v_challenge.set_id IS NOT NULL AND q.set_id = v_challenge.set_id);

  RETURN jsonb_build_object(
    'success', true,
    'score', v_score,
    'total_time_seconds', v_time,
    'status', 'submitted',
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
END;
$$;

COMMIT;
