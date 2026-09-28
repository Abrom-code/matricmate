-- seed_pilot_exam_sample.sql
--
-- Sample data to seed a full Pilot Exam simulator in Supabase.
-- It creates 1 Pilot Exam ("1st Semester Model Exam") and sets up:
--   - 4 Natural stream subjects (Mathematics, Physics, Chemistry, Biology)
--   - 4 Social stream subjects  (Mathematics, History, Geography, Economics)
--   - 2 Common subjects         (English, Aptitude / SAT)
-- Total = 10 rows. A student sees exactly 6 subjects (4 stream + 2 common).

DO $$
DECLARE
    v_exam_id BIGINT;
    v_math_nat_id INT;
    v_phys_id     INT;
    v_chem_id     INT;
    v_bio_id      INT;
    v_math_soc_id INT;
    v_hist_id     INT;
    v_geog_id     INT;
    v_econ_id     INT;
    v_eng_id      INT;
    v_apt_id      INT;
BEGIN
    -- 1. Insert Master Pilot Exam
    INSERT INTO public.pilot_exams (title, description, edition, is_active)
    VALUES (
        '1st Semester Model Exam',
        'Nationwide entrance trial simulation covering all 6 curriculum subjects. Scaled to 100 per subject with an aggregate score out of 600.',
        '2017 E.C.',
        true
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_exam_id;

    -- If already existed, fetch its ID
    IF v_exam_id IS NULL THEN
        SELECT id INTO v_exam_id FROM public.pilot_exams WHERE title = '1st Semester Model Exam' LIMIT 1;
    END IF;

    -- 2. Lookup Subject IDs from your existing `subjects` table
    -- (Adjust subject names if they differ slightly in your database)
    SELECT id INTO v_math_nat_id FROM public.subjects WHERE LOWER(name) LIKE '%math%' AND (is_natural = 1 OR is_natural = true) LIMIT 1;
    SELECT id INTO v_phys_id     FROM public.subjects WHERE LOWER(name) LIKE '%physic%' LIMIT 1;
    SELECT id INTO v_chem_id     FROM public.subjects WHERE LOWER(name) LIKE '%chemist%' LIMIT 1;
    SELECT id INTO v_bio_id      FROM public.subjects WHERE LOWER(name) LIKE '%biolog%' LIMIT 1;

    SELECT id INTO v_math_soc_id FROM public.subjects WHERE LOWER(name) LIKE '%math%' AND (is_natural = 0 OR is_natural = false) LIMIT 1;
    SELECT id INTO v_hist_id     FROM public.subjects WHERE LOWER(name) LIKE '%histor%' LIMIT 1;
    SELECT id INTO v_geog_id     FROM public.subjects WHERE LOWER(name) LIKE '%geograph%' LIMIT 1;
    SELECT id INTO v_econ_id     FROM public.subjects WHERE LOWER(name) LIKE '%econom%' LIMIT 1;

    SELECT id INTO v_eng_id      FROM public.subjects WHERE LOWER(name) LIKE '%english%' LIMIT 1;
    SELECT id INTO v_apt_id      FROM public.subjects WHERE LOWER(name) LIKE '%aptitude%' OR LOWER(name) LIKE '%sat%' LIMIT 1;

    -- Fallback safety IDs if exact names aren't matched
    v_math_nat_id := COALESCE(v_math_nat_id, 1);
    v_phys_id     := COALESCE(v_phys_id, 2);
    v_chem_id     := COALESCE(v_chem_id, 3);
    v_bio_id      := COALESCE(v_bio_id, 4);
    v_math_soc_id := COALESCE(v_math_soc_id, 1);
    v_hist_id     := COALESCE(v_hist_id, 5);
    v_geog_id     := COALESCE(v_geog_id, 6);
    v_econ_id     := COALESCE(v_econ_id, 7);
    v_eng_id      := COALESCE(v_eng_id, 8);
    v_apt_id      := COALESCE(v_apt_id, 9);

    -- 3. Insert 4 Natural Subjects
    INSERT INTO public.pilot_exam_subjects (pilot_exam_id, subject_id, subject_name, stream, test_id, order_index, question_count, time_minutes)
    VALUES
        (v_exam_id, v_math_nat_id, 'Mathematics (Natural)', 'natural', (SELECT id FROM public.tests WHERE subject_id = v_math_nat_id ORDER BY id DESC LIMIT 1), 1, 65, 120),
        (v_exam_id, v_phys_id,     'Physics',               'natural', (SELECT id FROM public.tests WHERE subject_id = v_phys_id ORDER BY id DESC LIMIT 1),     2, 50, 90),
        (v_exam_id, v_chem_id,     'Chemistry',             'natural', (SELECT id FROM public.tests WHERE subject_id = v_chem_id ORDER BY id DESC LIMIT 1),     3, 60, 90),
        (v_exam_id, v_bio_id,      'Biology',               'natural', (SELECT id FROM public.tests WHERE subject_id = v_bio_id ORDER BY id DESC LIMIT 1),      4, 60, 90)
    ON CONFLICT (pilot_exam_id, subject_id, stream) DO UPDATE
    SET test_id = EXCLUDED.test_id, question_count = EXCLUDED.question_count, time_minutes = EXCLUDED.time_minutes;

    -- 4. Insert 4 Social Subjects
    INSERT INTO public.pilot_exam_subjects (pilot_exam_id, subject_id, subject_name, stream, test_id, order_index, question_count, time_minutes)
    VALUES
        (v_exam_id, v_math_soc_id, 'Mathematics (Social)',  'social', (SELECT id FROM public.tests WHERE subject_id = v_math_soc_id ORDER BY id DESC LIMIT 1), 1, 60, 105),
        (v_exam_id, v_hist_id,     'History',               'social', (SELECT id FROM public.tests WHERE subject_id = v_hist_id ORDER BY id DESC LIMIT 1),     2, 60, 90),
        (v_exam_id, v_geog_id,     'Geography',             'social', (SELECT id FROM public.tests WHERE subject_id = v_geog_id ORDER BY id DESC LIMIT 1),     3, 60, 90),
        (v_exam_id, v_econ_id,     'Economics',             'social', (SELECT id FROM public.tests WHERE subject_id = v_econ_id ORDER BY id DESC LIMIT 1),     4, 60, 90)
    ON CONFLICT (pilot_exam_id, subject_id, stream) DO UPDATE
    SET test_id = EXCLUDED.test_id, question_count = EXCLUDED.question_count, time_minutes = EXCLUDED.time_minutes;

    -- 5. Insert 2 Common Subjects (Both Natural and Social students take these)
    INSERT INTO public.pilot_exam_subjects (pilot_exam_id, subject_id, subject_name, stream, test_id, order_index, question_count, time_minutes)
    VALUES
        (v_exam_id, v_eng_id,      'English',               'common',  (SELECT id FROM public.tests WHERE subject_id = v_eng_id ORDER BY id DESC LIMIT 1),      5, 60, 90),
        (v_exam_id, v_apt_id,      'Aptitude / SAT',        'common',  (SELECT id FROM public.tests WHERE subject_id = v_apt_id ORDER BY id DESC LIMIT 1),      6, 60, 90)
    ON CONFLICT (pilot_exam_id, subject_id, stream) DO UPDATE
    SET test_id = EXCLUDED.test_id, question_count = EXCLUDED.question_count, time_minutes = EXCLUDED.time_minutes;

END $$;
