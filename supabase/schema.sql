-- =====================================================================
-- schema.sql  —  MatricET complete database schema (v1, clean install)
--
-- Run this once on a fresh Supabase project.
-- After running, go to Supabase → Table Editor and set Realtime on:
--   app_config, notifications, notification_reads, users
-- Then run:
--   ALTER TABLE public.app_config           REPLICA IDENTITY FULL;
--   ALTER TABLE public.notifications        REPLICA IDENTITY FULL;
--   ALTER TABLE public.notification_reads   REPLICA IDENTITY FULL;
--   ALTER TABLE public.users                REPLICA IDENTITY FULL;
-- =====================================================================

BEGIN;


-- =====================================================================
-- CORE STUDENT TABLES
-- =====================================================================

-- users
-- id is a Firebase UID (text). NOT a Supabase auth uuid.
-- The student app signs in anonymously via ensure_supabase_auth.dart;
-- auth.uid() and users.id are unrelated values. Never use auth.uid() = id.
CREATE TABLE public.users (
    id                  text PRIMARY KEY,
    first_name          text NOT NULL,
    last_name           text,
    email               text NOT NULL,
    stream              text,
    subscription_status text NOT NULL DEFAULT 'inactive',
    fcm_token           text,
    created_at          timestamptz NOT NULL DEFAULT now(),
    last_active_at      timestamptz
);

CREATE INDEX users_subscription_idx ON public.users (subscription_status);
CREATE INDEX users_stream_idx       ON public.users (stream);


-- subjects
CREATE TABLE public.subjects (
    id                       integer PRIMARY KEY,
    name                     text    NOT NULL UNIQUE,
    is_natural               boolean NOT NULL DEFAULT false,
    is_common                boolean NOT NULL DEFAULT false,
    is_downloaded            boolean NOT NULL DEFAULT false,
    is_entrance_downloaded   boolean NOT NULL DEFAULT false,
    entrance_count           integer NOT NULL DEFAULT 0,
    model_count              integer NOT NULL DEFAULT 0
);


-- chapters
CREATE TABLE public.chapters (
    id             integer PRIMARY KEY,
    subject_id     integer NOT NULL REFERENCES public.subjects (id) ON DELETE CASCADE,
    grade          integer NOT NULL,
    chapter_number integer NOT NULL,
    title          text    NOT NULL
);

CREATE INDEX chapters_subject_idx ON public.chapters (subject_id);


-- passages
CREATE TABLE public.passages (
    id         integer PRIMARY KEY,
    content    text    NOT NULL,
    title      text,
    image_url  text,
    updated_at timestamptz
);


-- question_sections
CREATE TABLE public.question_sections (
    id    integer PRIMARY KEY,
    title text NOT NULL
);


