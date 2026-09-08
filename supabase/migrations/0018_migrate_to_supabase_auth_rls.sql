-- =====================================================================
-- 0018_migrate_to_supabase_auth_rls.sql
--
-- Complete migration from Firebase Auth to Supabase Auth:
--   1. Drops dependent views before column type alterations.
--   2. Converts public.users.id from text (Firebase UID) to uuid
--      referencing auth.users(id) ON DELETE CASCADE.
--   3. Updates all referencing tables to uuid with ON DELETE CASCADE.
--   4. Renames user_sessions.firebase_uid to user_id (uuid).
--   5. Recreates leaderboard views.
--   6. Ensures test_attempts and admin_audit_log tables exist.
--   7. Updates admins table and is_admin() function.
--   8. Adds auth.users trigger (handle_new_user) to auto-provision users.
--   9. Adds delete_own_account() SECURITY DEFINER RPC.
--  10. Enables Row Level Security (RLS) and defines secure policies.
--  11. Configures Supabase Storage RLS for receipts.
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 1: Drop views that depend on challenge_attempts.user_id
-- ─────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS public.v_challenge_leaderboard CASCADE;
DROP VIEW IF EXISTS public.v_challenge_leaderboard_weekly CASCADE;
DROP VIEW IF EXISTS public.v_challenge_leaderboard_monthly CASCADE;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 1b: Drop existing policies in public schema before type alterations
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN (
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I CASCADE',
                       pol.policyname, pol.schemaname, pol.tablename);
        RAISE NOTICE 'Dropped policy: % ON %.%', pol.policyname, pol.schemaname, pol.tablename;
    END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 2: Drop foreign key constraints pointing to public.users(id)
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tc.table_schema, tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
         AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND ccu.table_schema = 'public'
          AND ccu.table_name = 'users'
          AND ccu.column_name = 'id'
    ) LOOP
        EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I CASCADE',
                       r.table_schema, r.table_name, r.constraint_name);
        RAISE NOTICE 'Dropped FK constraint: %.% (%)', r.table_schema, r.table_name, r.constraint_name;
    END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 3: Handle user_sessions column rename and table alterations
-- ─────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'user_sessions'
          AND column_name = 'firebase_uid'
    ) THEN
        ALTER TABLE public.user_sessions RENAME COLUMN firebase_uid TO user_id;
        RAISE NOTICE 'Renamed user_sessions.firebase_uid to user_id';
    END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 4: Clean up any non-UUID test/dev rows and alter column types to uuid
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    v_is_text boolean;
BEGIN
    SELECT (data_type = 'text' OR data_type = 'character varying') INTO v_is_text
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id';

    IF v_is_text THEN
        -- Delete historical dummy test data with non-UUID Firebase UIDs
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notification_reads') THEN
            DELETE FROM public.notification_reads WHERE user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_sessions') THEN
            DELETE FROM public.user_sessions WHERE user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payment_receipts') THEN
            DELETE FROM public.payment_receipts WHERE user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'challenge_rewards') THEN
            DELETE FROM public.challenge_rewards WHERE user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'challenge_attempts') THEN
            DELETE FROM public.challenge_attempts WHERE user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
            UPDATE public.notifications SET user_id = NULL WHERE user_id IS NOT NULL AND user_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        -- Remove any orphan dummy users not matching UUID
        DELETE FROM public.users WHERE id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

        -- Drop PK on users before type alteration
        ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_pkey CASCADE;

        -- Alter users.id to uuid
        ALTER TABLE public.users ALTER COLUMN id TYPE uuid USING id::uuid;
        ALTER TABLE public.users ADD CONSTRAINT users_pkey PRIMARY KEY (id);

        RAISE NOTICE 'Altered public.users.id to uuid';
    END IF;
END $$;

-- Alter referencing tables to uuid
DO $$
BEGIN
    -- user_sessions.user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'user_sessions' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_pkey CASCADE;
        ALTER TABLE public.user_sessions ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
        ALTER TABLE public.user_sessions ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (user_id);
    END IF;

    -- payment_receipts.user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'payment_receipts' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.payment_receipts ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
    END IF;

    -- notifications.user_id (nullable)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.notifications ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
    END IF;

    -- notification_reads.user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'notification_reads' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.notification_reads ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
    END IF;

    -- challenge_attempts.user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'challenge_attempts' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.challenge_attempts ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
    END IF;

    -- challenge_rewards.user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'challenge_rewards' AND column_name = 'user_id' AND data_type != 'uuid'
    ) THEN
        ALTER TABLE public.challenge_rewards ALTER COLUMN user_id TYPE uuid USING user_id::uuid;
    END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 5: Recreate views
