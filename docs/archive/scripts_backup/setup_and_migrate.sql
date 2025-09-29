-- Supabase Database Migration SQL Script
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor)

-- First, create the exec_sql function if it doesn't exist
CREATE OR REPLACE FUNCTION public.exec_sql(sql text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.exec_sql(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.exec_sql(text) TO anon;

-- Now run the actual migration
-- Add missing columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
ADD COLUMN IF NOT EXISTS experience_level TEXT,
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL,
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL;

-- Ensure has_completed_onboarding column exists and has correct type
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE;

-- Update existing users to have proper default values
UPDATE profiles
SET has_completed_onboarding = FALSE
WHERE has_completed_onboarding IS NULL;

-- Verify the migration by checking the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;