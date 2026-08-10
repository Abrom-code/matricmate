-- =====================================================================
-- 0003_payment_rpcs.sql
--
-- Atomic approve / reject for the payment review queue.
--
-- WHY THESE ARE RPCs AND NOT THREE CLIENT CALLS
--   Approving a payment is three writes that must not come apart:
--     1. payment_receipts -> status, reviewed_by, reviewed_at, amount
--     2. users            -> subscription_status
--     3. admin_audit_log  -> an immutable record of who did it
--   Done from the client they are three round trips with two windows where a
--   crash, a dropped connection or a closed laptop leaves the database
--   inconsistent — most dangerously, money marked approved with the student
--   still locked out, or premium granted with no audit trail.
--
--   Inside a function they are one transaction. The push notification stays
--   OUTSIDE deliberately: if FCM fails the database is still correct, and the
--   student's app picks the change up over Realtime anyway.
--
-- DOUBLE-ACTION GUARD
--   Both functions re-read the row FOR UPDATE and abort unless it is still
--   'pending'. Two reviewers working the queue at once cannot both approve
--   the same receipt, and a double-clicked button cannot pay twice.
-- =====================================================================

BEGIN;

-- ── APPROVE ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_approve_payment(
    p_receipt_id bigint,
    p_user_id    text,
    p_admin_uid  text,
    p_amount     numeric DEFAULT NULL,
    p_note       text    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_receipt      public.payment_receipts%ROWTYPE;
    v_before       jsonb;
    v_after        jsonb;
    v_user_before  text;
    v_reviewer     text;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'not authorised';
    END IF;

    -- Lock the row for the duration of the transaction.
    SELECT * INTO v_receipt
    FROM public.payment_receipts
    WHERE id = p_receipt_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'receipt % not found', p_receipt_id;
    END IF;

    -- Double-action guard. Name the reviewer so the UI can say who won.
    IF v_receipt.status <> 'pending' THEN
        SELECT coalesce(a.display_name, a.email, v_receipt.reviewed_by)
          INTO v_reviewer
          FROM public.admins a
         WHERE a.firebase_uid = v_receipt.reviewed_by;

        RAISE EXCEPTION 'ALREADY_REVIEWED:%:%',
              v_receipt.status, coalesce(v_reviewer, 'another admin');
    END IF;

    v_before := to_jsonb(v_receipt);

    SELECT subscription_status INTO v_user_before
    FROM public.users WHERE id = p_user_id;

    -- 1. Mark the receipt approved.
    UPDATE public.payment_receipts
       SET status      = 'approved',
           reviewed_by = p_admin_uid,
           reviewed_at = now(),
           amount      = coalesce(p_amount, amount, 250)
     WHERE id = p_receipt_id
     RETURNING * INTO v_receipt;

    v_after := to_jsonb(v_receipt);

    -- 2. Grant premium. subscription_status IS the entire premium flag —
    --    there is no expiry date, plan type or duration anywhere in the
    --    schema, so this is permanent until someone changes it back.
    UPDATE public.users
       SET subscription_status = 'active'
     WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'user % not found', p_user_id;
    END IF;

    -- 3. Audit.
    INSERT INTO public.admin_audit_log
        (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (
        p_admin_uid,
        'approve_payment',
        'payment_receipt',
        p_receipt_id::text,
        jsonb_build_object(
            'receipt', v_before,
            'user_subscription_status', v_user_before
        ),
        jsonb_build_object(
            'receipt', v_after,
            'user_subscription_status', 'active'
        ),
        p_note
    );

    RETURN jsonb_build_object(
        'ok', true,
        'receipt_id', p_receipt_id,
        'user_id', p_user_id,
        'amount', v_receipt.amount
    );
END;
$$;


-- ── REJECT ───────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.admin_reject_payment(
    p_receipt_id bigint,
    p_user_id    text,
    p_admin_uid  text,
    p_reason     text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_receipt     public.payment_receipts%ROWTYPE;
    v_before      jsonb;
    v_after       jsonb;
    v_user_before text;
    v_reviewer    text;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'not authorised';
    END IF;

    IF p_reason IS NULL OR btrim(p_reason) = '' THEN
        RAISE EXCEPTION 'a rejection reason is required';
    END IF;

    SELECT * INTO v_receipt
    FROM public.payment_receipts
    WHERE id = p_receipt_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'receipt % not found', p_receipt_id;
    END IF;

    IF v_receipt.status <> 'pending' THEN
        SELECT coalesce(a.display_name, a.email, v_receipt.reviewed_by)
          INTO v_reviewer
          FROM public.admins a
         WHERE a.firebase_uid = v_receipt.reviewed_by;

        RAISE EXCEPTION 'ALREADY_REVIEWED:%:%',
              v_receipt.status, coalesce(v_reviewer, 'another admin');
    END IF;

    v_before := to_jsonb(v_receipt);

    SELECT subscription_status INTO v_user_before
    FROM public.users WHERE id = p_user_id;

    UPDATE public.payment_receipts
       SET status           = 'rejected',
           reviewed_by      = p_admin_uid,
           reviewed_at      = now(),
           rejection_reason = p_reason
     WHERE id = p_receipt_id
     RETURNING * INTO v_receipt;

    v_after := to_jsonb(v_receipt);

    -- ⚠️ The user is written 'inactive', NOT 'rejected'.
    --
    -- UserModel exposes exactly three status getters:
    --     isActive   => status == 'active'
    --     isPending  => status == 'pending'
    --     isInactive => status == 'inactive'
    -- A value of 'rejected' makes ALL THREE return false, dropping the
    -- student into a UI dead zone with no premium, no pending state and no
    -- call to action — while the push notification tells them their payment
    -- was rejected. The receipt keeps status='rejected' so the admin queue
    -- stays accurate; only the user-facing flag is normalised.
    --
    -- The reason is preserved in payment_receipts.rejection_reason and sent
    -- in the push payload.
    --
    -- If the student app ever handles 'rejected' (Phase 12 item 10), this
    -- line can change — but not before.
    UPDATE public.users
       SET subscription_status = 'inactive'
     WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'user % not found', p_user_id;
    END IF;

    INSERT INTO public.admin_audit_log
        (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (
        p_admin_uid,
        'reject_payment',
        'payment_receipt',
        p_receipt_id::text,
        jsonb_build_object(
            'receipt', v_before,
            'user_subscription_status', v_user_before
        ),
        jsonb_build_object(
            'receipt', v_after,
            'user_subscription_status', 'inactive'
        ),
        p_reason
    );

    RETURN jsonb_build_object(
        'ok', true,
        'receipt_id', p_receipt_id,
        'user_id', p_user_id
    );
END;
$$;


-- ── Manual subscription override (Phase 9) ───────────────────────────
-- Support cases: comping a subscription, revoking a fraudulent one. Audited
-- like everything else, and restricted to the three values UserModel can
-- actually represent.

CREATE OR REPLACE FUNCTION public.admin_set_subscription_status(
    p_user_id   text,
    p_status    text,
    p_admin_uid text,
    p_note      text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_before text;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'not authorised';
    END IF;

    IF p_status NOT IN ('active', 'pending', 'inactive') THEN
        RAISE EXCEPTION
            'status must be active, pending or inactive (got %)', p_status;
    END IF;

    SELECT subscription_status INTO v_before
    FROM public.users WHERE id = p_user_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'user % not found', p_user_id;
    END IF;

    UPDATE public.users
       SET subscription_status = p_status
     WHERE id = p_user_id;

    INSERT INTO public.admin_audit_log
        (admin_uid, action, entity_type, entity_id, before, after, note)
    VALUES (
        p_admin_uid,
        'set_subscription_status',
        'user',
        p_user_id,
        jsonb_build_object('subscription_status', v_before),
        jsonb_build_object('subscription_status', p_status),
        p_note
    );

    RETURN jsonb_build_object('ok', true, 'before', v_before, 'after', p_status);
END;
$$;


-- ── Grants ───────────────────────────────────────────────────────────
DO $$
DECLARE
    fn text;
BEGIN
    FOREACH fn IN ARRAY ARRAY[
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

COMMIT;


-- =====================================================================
-- ROLLBACK
-- =====================================================================
-- BEGIN;
-- DROP FUNCTION IF EXISTS public.admin_set_subscription_status(text, text, text, text);
-- DROP FUNCTION IF EXISTS public.admin_reject_payment(bigint, text, text, text);
-- DROP FUNCTION IF EXISTS public.admin_approve_payment(bigint, text, text, numeric, text);
-- COMMIT;