-- ─────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.v_challenge_leaderboard AS
SELECT challenge_id,
       stream,
       user_id,
       score,
       total_time_seconds,
       row_number() OVER (PARTITION BY challenge_id, stream ORDER BY score DESC, total_time_seconds, submitted_at) AS rank
FROM public.challenge_attempts
WHERE status = 'submitted';

CREATE OR REPLACE VIEW public.v_challenge_leaderboard_weekly AS
SELECT a.user_id,
       a.stream,
       date_trunc('week', c.starts_at)::date AS period_start,
       sum(a.score)::integer AS total_score,
       sum(a.total_time_seconds)::integer AS total_time_seconds,
       count(*)::integer AS challenges_taken,
       row_number() OVER (PARTITION BY a.stream, (date_trunc('week', c.starts_at)) ORDER BY sum(a.score) DESC, count(*), sum(a.total_time_seconds)) AS rank
FROM public.challenge_attempts a
JOIN public.leaderboard_challenges c ON c.id = a.challenge_id
WHERE a.status = 'submitted' AND c.starts_at IS NOT NULL
GROUP BY a.user_id, a.stream, (date_trunc('week', c.starts_at));

CREATE OR REPLACE VIEW public.v_challenge_leaderboard_monthly AS
SELECT a.user_id,
       a.stream,
       date_trunc('month', c.starts_at)::date AS period_start,
       sum(a.score)::integer AS total_score,
       sum(a.total_time_seconds)::integer AS total_time_seconds,
       count(*)::integer AS challenges_taken,
       row_number() OVER (PARTITION BY a.stream, (date_trunc('month', c.starts_at)) ORDER BY sum(a.score) DESC, count(*), sum(a.total_time_seconds)) AS rank
FROM public.challenge_attempts a
JOIN public.leaderboard_challenges c ON c.id = a.challenge_id
WHERE a.status = 'submitted' AND c.starts_at IS NOT NULL
GROUP BY a.user_id, a.stream, (date_trunc('month', c.starts_at));

-- ─────────────────────────────────────────────────────────────────────
-- STEP 6: Ensure test_attempts and admin_audit_log tables exist
-- ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.test_attempts (
    id             bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id        uuid    NOT NULL,
    test_id        integer NOT NULL,
    subject_id     integer,
    test_type      text,
    grade          integer,
    score          integer NOT NULL,
    question_count integer NOT NULL,
    time_taken     integer,
    attempted_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id          bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    admin_uid   text NOT NULL,
    action      text NOT NULL,
    entity_type text NOT NULL,
    entity_id   text,
    before      jsonb,
    after       jsonb,
    note        text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────
-- STEP 7: Add foreign key constraints to auth.users and public.users
-- ─────────────────────────────────────────────────────────────────────

-- public.users.id -> auth.users.id ON DELETE CASCADE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_id_fkey'
    ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT users_id_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

ALTER TABLE public.user_sessions
    DROP CONSTRAINT IF EXISTS user_sessions_user_id_fkey,
    ADD CONSTRAINT user_sessions_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.payment_receipts
    DROP CONSTRAINT IF EXISTS payment_receipts_user_id_fkey,
    ADD CONSTRAINT payment_receipts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.notifications
    DROP CONSTRAINT IF EXISTS notifications_user_id_fkey,
    ADD CONSTRAINT notifications_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.notification_reads
    DROP CONSTRAINT IF EXISTS notification_reads_user_id_fkey,
    ADD CONSTRAINT notification_reads_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.test_attempts
    DROP CONSTRAINT IF EXISTS test_attempts_user_id_fkey,
    ADD CONSTRAINT test_attempts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.challenge_attempts
    DROP CONSTRAINT IF EXISTS challenge_attempts_user_id_fkey,
    ADD CONSTRAINT challenge_attempts_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.challenge_rewards
    DROP CONSTRAINT IF EXISTS challenge_rewards_user_id_fkey,
    ADD CONSTRAINT challenge_rewards_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 8: Admins table and is_admin() function
-- ─────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    v_admin_auth_id uuid;
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'admins' AND column_name = 'firebase_uid'
    ) THEN
        ALTER TABLE public.admins DROP CONSTRAINT IF EXISTS admins_pkey CASCADE;
        ALTER TABLE public.admins RENAME COLUMN firebase_uid TO id;

        -- Find if howdes admin user exists in auth.users
        SELECT id INTO v_admin_auth_id FROM auth.users WHERE lower(email) LIKE '%howdes404%' LIMIT 1;

        IF v_admin_auth_id IS NOT NULL THEN
            UPDATE public.admins
            SET id = v_admin_auth_id::text,
                email = 'howdes404@gmail.com'
            WHERE lower(email) LIKE '%howdes404%';
        ELSE
            DELETE FROM public.admins WHERE id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        END IF;

        ALTER TABLE public.admins ALTER COLUMN id TYPE uuid USING id::uuid;
        ALTER TABLE public.admins ADD CONSTRAINT admins_pkey PRIMARY KEY (id);
        ALTER TABLE public.admins DROP CONSTRAINT IF EXISTS admins_id_fkey;
        ALTER TABLE public.admins ADD CONSTRAINT admins_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.admins a
        WHERE a.is_active
          AND (
            a.id = auth.uid()
            OR lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
          )
    );
