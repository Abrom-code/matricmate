-- =============================================================================
-- 0013_auto_challenge_notifications.sql
-- Automatically creates notifications in public.notifications when challenges
-- are created, scheduled, opened (live), or closed.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.trg_fn_on_challenge_notify()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_subj_name text := 'Subject';
  v_target_stream text := NULL;
  v_notif_title text;
  v_notif_body text;
  v_starts_fmt text;
BEGIN
  -- 1. Resolve subject name
  IF NEW.subject_id IS NOT NULL AND NEW.subject_id > 0 THEN
    SELECT name INTO v_subj_name FROM public.subjects WHERE id = NEW.subject_id;
    IF v_subj_name IS NULL THEN
      v_subj_name := 'Subject';
    END IF;
  END IF;

  -- 2. Resolve target stream ('both' -> NULL for all students)
  IF LOWER(TRIM(COALESCE(NEW.audience, 'both'))) = 'both' THEN
    v_target_stream := NULL;
  ELSE
    v_target_stream := LOWER(TRIM(NEW.audience));
  END IF;

  -- ── CASE 1: New Challenge Created (INSERT) ─────────────────────────────────
  IF (TG_OP = 'INSERT') THEN
    IF NEW.status = 'scheduled' THEN
      IF NEW.starts_at IS NOT NULL THEN
        v_starts_fmt := to_char(NEW.starts_at AT TIME ZONE 'UTC', 'Mon DD, YYYY at HH12:MI AM UTC');
        v_notif_title := '📅 New Challenge Scheduled!';
        v_notif_body := NEW.title || ' (' || v_subj_name || ') is scheduled for ' || v_starts_fmt || '. Get ready to compete!';
      ELSE
        v_notif_title := '📅 New Challenge Scheduled!';
        v_notif_body := NEW.title || ' (' || v_subj_name || ') has been scheduled. Check the Challenges tab!';
      END IF;

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        target_stream,
        payload,
        is_read,
        created_at
      ) VALUES (
        NULL,
        v_notif_title,
        v_notif_body,
        'challenge',
        v_target_stream,
        jsonb_build_object(
          'type', 'challenge_scheduled',
          'challenge_id', NEW.id::text,
          'status', 'scheduled',
          'title', NEW.title,
          'audience', COALESCE(NEW.audience, 'both')
        ),
        false,
        NOW()
      );

    ELSIF NEW.status = 'live' THEN
      v_notif_title := '🔥 Challenge is LIVE!';
      v_notif_body := NEW.title || ' (' || v_subj_name || ') is now live! Test your knowledge and climb the leaderboard.';

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        target_stream,
        payload,
        is_read,
        created_at
      ) VALUES (
        NULL,
        v_notif_title,
        v_notif_body,
        'challenge',
        v_target_stream,
        jsonb_build_object(
          'type', 'challenge_live',
          'challenge_id', NEW.id::text,
          'status', 'live',
          'title', NEW.title,
          'audience', COALESCE(NEW.audience, 'both')
        ),
        false,
        NOW()
      );
    END IF;

  -- ── CASE 2: Challenge Status Transitioned (UPDATE) ─────────────────────────
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Scheduled -> Live
    IF (OLD.status IS DISTINCT FROM NEW.status) AND (NEW.status = 'live') THEN
      v_notif_title := '🔥 Challenge is LIVE!';
      v_notif_body := NEW.title || ' (' || v_subj_name || ') is now live! Test your knowledge and climb the leaderboard.';

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        target_stream,
        payload,
        is_read,
        created_at
      ) VALUES (
        NULL,
        v_notif_title,
        v_notif_body,
        'challenge',
        v_target_stream,
        jsonb_build_object(
          'type', 'challenge_live',
          'challenge_id', NEW.id::text,
          'status', 'live',
          'title', NEW.title,
          'audience', COALESCE(NEW.audience, 'both')
        ),
        false,
        NOW()
      );

    -- Live -> Closed / Archived
    ELSIF (OLD.status IS DISTINCT FROM NEW.status) AND (NEW.status IN ('closed', 'archived')) THEN
      v_notif_title := '🏆 Challenge Results Are In!';
      v_notif_body := NEW.title || ' (' || v_subj_name || ') has closed. Check the final leaderboard standings and practice offline!';

      INSERT INTO public.notifications (
        user_id,
        title,
        body,
        type,
        target_stream,
        payload,
        is_read,
        created_at
      ) VALUES (
        NULL,
        v_notif_title,
        v_notif_body,
        'challenge',
        v_target_stream,
        jsonb_build_object(
          'type', 'challenge_closed',
          'challenge_id', NEW.id::text,
          'status', 'closed',
          'title', NEW.title,
          'audience', COALESCE(NEW.audience, 'both')
        ),
        false,
        NOW()
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_challenge_auto_notify ON public.leaderboard_challenges;

CREATE TRIGGER trg_challenge_auto_notify
AFTER INSERT OR UPDATE OF status, starts_at, audience, title ON public.leaderboard_challenges
FOR EACH ROW
EXECUTE FUNCTION public.trg_fn_on_challenge_notify();
