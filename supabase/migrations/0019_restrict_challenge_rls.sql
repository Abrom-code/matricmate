-- =============================================================================
-- Migration: 0019_restrict_challenge_rls.sql
-- Description: Tighten Row-Level Security (RLS) policies for all challenge tables
--              and harden challenge RPC functions against unauthorized access.
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. LEADERBOARD CHALLENGES
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Leaderboard challenges are publicly readable" ON public.leaderboard_challenges;
DROP POLICY IF EXISTS "Leaderboard challenges view policy" ON public.leaderboard_challenges;
DROP POLICY IF EXISTS "Admins manage leaderboard challenges" ON public.leaderboard_challenges;

-- Only admins see 'draft' challenges. Authenticated users only see published rounds.
CREATE POLICY "Leaderboard challenges view policy"
ON public.leaderboard_challenges
FOR SELECT
TO authenticated
USING (
    public.is_admin()
    OR status IN ('scheduled', 'live', 'closed', 'archived')
);

CREATE POLICY "Admins manage leaderboard challenges"
ON public.leaderboard_challenges
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. CHALLENGE QUESTION SETS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Challenge question sets are publicly readable" ON public.challenge_question_sets;
DROP POLICY IF EXISTS "Challenge question sets view policy" ON public.challenge_question_sets;
DROP POLICY IF EXISTS "Admins manage challenge question sets" ON public.challenge_question_sets;

-- Question sets are admin banks; students only see sets associated with published challenges
CREATE POLICY "Challenge question sets view policy"
ON public.challenge_question_sets
FOR SELECT
TO authenticated
USING (
    public.is_admin()
    OR EXISTS (
        SELECT 1 FROM public.leaderboard_challenges lc
        WHERE lc.set_id = challenge_question_sets.id
          AND lc.status IN ('scheduled', 'live', 'closed', 'archived')
    )
);

CREATE POLICY "Admins manage challenge question sets"
ON public.challenge_question_sets
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. CHALLENGE QUESTIONS (Contains correct_choice & explanations)
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Challenge questions are publicly readable" ON public.challenge_questions;
DROP POLICY IF EXISTS "Challenge questions view policy" ON public.challenge_questions;
DROP POLICY IF EXISTS "Admins manage challenge questions" ON public.challenge_questions;

-- Anti-cheating protection:
-- 1. Admins see all questions.
-- 2. Students can ONLY select questions if:
--    a) The challenge has ended ('closed' or 'archived') for review / practice, OR
--    b) The student has already SUBMITTED their attempt for this challenge.
-- Note: During an ongoing active attempt, questions are retrieved through rpc_start_attempt
-- (which is SECURITY DEFINER and strips out correct_choice and explanations).
CREATE POLICY "Challenge questions view policy"
ON public.challenge_questions
FOR SELECT
TO authenticated
USING (
    public.is_admin()
    OR EXISTS (
        SELECT 1 FROM public.leaderboard_challenges lc
        WHERE lc.id = challenge_questions.challenge_id
          AND lc.status IN ('closed', 'archived')
    )
    OR EXISTS (
        SELECT 1 FROM public.challenge_attempts ca
        WHERE ca.user_id = auth.uid()
          AND ca.status = 'submitted'
          AND ca.challenge_id = challenge_questions.challenge_id
    )
);

CREATE POLICY "Admins manage challenge questions"
ON public.challenge_questions
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CHALLENGE ATTEMPTS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Challenge attempts are viewable by all" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Users can insert and update own challenge attempts" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Challenge attempts view policy" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Users can insert own challenge attempt" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Users can update own challenge attempt" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Users can delete own challenge attempt" ON public.challenge_attempts;

-- Students can view their OWN attempts (any status), or SUBMITTED attempts of others (for leaderboard).
-- In-progress attempts of other students are strictly hidden!
CREATE POLICY "Challenge attempts view policy"
ON public.challenge_attempts
FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
    OR status = 'submitted'
    OR public.is_admin()
);