$$;

COMMENT ON FUNCTION public.is_admin() IS
    'Returns true if authenticated user is active in public.admins by uid or jwt email.';

-- ─────────────────────────────────────────────────────────────────────
-- STEP 9: Auto-provisioning trigger on auth.users
-- ─────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        stream,
        subscription_status,
        created_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'stream', 'natural'),
        'inactive',
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        first_name = CASE WHEN EXCLUDED.first_name <> '' THEN EXCLUDED.first_name ELSE public.users.first_name END,
        last_name = CASE WHEN EXCLUDED.last_name <> '' THEN EXCLUDED.last_name ELSE public.users.last_name END,
        stream = CASE WHEN EXCLUDED.stream <> '' THEN EXCLUDED.stream ELSE public.users.stream END;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────
-- STEP 10: Self-service account deletion RPC
-- ─────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Deleting from auth.users cascades to public.users and all referencing tables
    DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

-- ─────────────────────────────────────────────────────────────────────
-- STEP 11: Row Level Security (RLS) Policies
-- ─────────────────────────────────────────────────────────────────────

-- Enable RLS across all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_question_sets ENABLE ROW LEVEL SECURITY;

-- ── 1. Users policies ────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view own profile or admin" ON public.users;
CREATE POLICY "Users can view own profile or admin" ON public.users
    FOR SELECT USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile or admin" ON public.users;
CREATE POLICY "Users can update own profile or admin" ON public.users
    FOR UPDATE USING (auth.uid() = id OR public.is_admin())
    WITH CHECK (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Users can insert own profile or admin" ON public.users;
CREATE POLICY "Users can insert own profile or admin" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Users can delete own profile or admin" ON public.users;
CREATE POLICY "Users can delete own profile or admin" ON public.users
    FOR DELETE USING (auth.uid() = id OR public.is_admin());

-- ── 2. User sessions policies ────────────────────────────────────────
DROP POLICY IF EXISTS "Users can manage own session" ON public.user_sessions;
CREATE POLICY "Users can manage own session" ON public.user_sessions
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ── 3. Payment receipts policies ─────────────────────────────────────
DROP POLICY IF EXISTS "Users can view own receipts or admin" ON public.payment_receipts;
CREATE POLICY "Users can view own receipts or admin" ON public.payment_receipts
    FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can insert own receipts" ON public.payment_receipts;
CREATE POLICY "Users can insert own receipts" ON public.payment_receipts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can update receipts" ON public.payment_receipts;
CREATE POLICY "Admins can update receipts" ON public.payment_receipts
    FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "Users can delete own pending receipts or admin" ON public.payment_receipts;
CREATE POLICY "Users can delete own pending receipts or admin" ON public.payment_receipts
    FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- ── 4. Notifications policies ────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view global or own notifications" ON public.notifications;
CREATE POLICY "Users can view global or own notifications" ON public.notifications
    FOR SELECT USING (user_id IS NULL OR auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Admins can manage notifications" ON public.notifications;
CREATE POLICY "Admins can manage notifications" ON public.notifications
    FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins or user can delete notifications" ON public.notifications;
CREATE POLICY "Admins or user can delete notifications" ON public.notifications
    FOR DELETE USING (auth.uid() = user_id OR public.is_admin());

-- ── 5. Notification reads policies ───────────────────────────────────
DROP POLICY IF EXISTS "Users can manage own notification reads" ON public.notification_reads;
CREATE POLICY "Users can manage own notification reads" ON public.notification_reads
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ── 6. Test attempts policies ────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view and record own test attempts" ON public.test_attempts;
CREATE POLICY "Users can view and record own test attempts" ON public.test_attempts
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ── 7. Challenge attempts & answers policies ─────────────────────────
DROP POLICY IF EXISTS "Challenge attempts are viewable by all" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Challenge attempts view policy" ON public.challenge_attempts;
CREATE POLICY "Challenge attempts view policy" ON public.challenge_attempts
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id OR status = 'submitted' OR public.is_admin());

DROP POLICY IF EXISTS "Users can insert and update own challenge attempts" ON public.challenge_attempts;
DROP POLICY IF EXISTS "Users can insert own challenge attempt" ON public.challenge_attempts;
CREATE POLICY "Users can insert own challenge attempt" ON public.challenge_attempts
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own challenge attempt" ON public.challenge_attempts;
CREATE POLICY "Users can update own challenge attempt" ON public.challenge_attempts
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can delete own challenge attempt" ON public.challenge_attempts;
CREATE POLICY "Users can delete own challenge attempt" ON public.challenge_attempts
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can manage answers for own attempt" ON public.challenge_answers;
DROP POLICY IF EXISTS "Users can view own challenge answers" ON public.challenge_answers;
CREATE POLICY "Users can view own challenge answers" ON public.challenge_answers
    FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.challenge_attempts a WHERE a.id = challenge_answers.attempt_id AND (a.user_id = auth.uid() OR public.is_admin())));

