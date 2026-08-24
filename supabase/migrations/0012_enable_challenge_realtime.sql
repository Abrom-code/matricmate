-- =============================================================================
-- 0012_enable_challenge_realtime.sql
-- Enable Supabase Realtime broadcast for leaderboard_challenges & challenge_attempts
-- =============================================================================

-- 1. Enable Full Replica Identity so UPDATE/DELETE payloads include complete rows
ALTER TABLE IF EXISTS public.leaderboard_challenges REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.challenge_attempts REPLICA IDENTITY FULL;
ALTER TABLE IF EXISTS public.challenge_questions REPLICA IDENTITY FULL;

-- 2. Add tables to supabase_realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'leaderboard_challenges'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.leaderboard_challenges;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'challenge_attempts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.challenge_attempts;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'challenge_questions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.challenge_questions;
  END IF;
END $$;