CREATE POLICY "Users can insert own challenge attempt"
ON public.challenge_attempts
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = user_id
    OR public.is_admin()
);

CREATE POLICY "Users can update own challenge attempt"
ON public.challenge_attempts
FOR UPDATE
TO authenticated
USING (
    auth.uid() = user_id
    OR public.is_admin()
)
WITH CHECK (
    auth.uid() = user_id
    OR public.is_admin()
);

CREATE POLICY "Users can delete own challenge attempt"
ON public.challenge_attempts
FOR DELETE
TO authenticated
USING (
    auth.uid() = user_id
    OR public.is_admin()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. CHALLENGE ANSWERS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can manage answers for own attempt" ON public.challenge_answers;
DROP POLICY IF EXISTS "Users can view own challenge answers" ON public.challenge_answers;
DROP POLICY IF EXISTS "Users can insert own challenge answers" ON public.challenge_answers;
DROP POLICY IF EXISTS "Users can update own challenge answers" ON public.challenge_answers;
DROP POLICY IF EXISTS "Users can delete own challenge answers" ON public.challenge_answers;

-- Only the student who took the attempt (or admin) can see their answers
CREATE POLICY "Users can view own challenge answers"
ON public.challenge_answers
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.challenge_attempts a
        WHERE a.id = challenge_answers.attempt_id
          AND (a.user_id = auth.uid() OR public.is_admin())
    )
);

-- Answers can only be inserted/updated while the attempt is actively 'in_progress'
CREATE POLICY "Users can insert own challenge answers"
ON public.challenge_answers
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.challenge_attempts a
        WHERE a.id = challenge_answers.attempt_id
          AND (a.user_id = auth.uid() OR public.is_admin())
          AND (a.status = 'in_progress' OR public.is_admin())
    )
);

CREATE POLICY "Users can update own challenge answers"
ON public.challenge_answers
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.challenge_attempts a
        WHERE a.id = challenge_answers.attempt_id
          AND (a.user_id = auth.uid() OR public.is_admin())
          AND (a.status = 'in_progress' OR public.is_admin())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.challenge_attempts a
        WHERE a.id = challenge_answers.attempt_id
          AND (a.user_id = auth.uid() OR public.is_admin())
          AND (a.status = 'in_progress' OR public.is_admin())
    )
);

CREATE POLICY "Users can delete own challenge answers"
ON public.challenge_answers
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.challenge_attempts a
        WHERE a.id = challenge_answers.attempt_id
          AND (a.user_id = auth.uid() OR public.is_admin())
    )
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. CHALLENGE REWARDS
-- ─────────────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Challenge rewards are viewable by all" ON public.challenge_rewards;
DROP POLICY IF EXISTS "Challenge rewards view policy" ON public.challenge_rewards;
DROP POLICY IF EXISTS "Admins can manage challenge rewards" ON public.challenge_rewards;

CREATE POLICY "Challenge rewards view policy"
ON public.challenge_rewards
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can manage challenge rewards"
ON public.challenge_rewards
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. HARDEN RPC FUNCTIONS WITH STRICT CALLER AUTHORIZATION
-- ─────────────────────────────────────────────────────────────────────────────