DROP POLICY IF EXISTS "Users can insert own challenge answers" ON public.challenge_answers;
CREATE POLICY "Users can insert own challenge answers" ON public.challenge_answers
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (SELECT 1 FROM public.challenge_attempts a WHERE a.id = challenge_answers.attempt_id AND (a.user_id = auth.uid() OR public.is_admin()) AND (a.status = 'in_progress' OR public.is_admin())));

DROP POLICY IF EXISTS "Users can update own challenge answers" ON public.challenge_answers;
CREATE POLICY "Users can update own challenge answers" ON public.challenge_answers
    FOR UPDATE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.challenge_attempts a WHERE a.id = challenge_answers.attempt_id AND (a.user_id = auth.uid() OR public.is_admin()) AND (a.status = 'in_progress' OR public.is_admin())))
    WITH CHECK (EXISTS (SELECT 1 FROM public.challenge_attempts a WHERE a.id = challenge_answers.attempt_id AND (a.user_id = auth.uid() OR public.is_admin()) AND (a.status = 'in_progress' OR public.is_admin())));

DROP POLICY IF EXISTS "Users can delete own challenge answers" ON public.challenge_answers;
CREATE POLICY "Users can delete own challenge answers" ON public.challenge_answers
    FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.challenge_attempts a WHERE a.id = challenge_answers.attempt_id AND (a.user_id = auth.uid() OR public.is_admin())));

DROP POLICY IF EXISTS "Challenge rewards are viewable by all" ON public.challenge_rewards;
DROP POLICY IF EXISTS "Challenge rewards view policy" ON public.challenge_rewards;
CREATE POLICY "Challenge rewards view policy" ON public.challenge_rewards
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage challenge rewards" ON public.challenge_rewards;
CREATE POLICY "Admins can manage challenge rewards" ON public.challenge_rewards
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── 8. Public read content tables (subjects, tests, questions, config)
DROP POLICY IF EXISTS "Subjects are publicly readable" ON public.subjects;
CREATE POLICY "Subjects are publicly readable" ON public.subjects FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage subjects" ON public.subjects;
CREATE POLICY "Admins manage subjects" ON public.subjects FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Chapters are publicly readable" ON public.chapters;
CREATE POLICY "Chapters are publicly readable" ON public.chapters FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage chapters" ON public.chapters;
CREATE POLICY "Admins manage chapters" ON public.chapters FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Passages are publicly readable" ON public.passages;
CREATE POLICY "Passages are publicly readable" ON public.passages FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage passages" ON public.passages;
CREATE POLICY "Admins manage passages" ON public.passages FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Question sections are publicly readable" ON public.question_sections;
CREATE POLICY "Question sections are publicly readable" ON public.question_sections FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage question sections" ON public.question_sections;
CREATE POLICY "Admins manage question sections" ON public.question_sections FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Tests are publicly readable" ON public.tests;
CREATE POLICY "Tests are publicly readable" ON public.tests FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage tests" ON public.tests;
CREATE POLICY "Admins manage tests" ON public.tests FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Questions are publicly readable" ON public.questions;
CREATE POLICY "Questions are publicly readable" ON public.questions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage questions" ON public.questions;
CREATE POLICY "Admins manage questions" ON public.questions FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Leaderboard challenges are publicly readable" ON public.leaderboard_challenges;
DROP POLICY IF EXISTS "Leaderboard challenges view policy" ON public.leaderboard_challenges;
CREATE POLICY "Leaderboard challenges view policy" ON public.leaderboard_challenges
    FOR SELECT TO authenticated
    USING (public.is_admin() OR status IN ('scheduled', 'live', 'closed', 'archived'));

