-- Migration to add Grace Period support to existing user_streaks table
-- Run this after deploying the main schema updates

-- Add new columns for grace period tracking
ALTER TABLE public.user_streaks 
ADD COLUMN IF NOT EXISTS consecutive_missed_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS grace_days_used INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS grace_days_available INTEGER DEFAULT 2,
ADD COLUMN IF NOT EXISTS last_grace_reset_date DATE,
ADD COLUMN IF NOT EXISTS last_attempted_date DATE;

-- Update existing records to have full grace available
UPDATE public.user_streaks 
SET 
  consecutive_missed_days = 0,
  grace_days_used = 0,
  grace_days_available = 2,
  last_grace_reset_date = last_completed_date,
  last_attempted_date = COALESCE(last_completed_date, CURRENT_DATE)
WHERE consecutive_missed_days IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.user_streaks.consecutive_missed_days IS 'Number of consecutive days missed (resets on successful day)';
COMMENT ON COLUMN public.user_streaks.grace_days_used IS 'Grace days currently being used (0-2)';
COMMENT ON COLUMN public.user_streaks.grace_days_available IS 'Maximum grace days available (typically 2, resets after successful day)';
COMMENT ON COLUMN public.user_streaks.last_grace_reset_date IS 'Date when grace period was last reset (after successful goal completion)';
COMMENT ON COLUMN public.user_streaks.last_attempted_date IS 'Last date user attempted goals (successful or failed)';