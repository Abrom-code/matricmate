-- Migration: 0014_create_telegram_banned_users.sql
-- Description: Stores Telegram chat IDs of banned users for the support bot

CREATE TABLE IF NOT EXISTS telegram_banned_users (
  chat_id TEXT PRIMARY KEY,
  reason TEXT,
  banned_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE telegram_banned_users ENABLE ROW LEVEL SECURITY;

-- Allow service_role full access (Edge Functions use SERVICE_ROLE_KEY)
CREATE POLICY "Service role can manage telegram_banned_users"
  ON telegram_banned_users
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