-- tests
CREATE TABLE public.tests (
    id             integer PRIMARY KEY,
    subject_id     integer NOT NULL REFERENCES public.subjects  (id) ON DELETE CASCADE,
    chapter_id     integer          REFERENCES public.chapters  (id) ON DELETE CASCADE,
    grade          integer,
    title          text    NOT NULL,
    type           text    NOT NULL DEFAULT 'chapter',
    question_count integer NOT NULL,
    time           integer NOT NULL DEFAULT -1,   -- -1 = untimed
    description    text,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX tests_subject_grade_chapter_idx ON public.tests (subject_id, grade, chapter_id);
CREATE INDEX tests_type_idx                  ON public.tests (type);


-- questions
CREATE TABLE public.questions (
    id                    integer PRIMARY KEY,
    subject_id            integer NOT NULL REFERENCES public.subjects  (id) ON DELETE CASCADE,
    test_id               integer NOT NULL REFERENCES public.tests     (id) ON DELETE CASCADE,
    chapter_id            integer          REFERENCES public.chapters  (id) ON DELETE SET NULL,
    passage_id            integer          REFERENCES public.passages  (id) ON DELETE SET NULL,
    grade                 integer,
    question_text         text    NOT NULL,
    image_url             text,
    options               jsonb   NOT NULL,
    correct_option_index  integer NOT NULL,
    explanation_en        text,
    explanation_am        text,
    explanation_image_url text,
    question_order        integer NOT NULL DEFAULT 1,
    section_id            integer          REFERENCES public.question_sections (id) ON DELETE SET NULL,
    section_title         text,
    updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX questions_subject_grade_idx ON public.questions (subject_id, grade);
CREATE INDEX questions_chapter_idx       ON public.questions (chapter_id);
CREATE INDEX questions_test_idx          ON public.questions (test_id);
CREATE INDEX questions_passage_idx       ON public.questions (passage_id);


-- user_sessions  (single-device lock)
CREATE TABLE public.user_sessions (
    firebase_uid text    NOT NULL,
    device_id    uuid    NOT NULL,
    trial        integer NOT NULL DEFAULT 5,
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (firebase_uid)
);


-- payment_receipts
-- The student app inserts: user_id, receipt_path, receipt_url,
-- payment_method, verification_url. All other columns are defaulted/nullable.
CREATE TABLE public.payment_receipts (
    id               bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id          text   NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
    receipt_path     text   NOT NULL,
    receipt_url      text   NOT NULL,
    payment_method   text   NOT NULL,
    verification_url text,
    status           text   NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'approved', 'rejected')),
    amount           numeric(10, 2),
    currency         text   NOT NULL DEFAULT 'ETB',
    reviewed_by      text,
    reviewed_at      timestamptz,
    rejection_reason text,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX payment_receipts_user_idx            ON public.payment_receipts (user_id);
CREATE INDEX payment_receipts_status_created_idx  ON public.payment_receipts (status, created_at DESC);


-- =====================================================================
-- APP CONFIGURATION  (payment accounts, subscription price, etc.)
-- =====================================================================
-- Rows are key/value pairs loaded at startup and watched via Realtime.
-- The student app reads this as anon — no RLS.
--
-- Standard keys:
--   payment_telebirr          account number
--   payment_telebirr_holder   holder name
--   payment_cbe_birr          account number
--   payment_cbe_birr_holder   holder name
--   payment_abyssinia         account number
--   payment_abyssinia_holder  holder name
--   payment_mpesa             account number
--   payment_mpesa_holder      holder name
--   payment_extra_accounts    JSON array of extra methods
--   subscription_price        integer ETB
--   trial_count               integer, default trials given to new users
--   webhook_secret            shared secret for send-push edge function

CREATE TABLE public.app_config (
    key         text PRIMARY KEY,
    value       text,
    description text
);

-- Seed the required rows so the app always has defaults to show.
INSERT INTO public.app_config (key, value, description) VALUES
    ('payment_telebirr',         '',    'Telebirr account number'),
    ('payment_telebirr_holder',  '',    'Telebirr account holder name'),
    ('payment_cbe_birr',         '',    'CBE Birr account number'),
    ('payment_cbe_birr_holder',  '',    'CBE Birr account holder name'),
    ('payment_abyssinia',        '',    'Abyssinia bank account number'),
    ('payment_abyssinia_holder', '',    'Abyssinia bank account holder name'),
    ('payment_mpesa',            '',    'M-PESA account number'),
    ('payment_mpesa_holder',     '',    'M-PESA account holder name'),
    ('payment_extra_accounts',   '[]',  'JSON array of extra payment methods'),
    ('subscription_price',       '300', 'Subscription price in ETB'),
    ('trial_count',              '3',   'Free trial attempts given to new users'),
    ('webhook_secret',           '',    'Shared secret for send-push edge function header x-webhook-secret')
ON CONFLICT (key) DO NOTHING;


-- =====================================================================
-- NOTIFICATIONS
-- =====================================================================

-- notifications
-- user_id is text (Firebase UID). NULL = broadcast row.
-- No FK to users — the edge function writes this with the service role
-- and an FK adds a failure mode for no benefit.
-- target_stream: NULL = all users; 'natural' / 'social' = stream-scoped.
CREATE TABLE public.notifications (
    id            bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id       text,                   -- NULL = broadcast
    title         text    NOT NULL,
    body          text    NOT NULL DEFAULT '',
    type          text    NOT NULL DEFAULT 'announcement'
                  CHECK (type IN ('announcement', 'payment', 'new_content')),
    target_stream text,                   -- NULL = global broadcast
    payload       jsonb   NOT NULL DEFAULT '{}',
    is_read       boolean NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    created_by    text                    -- admin firebase_uid who sent it
);

CREATE INDEX notifications_user_created_idx   ON public.notifications (user_id, created_at DESC);
CREATE INDEX notifications_broadcast_idx      ON public.notifications (created_at DESC) WHERE user_id IS NULL;
CREATE INDEX notifications_stream_idx         ON public.notifications (target_stream) WHERE user_id IS NULL;


-- notification_reads  (per-user read state for broadcast rows)
-- user_id is text (Firebase UID), matching users.id.
-- No FK to users — avoids blocking the student client (runs as anon).
CREATE TABLE public.notification_reads (
    notification_id bigint NOT NULL REFERENCES public.notifications (id) ON DELETE CASCADE,
    user_id         text   NOT NULL,
    read_at         timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (notification_id, user_id)
);

CREATE INDEX notification_reads_user_idx ON public.notification_reads (user_id);


-- =====================================================================
-- ADMIN TABLES
-- =====================================================================

-- admins
-- firebase_uid is PK — Firebase Auth is the identity provider.
-- is_admin() matches on email because that is what the admin-auth
-- edge function can assert from a verified Firebase ID token.
CREATE TABLE public.admins (
    firebase_uid  text PRIMARY KEY,
    email         text    NOT NULL UNIQUE,
    display_name  text,
    role          text    NOT NULL DEFAULT 'admin'
                  CHECK (role IN ('admin', 'superadmin')),
    is_active     boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    last_login_at timestamptz
);

CREATE INDEX admins_email_active_idx ON public.admins (email) WHERE is_active;

-- FK from notifications.created_by → admins
ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.admins (firebase_uid);

-- FK from payment_receipts.reviewed_by → admins
ALTER TABLE public.payment_receipts
    ADD CONSTRAINT payment_receipts_reviewed_by_fkey
    FOREIGN KEY (reviewed_by) REFERENCES public.admins (firebase_uid);


-- admin_audit_log  (append-only by RLS policy — no UPDATE/DELETE granted)
CREATE TABLE public.admin_audit_log (
    id          bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    admin_uid   text   NOT NULL,
    action      text   NOT NULL,
    entity_type text   NOT NULL,
    entity_id   text,
    before      jsonb,
    after       jsonb,
    note        text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX admin_audit_log_created_idx       ON public.admin_audit_log (created_at DESC);
CREATE INDEX admin_audit_log_admin_created_idx ON public.admin_audit_log (admin_uid, created_at DESC);
CREATE INDEX admin_audit_log_entity_idx        ON public.admin_audit_log (entity_type, entity_id);


-- test_attempts  (server-side analytics — synced from client, Phase 12)
CREATE TABLE public.test_attempts (
    id             bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    user_id        text    NOT NULL,
    test_id        integer NOT NULL,
    subject_id     integer,
    test_type      text,
    grade          integer,
    correct_count  integer NOT NULL,
    question_count integer NOT NULL,
    score_pct      numeric(5, 2) GENERATED ALWAYS AS (
                       CASE WHEN question_count > 0
                            THEN round(correct_count::numeric * 100 / question_count, 2)
                            ELSE 0
                       END
                   ) STORED,
    is_completed   boolean NOT NULL DEFAULT true,
    duration_secs  integer,
    attempted_at   timestamptz NOT NULL DEFAULT now(),
    synced_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX test_attempts_attempted_idx       ON public.test_attempts (attempted_at DESC);
CREATE INDEX test_attempts_user_attempted_idx  ON public.test_attempts (user_id, attempted_at DESC);
CREATE INDEX test_attempts_subject_idx         ON public.test_attempts (subject_id);
CREATE INDEX test_attempts_type_idx            ON public.test_attempts (test_type);


-- =====================================================================
-- HELPER FUNCTION
-- =====================================================================

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
          AND lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    );
$$;


-- =====================================================================
-- AGGREGATE RPCs  (admin dashboard — one round trip each)
-- =====================================================================

CREATE OR REPLACE FUNCTION public.admin_kpis()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE result jsonb;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    SELECT jsonb_build_object(
        'total_users',        (SELECT count(*) FROM public.users),
        'active_users',       (SELECT count(*) FROM public.users WHERE subscription_status = 'active'),
        'pending_users',      (SELECT count(*) FROM public.users WHERE subscription_status = 'pending'),
        'inactive_users',     (SELECT count(*) FROM public.users WHERE subscription_status = 'inactive'),
        'stream_natural',     (SELECT count(*) FROM public.users WHERE stream = 'natural'),
        'stream_social',      (SELECT count(*) FROM public.users WHERE stream = 'social'),
        'pending_payments',   (SELECT count(*) FROM public.payment_receipts WHERE status = 'pending'),
        'approved_revenue',   (SELECT coalesce(sum(amount), 0) FROM public.payment_receipts WHERE status = 'approved'),
        'attempts_today',     (SELECT count(*) FROM public.test_attempts WHERE attempted_at >= date_trunc('day', now())),
        'attempts_7d',        (SELECT count(*) FROM public.test_attempts WHERE attempted_at >= now() - interval '7 days'),
        'push_reachable',     (SELECT count(*) FROM public.users WHERE fcm_token IS NOT NULL AND fcm_token <> ''),
        'users_with_attempts',(SELECT count(DISTINCT user_id) FROM public.test_attempts)
    ) INTO result;
    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_signups_daily(days integer DEFAULT 30)
RETURNS TABLE (day date, count integer)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    RETURN QUERY
    SELECT d.day::date, coalesce(count(u.id), 0)::integer
    FROM generate_series(
        date_trunc('day', now()) - make_interval(days => days - 1),
        date_trunc('day', now()), interval '1 day') AS d(day)
    LEFT JOIN public.users u ON date_trunc('day', u.created_at) = d.day
    GROUP BY d.day ORDER BY d.day;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_revenue_daily(days integer DEFAULT 30)
RETURNS TABLE (day date, amount numeric, count integer)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    RETURN QUERY
    SELECT d.day::date, coalesce(sum(p.amount), 0)::numeric, count(p.id)::integer
    FROM generate_series(
        date_trunc('day', now()) - make_interval(days => days - 1),
        date_trunc('day', now()), interval '1 day') AS d(day)
    LEFT JOIN public.payment_receipts p
        ON date_trunc('day', p.reviewed_at) = d.day AND p.status = 'approved'
    GROUP BY d.day ORDER BY d.day;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_funnel()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE result jsonb;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    SELECT jsonb_build_object(
        'signups',           (SELECT count(*) FROM public.users),
        'first_attempt',     (SELECT count(DISTINCT user_id) FROM public.test_attempts),
        'payment_submitted', (SELECT count(DISTINCT user_id) FROM public.payment_receipts),
        'approved',          (SELECT count(DISTINCT user_id) FROM public.payment_receipts WHERE status = 'approved')
    ) INTO result;
    RETURN result;
END;
$$;


-- =====================================================================
-- PAYMENT RPCs  (atomic approve / reject)
-- =====================================================================

CREATE OR REPLACE FUNCTION public.admin_approve_payment(
    p_receipt_id bigint,
    p_user_id    text,
    p_admin_uid  text,
    p_amount     numeric DEFAULT NULL,
    p_note       text    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE
    v_receipt     public.payment_receipts%ROWTYPE;
    v_before      jsonb;
    v_after       jsonb;
    v_user_before text;
    v_reviewer    text;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;

    SELECT * INTO v_receipt FROM public.payment_receipts
    WHERE id = p_receipt_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'receipt % not found', p_receipt_id; END IF;

    IF v_receipt.status <> 'pending' THEN
        SELECT coalesce(a.display_name, a.email, v_receipt.reviewed_by) INTO v_reviewer
        FROM public.admins a WHERE a.firebase_uid = v_receipt.reviewed_by;
        RAISE EXCEPTION 'ALREADY_REVIEWED:%:%', v_receipt.status, coalesce(v_reviewer, 'another admin');
    END IF;

    v_before := to_jsonb(v_receipt);
    SELECT subscription_status INTO v_user_before FROM public.users WHERE id = p_user_id;

    UPDATE public.payment_receipts
    SET status = 'approved', reviewed_by = p_admin_uid, reviewed_at = now(),
        amount = coalesce(p_amount, amount, 300)
    WHERE id = p_receipt_id RETURNING * INTO v_receipt;

    v_after := to_jsonb(v_receipt);

    UPDATE public.users SET subscription_status = 'active' WHERE id = p_user_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'user % not found', p_user_id; END IF;

    INSERT INTO public.admin_audit_log (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (p_admin_uid, 'approve_payment', 'payment_receipt', p_receipt_id::text,
            jsonb_build_object('receipt', v_before, 'user_subscription_status', v_user_before),
            jsonb_build_object('receipt', v_after,  'user_subscription_status', 'active'), p_note);

    RETURN jsonb_build_object('ok', true, 'receipt_id', p_receipt_id,
                              'user_id', p_user_id, 'amount', v_receipt.amount);
END;
$$;


CREATE OR REPLACE FUNCTION public.admin_reject_payment(
    p_receipt_id bigint,
    p_user_id    text,
    p_admin_uid  text,
    p_reason     text
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE
    v_receipt     public.payment_receipts%ROWTYPE;
    v_before      jsonb;
    v_after       jsonb;
    v_user_before text;
    v_reviewer    text;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    IF p_reason IS NULL OR btrim(p_reason) = '' THEN
        RAISE EXCEPTION 'a rejection reason is required';
    END IF;

    SELECT * INTO v_receipt FROM public.payment_receipts
    WHERE id = p_receipt_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'receipt % not found', p_receipt_id; END IF;

    IF v_receipt.status <> 'pending' THEN
        SELECT coalesce(a.display_name, a.email, v_receipt.reviewed_by) INTO v_reviewer
        FROM public.admins a WHERE a.firebase_uid = v_receipt.reviewed_by;
        RAISE EXCEPTION 'ALREADY_REVIEWED:%:%', v_receipt.status, coalesce(v_reviewer, 'another admin');
    END IF;

    v_before := to_jsonb(v_receipt);
    SELECT subscription_status INTO v_user_before FROM public.users WHERE id = p_user_id;

    UPDATE public.payment_receipts
    SET status = 'rejected', reviewed_by = p_admin_uid, reviewed_at = now(),
        rejection_reason = p_reason
    WHERE id = p_receipt_id RETURNING * INTO v_receipt;

    v_after := to_jsonb(v_receipt);

    UPDATE public.users SET subscription_status = 'inactive' WHERE id = p_user_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'user % not found', p_user_id; END IF;

    INSERT INTO public.admin_audit_log (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (p_admin_uid, 'reject_payment', 'payment_receipt', p_receipt_id::text,
            jsonb_build_object('receipt', v_before, 'user_subscription_status', v_user_before),
            jsonb_build_object('receipt', v_after,  'user_subscription_status', 'inactive'), p_reason);

    RETURN jsonb_build_object('ok', true, 'receipt_id', p_receipt_id, 'user_id', p_user_id);
END;
$$;


CREATE OR REPLACE FUNCTION public.admin_set_subscription_status(
    p_user_id   text,
    p_status    text,
    p_admin_uid text,
    p_note      text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
DECLARE v_before text;
BEGIN
    IF NOT public.is_admin() THEN RAISE EXCEPTION 'not authorised'; END IF;
    IF p_status NOT IN ('active', 'pending', 'inactive') THEN
        RAISE EXCEPTION 'status must be active, pending or inactive (got %)', p_status;
    END IF;

    SELECT subscription_status INTO v_before FROM public.users WHERE id = p_user_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'user % not found', p_user_id; END IF;

    UPDATE public.users SET subscription_status = p_status WHERE id = p_user_id;

    INSERT INTO public.admin_audit_log (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (p_admin_uid, 'set_subscription_status', 'user', p_user_id,
            jsonb_build_object('subscription_status', v_before),
            jsonb_build_object('subscription_status', p_status), p_note);

    RETURN jsonb_build_object('ok', true, 'before', v_before, 'after', p_status);
END;
$$;


-- =====================================================================
-- REVOKE / GRANT  (lock everything down to authenticated admins only)
-- =====================================================================

DO $$
DECLARE fn text;
BEGIN
    FOREACH fn IN ARRAY ARRAY[
        'public.is_admin()',
        'public.admin_kpis()',
        'public.admin_signups_daily(integer)',
        'public.admin_revenue_daily(integer)',
        'public.admin_funnel()',
        'public.admin_approve_payment(bigint, text, text, numeric, text)',
        'public.admin_reject_payment(bigint, text, text, text)',
        'public.admin_set_subscription_status(text, text, text, text)'
    ]
    LOOP
        EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', fn);
        EXECUTE format('REVOKE ALL ON FUNCTION %s FROM anon', fn);
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', fn);
    END LOOP;
END $$;


-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
-- Only the four admin-owned tables get RLS.
-- The student tables (users, notifications, app_config, etc.) do NOT
-- have RLS because the student app runs as `anon` with no real session.
-- See the note in the original migration for the full explanation.

ALTER TABLE public.admins           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

-- admins: only authenticated admins can read; only superadmins can write
CREATE POLICY admins_select ON public.admins
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY admins_write ON public.admins
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.admins a WHERE a.is_active AND a.role = 'superadmin'
        AND lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.admins a WHERE a.is_active AND a.role = 'superadmin'
        AND lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    ));

-- admin_audit_log: readable by admins, appendable by admins, never editable
CREATE POLICY audit_select ON public.admin_audit_log
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY audit_insert ON public.admin_audit_log
    FOR INSERT TO authenticated WITH CHECK (public.is_admin());

-- test_attempts: student can insert (anon, no session), only admin can read
CREATE POLICY attempts_insert ON public.test_attempts
    FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY attempts_select ON public.test_attempts
    FOR SELECT TO authenticated USING (public.is_admin());

-- notification_reads: student (anon) can insert and read their own reads
CREATE POLICY reads_insert ON public.notification_reads
    FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY reads_select ON public.notification_reads
    FOR SELECT TO anon, authenticated USING (true);


-- =====================================================================
-- REALTIME  (enable publication for live-updating tables)
-- =====================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.app_config;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_reads;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;

-- REPLICA IDENTITY FULL is required so DELETE events carry oldRecord
-- and UPDATE events carry all columns (not just changed ones).
ALTER TABLE public.app_config         REPLICA IDENTITY FULL;
ALTER TABLE public.notifications      REPLICA IDENTITY FULL;
ALTER TABLE public.notification_reads REPLICA IDENTITY FULL;
ALTER TABLE public.users              REPLICA IDENTITY FULL;


COMMIT;


-- =====================================================================
-- AFTER RUNNING THIS FILE:
--
-- 1. Seed your first admin (replace the placeholders):
--
--    INSERT INTO public.admins (firebase_uid, email, display_name, role, is_active)
--    VALUES ('FIREBASE_UID', 'admin@example.com', 'Admin Name', 'superadmin', true);
--
-- 2. Set payment config values via Supabase Table Editor or:
--
--    UPDATE public.app_config SET value = '0912345678' WHERE key = 'payment_telebirr';
--    UPDATE public.app_config SET value = 'Holder Name' WHERE key = 'payment_telebirr_holder';
--    UPDATE public.app_config SET value = '300' WHERE key = 'subscription_price';
--    (leave account number empty to hide a payment method from the app)
--
-- 3. Deploy the send-push edge function:
--    supabase functions deploy send-push
-- =====================================================================
