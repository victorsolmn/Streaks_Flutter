-- =============================================
-- SUPABASE PROFILES TABLE MIGRATION SCRIPT
-- =============================================
-- This script fixes the schema mismatches between the app and database
-- Run this in Supabase SQL Editor: Dashboard > SQL Editor > New Query
-- =============================================

BEGIN;

-- =============================================
-- STEP 1: ADD MISSING COLUMNS
-- =============================================
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS target_weight NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_sleep_target NUMERIC(4,2),
ADD COLUMN IF NOT EXISTS daily_water_target NUMERIC(4,2),
ADD COLUMN IF NOT EXISTS has_seen_fitness_goal_summary BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS device_name TEXT,
ADD COLUMN IF NOT EXISTS device_connected BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS bmi_value NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS bmi_category_value TEXT;

-- =============================================
-- STEP 2: REMOVE UNUSED COLUMNS
-- =============================================
ALTER TABLE public.profiles
DROP COLUMN IF EXISTS phone CASCADE,
DROP COLUMN IF EXISTS date_of_birth CASCADE,
DROP COLUMN IF EXISTS gender CASCADE,
DROP COLUMN IF EXISTS preferred_workout_time CASCADE,
DROP COLUMN IF EXISTS workout_days_per_week CASCADE,
DROP COLUMN IF EXISTS profile_picture_url CASCADE,
DROP COLUMN IF EXISTS bio CASCADE;

-- =============================================
-- STEP 3: DROP OLD CONSTRAINTS
-- =============================================
ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_activity_level_check,
DROP CONSTRAINT IF EXISTS profiles_fitness_goal_check,
DROP CONSTRAINT IF EXISTS profiles_experience_level_check,
DROP CONSTRAINT IF EXISTS profiles_gender_check;

-- =============================================
-- STEP 4: ADD UPDATED CONSTRAINTS
-- =============================================
ALTER TABLE public.profiles
ADD CONSTRAINT profiles_activity_level_check CHECK (
  activity_level IS NULL OR activity_level IN (
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active'
  )
),
ADD CONSTRAINT profiles_fitness_goal_check CHECK (
  fitness_goal IS NULL OR fitness_goal IN (
    'Lose Weight',
    'Maintain Weight',
    'Gain Muscle',
    'Improve Fitness',
    'Build Strength'
  )
),
ADD CONSTRAINT profiles_experience_level_check CHECK (
  experience_level IS NULL OR experience_level IN (
    'Beginner',
    'Intermediate',
    'Advanced'
  )
),
ADD CONSTRAINT profiles_workout_consistency_check CHECK (
  workout_consistency IS NULL OR workout_consistency IN (
    'Daily',
    '5-6 times per week',
    '3-4 times per week',
    '1-2 times per week',
    'Rarely'
  )
),
ADD CONSTRAINT profiles_target_weight_check CHECK (
  target_weight IS NULL OR (target_weight >= 20 AND target_weight <= 500)
),
ADD CONSTRAINT profiles_daily_calories_check CHECK (
  daily_calories_target IS NULL OR (daily_calories_target >= 500 AND daily_calories_target <= 10000)
),
ADD CONSTRAINT profiles_daily_steps_check CHECK (
  daily_steps_target IS NULL OR (daily_steps_target >= 0 AND daily_steps_target <= 100000)
),
ADD CONSTRAINT profiles_daily_sleep_check CHECK (
  daily_sleep_target IS NULL OR (daily_sleep_target >= 0 AND daily_sleep_target <= 24)
),
ADD CONSTRAINT profiles_daily_water_check CHECK (
  daily_water_target IS NULL OR (daily_water_target >= 0 AND daily_water_target <= 20)
);

-- =============================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IF NOT EXISTS idx_profiles_device_connected ON public.profiles(device_connected);
CREATE INDEX IF NOT EXISTS idx_profiles_workout_consistency ON public.profiles(workout_consistency);

COMMIT;

-- =============================================
-- VERIFICATION QUERY
-- =============================================
-- After running the migration, this query will show all columns
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;