DROP POLICY IF EXISTS "Admins manage leaderboard challenges" ON public.leaderboard_challenges;
CREATE POLICY "Admins manage leaderboard challenges" ON public.leaderboard_challenges
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Challenge question sets are publicly readable" ON public.challenge_question_sets;
DROP POLICY IF EXISTS "Challenge question sets view policy" ON public.challenge_question_sets;
CREATE POLICY "Challenge question sets view policy" ON public.challenge_question_sets
    FOR SELECT TO authenticated
    USING (public.is_admin() OR EXISTS (SELECT 1 FROM public.leaderboard_challenges lc WHERE lc.set_id = challenge_question_sets.id AND lc.status IN ('scheduled', 'live', 'closed', 'archived')));

DROP POLICY IF EXISTS "Admins manage challenge question sets" ON public.challenge_question_sets;
CREATE POLICY "Admins manage challenge question sets" ON public.challenge_question_sets
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Challenge questions are publicly readable" ON public.challenge_questions;
DROP POLICY IF EXISTS "Challenge questions view policy" ON public.challenge_questions;
CREATE POLICY "Challenge questions view policy" ON public.challenge_questions
    FOR SELECT TO authenticated
    USING (
        public.is_admin()
        OR EXISTS (SELECT 1 FROM public.leaderboard_challenges lc WHERE lc.id = challenge_questions.challenge_id AND lc.status IN ('closed', 'archived'))
        OR EXISTS (SELECT 1 FROM public.challenge_attempts ca WHERE ca.user_id = auth.uid() AND ca.status = 'submitted' AND ca.challenge_id = challenge_questions.challenge_id)
    );

DROP POLICY IF EXISTS "Admins manage challenge questions" ON public.challenge_questions;
CREATE POLICY "Admins manage challenge questions" ON public.challenge_questions
    FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "App config is publicly readable" ON public.app_config;
CREATE POLICY "App config is publicly readable" ON public.app_config FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins manage app config" ON public.app_config;
CREATE POLICY "Admins manage app config" ON public.app_config FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── 9. Admins and audit logs ─────────────────────────────────────────
DROP POLICY IF EXISTS "Admins can view admins" ON public.admins;
CREATE POLICY "Admins can view admins" ON public.admins FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can view and insert audit logs" ON public.admin_audit_log;
CREATE POLICY "Admins can view and insert audit logs" ON public.admin_audit_log FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────────────
-- STEP 12: Supabase Storage RLS for receipts bucket
-- ─────────────────────────────────────────────────────────────────────

-- Ensure receipts bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Storage RLS: storage.objects already has RLS enabled by default in Supabase.
DROP POLICY IF EXISTS "Allow anyone to delete receipts" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete for everyone" ON storage.objects;
DROP POLICY IF EXISTS "Allow select for everyone" ON storage.objects;
DROP POLICY IF EXISTS "Allow select receipts" ON storage.objects;

DROP POLICY IF EXISTS "Users can upload own receipt" ON storage.objects;
CREATE POLICY "Users can upload own receipt" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'receipts'
        AND (auth.uid())::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users and admins can read receipts" ON storage.objects;
CREATE POLICY "Users and admins can read receipts" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'receipts'
        AND (
            (auth.uid())::text = (storage.foldername(name))[1]
            OR public.is_admin()
        )
    );

DROP POLICY IF EXISTS "Users and admins can delete own receipts" ON storage.objects;
CREATE POLICY "Users and admins can delete own receipts" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'receipts'
        AND (
            (auth.uid())::text = (storage.foldername(name))[1]
            OR public.is_admin()
        )
    );

COMMIT;
