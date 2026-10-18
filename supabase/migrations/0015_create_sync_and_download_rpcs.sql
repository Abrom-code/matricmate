-- Migration: 0015_create_sync_and_download_rpcs.sql
-- Description: RPC functions to bundle subject/entrance content and test questions into single HTTP requests,
-- reducing Supabase log ingestion and egress by 70-85%.

-- ─────────────────────────────────────────────────────────────────────
-- 1. rpc_download_subject: Bundles chapters, tests, questions & passages in 1 call
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION rpc_download_subject(
  p_subject_id INTEGER,
  p_is_premium BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_allowed_test_ids INTEGER[];
  v_passage_ids INTEGER[];
  v_result JSONB;
BEGIN
  -- 1. Identify tests allowed for this user tier
  SELECT COALESCE(array_agg(id), ARRAY[]::INTEGER[])
  INTO v_allowed_test_ids
  FROM tests
  WHERE subject_id = p_subject_id
    AND (
      p_is_premium = TRUE 
      OR is_premium = 0 
      OR is_premium IS NULL 
      OR is_premium = 'false'
    );

  -- 2. Identify passages referenced by allowed questions
  SELECT COALESCE(array_agg(DISTINCT passage_id), ARRAY[]::INTEGER[])
  INTO v_passage_ids
  FROM questions
  WHERE test_id = ANY(v_allowed_test_ids)
    AND passage_id IS NOT NULL;

  -- 3. Construct single unified JSON bundle
  SELECT jsonb_build_object(
    'chapters', COALESCE((
      SELECT jsonb_agg(row_to_json(c))
      FROM chapters c
      WHERE c.subject_id = p_subject_id
    ), '[]'::jsonb),

    'tests', COALESCE((
      SELECT jsonb_agg(row_to_json(t))
      FROM tests t
      WHERE t.subject_id = p_subject_id
    ), '[]'::jsonb),

    'questions', COALESCE((
      SELECT jsonb_agg(
        row_to_json(q)::jsonb || jsonb_build_object('section_title', qs.title)
      )
      FROM questions q
      LEFT JOIN question_sections qs ON q.section_id = qs.id
      WHERE q.test_id = ANY(v_allowed_test_ids)
    ), '[]'::jsonb),

    'passages', COALESCE((
      SELECT jsonb_agg(row_to_json(p))
      FROM passages p
      WHERE p.id = ANY(v_passage_ids)
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────
-- 2. rpc_download_entrance: Bundles entrance/model tests, questions & passages
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION rpc_download_entrance(
  p_subject_id INTEGER,
  p_is_premium BOOLEAN DEFAULT FALSE,
  p_is_admin BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_allowed_test_ids INTEGER[];
  v_passage_ids INTEGER[];
  v_result JSONB;
BEGIN
  -- 1. Identify entrance/model tests
  SELECT COALESCE(array_agg(id), ARRAY[]::INTEGER[])
  INTO v_allowed_test_ids
  FROM tests
  WHERE subject_id = p_subject_id
    AND type IN ('entrance', 'model')
    AND (p_is_admin = TRUE OR status = 'published' OR status IS NULL)
    AND (
      p_is_premium = TRUE 
      OR is_premium = 0 
      OR is_premium IS NULL 
      OR is_premium = 'false'
    );

  -- 2. Identify passages
  SELECT COALESCE(array_agg(DISTINCT passage_id), ARRAY[]::INTEGER[])
  INTO v_passage_ids
  FROM questions
  WHERE test_id = ANY(v_allowed_test_ids)
    AND passage_id IS NOT NULL;

  -- 3. Construct single JSON bundle
  SELECT jsonb_build_object(
    'tests', COALESCE((
      SELECT jsonb_agg(row_to_json(t))
      FROM tests t
      WHERE t.subject_id = p_subject_id
        AND t.type IN ('entrance', 'model')
        AND (p_is_admin = TRUE OR t.status = 'published' OR t.status IS NULL)
    ), '[]'::jsonb),

    'questions', COALESCE((
      SELECT jsonb_agg(
        row_to_json(q)::jsonb || jsonb_build_object('section_title', qs.title)
      )
      FROM questions q
      LEFT JOIN question_sections qs ON q.section_id = qs.id
      WHERE q.test_id = ANY(v_allowed_test_ids)
    ), '[]'::jsonb),

    'passages', COALESCE((
      SELECT jsonb_agg(row_to_json(p))
      FROM passages p
      WHERE p.id = ANY(v_passage_ids)
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────
-- 3. rpc_get_test_content: Bundles on-demand test questions & passages in 1 call
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION rpc_get_test_content(p_test_id INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_passage_ids INTEGER[];
  v_result JSONB;
BEGIN
  SELECT COALESCE(array_agg(DISTINCT passage_id), ARRAY[]::INTEGER[])
  INTO v_passage_ids
  FROM questions
  WHERE test_id = p_test_id
    AND passage_id IS NOT NULL;

  SELECT jsonb_build_object(
    'questions', COALESCE((
      SELECT jsonb_agg(
        row_to_json(q)::jsonb || jsonb_build_object('section_title', qs.title)
      )
      FROM questions q
      LEFT JOIN question_sections qs ON q.section_id = qs.id
      WHERE q.test_id = p_test_id
    ), '[]'::jsonb),

    'passages', COALESCE((
      SELECT jsonb_agg(row_to_json(p))
      FROM passages p
      WHERE p.id = ANY(v_passage_ids)
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────
-- 4. increment_receipt_upload_count: Atomically increments upload count
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_receipt_upload_count(p_user_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users
  SET receipt_upload_count = COALESCE(receipt_upload_count, 0) + 1
  WHERE id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION increment_receipt_upload_count TO authenticated;
GRANT EXECUTE ON FUNCTION increment_receipt_upload_count TO anon;

-- ─────────────────────────────────────────────────────────────────────
-- 5. rpc_batch_submit_answers: Submits all challenge answers in 1 call
-- ─────────────────────────────────────────────────────────────────────
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