-- 7.1 Start Attempt: Verifies auth.uid() matches user, enforces schedule & stream eligibility
CREATE OR REPLACE FUNCTION public.rpc_start_attempt(
  p_challenge_id uuid,
  p_user_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge record;
  v_user record;
  v_attempt record;
  v_questions jsonb;
  v_target_uid uuid;
BEGIN
  -- 1. Authentication check
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  v_target_uid := p_user_id::uuid;
  IF auth.uid() != v_target_uid AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- 2. Challenge status check
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

  -- 3. User & stream eligibility check
  SELECT * INTO v_user FROM public.users WHERE id = v_target_uid;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_challenge.audience != 'both' AND lower(v_challenge.audience) != lower(coalesce(v_user.stream, '')) THEN
    RAISE EXCEPTION 'stream_not_eligible';
  END IF;

  -- 4. Create or load attempt
  INSERT INTO public.challenge_attempts (
    challenge_id, user_id, stream, started_at, status
  )
  VALUES (
    v_challenge.id, v_user.id, coalesce(v_user.stream, 'natural'), now(), 'in_progress'
  )
  ON CONFLICT (challenge_id, user_id)
  DO UPDATE SET started_at = challenge_attempts.started_at
  RETURNING * INTO v_attempt;

  IF v_attempt.status = 'submitted' THEN
    RAISE EXCEPTION 'already_submitted';
  END IF;

  -- 5. Return questions WITHOUT correct_choice or explanations
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'order_index', q.order_index,
      'question_text', q.question_text,
      'choices', q.choices,
      'image_url', q.image_url,
      'passage_id', q.passage_id
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  WHERE q.challenge_id = v_challenge.id;

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

-- 7.2 Submit Answer: Verifies caller owns attempt and attempt is in_progress
CREATE OR REPLACE FUNCTION public.rpc_submit_answer(
  p_attempt_id uuid,
  p_question_id uuid,
  p_selected_choice text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_attempt record;
  v_question record;
  v_is_correct boolean := false;
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

  SELECT * INTO v_question FROM public.challenge_questions WHERE id = p_question_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'question_not_found';
  END IF;

  IF trim(lower(coalesce(v_question.correct_choice, ''))) = trim(lower(coalesce(p_selected_choice, ''))) THEN
    v_is_correct := true;
  END IF;

  INSERT INTO public.challenge_answers (attempt_id, question_id, selected_choice, is_correct, answered_at)
  VALUES (p_attempt_id, p_question_id, p_selected_choice, v_is_correct, now())
  ON CONFLICT (attempt_id, question_id)
  DO UPDATE SET
    selected_choice = EXCLUDED.selected_choice,
    is_correct = EXCLUDED.is_correct,
    answered_at = EXCLUDED.answered_at;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 7.3 Submit Attempt: Verifies caller owns attempt
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
  v_questions jsonb;
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

  IF v_attempt.status = 'submitted' THEN
    RETURN jsonb_build_object(
      'success', true,
      'score', v_attempt.score,
      'total_time_seconds', v_attempt.total_time_seconds,
      'status', v_attempt.status
    );
  END IF;

  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = v_attempt.challenge_id;

  -- Compute correct score
  SELECT count(*)::int INTO v_score
  FROM public.challenge_answers
  WHERE attempt_id = p_attempt_id AND is_correct = true;

  -- Compute elapsed time
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

  -- Return review questions WITH answers now that attempt is submitted
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
      'passage_id', q.passage_id
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  WHERE q.challenge_id = v_challenge.id;

  RETURN jsonb_build_object(
    'success', true,
    'score', v_score,
    'total_time_seconds', v_time,
    'status', 'submitted',
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
END;
$$;

-- 7.4 Get Challenge Answers: Only permitted if admin, challenge closed, or caller submitted attempt
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
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT * INTO v_challenge FROM public.leaderboard_challenges WHERE id = p_challenge_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'challenge_not_found';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.challenge_attempts
    WHERE challenge_id = p_challenge_id AND user_id = auth.uid() AND status = 'submitted'
  ) INTO v_is_submitted;

  IF NOT public.is_admin() AND v_challenge.status NOT IN ('closed', 'archived') AND NOT v_is_submitted THEN
    RAISE EXCEPTION 'challenge_answers_restricted';
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
      'passage_id', q.passage_id
    ) ORDER BY q.order_index ASC
  ) INTO v_questions
  FROM public.challenge_questions q
  WHERE q.challenge_id = v_challenge.id;

  RETURN jsonb_build_object(
    'challenge_id', v_challenge.id,
    'subject_id', v_challenge.subject_id,
    'title', v_challenge.title,
    'audience', v_challenge.audience,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
END;
$$;

COMMIT;
