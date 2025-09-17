-- ===================================================
-- SUPABASE PROFILES TABLE - COMPLETE SCHEMA FIX (CORRECTED)
-- ===================================================
-- Run this in your Supabase SQL Editor to add all missing columns

-- Add all missing columns to profiles table
ALTER TABLE public.profiles

-- Basic Profile Information
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS height DECIMAL(5,2), -- in cm, allows 999.99
ADD COLUMN IF NOT EXISTS weight DECIMAL(5,2), -- in kg, allows 999.99
ADD COLUMN IF NOT EXISTS target_weight DECIMAL(5,2),

-- Activity & Fitness
ADD COLUMN IF NOT EXISTS activity_level TEXT,
ADD COLUMN IF NOT EXISTS fitness_goal TEXT,
ADD COLUMN IF NOT EXISTS experience_level TEXT,
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,

-- Onboarding & Settings
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_seen_fitness_goal_summary BOOLEAN DEFAULT FALSE,

-- Daily Targets
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER DEFAULT 10000,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL(3,1), -- hours, like 8.5
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL(4,1), -- liters, like 2.5

-- Additional Profile Fields
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'UTC',

-- Preferences
ADD COLUMN IF NOT EXISTS preferred_units TEXT DEFAULT 'metric', -- metric/imperial
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}'::jsonb,

-- Timestamps
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP WITH TIME ZONE;

-- Add constraints for data validation (using DO block to handle IF NOT EXISTS)
DO $$
BEGIN
    -- Age constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_age_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_age_check CHECK (age >= 13 AND age <= 120);
    END IF;

    -- Height constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_height_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_height_check CHECK (height >= 50 AND height <= 300);
    END IF;

    -- Weight constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_weight_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_weight_check CHECK (weight >= 20 AND weight <= 500);
    END IF;

    -- Target weight constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_target_weight_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_target_weight_check CHECK (target_weight >= 20 AND target_weight <= 500);
    END IF;

    -- Daily calories constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_daily_calories_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_daily_calories_check CHECK (daily_calories_target >= 800 AND daily_calories_target <= 5000);
    END IF;

    -- Daily steps constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_daily_steps_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_daily_steps_check CHECK (daily_steps_target >= 1000 AND daily_steps_target <= 50000);
    END IF;

    -- Daily sleep constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_daily_sleep_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_daily_sleep_check CHECK (daily_sleep_target >= 3.0 AND daily_sleep_target <= 12.0);
    END IF;

    -- Daily water constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_daily_water_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_daily_water_check CHECK (daily_water_target >= 0.5 AND daily_water_target <= 10.0);
    END IF;

    -- Activity level constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_activity_level_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_activity_level_check
        CHECK (activity_level IN ('Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'));
    END IF;

    -- Fitness goal constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_fitness_goal_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_fitness_goal_check
        CHECK (fitness_goal IN ('Lose Weight', 'Maintain Weight', 'Gain Muscle', 'Improve Fitness', 'Build Strength'));
    END IF;

    -- Experience level constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_experience_level_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_experience_level_check
        CHECK (experience_level IN ('Beginner', 'Intermediate', 'Advanced'));
    END IF;

    -- Workout consistency constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_workout_consistency_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_workout_consistency_check
        CHECK (workout_consistency IN ('Never', 'Rarely', 'Sometimes', 'Often', 'Always'));
    END IF;

    -- Gender constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_gender_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_gender_check
        CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say'));
    END IF;

    -- Preferred units constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_preferred_units_check') THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_preferred_units_check
        CHECK (preferred_units IN ('metric', 'imperial'));
    END IF;
END $$;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding ON public.profiles(has_completed_onboarding);
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON public.profiles(updated_at);

-- Enable Row Level Security (if not already enabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (drop first to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Grant necessary permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;

-- ===================================================
-- VERIFICATION QUERIES
-- ===================================================
-- Run these to verify the schema is complete:

-- 1. Check all columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'profiles' AND table_schema = 'public';

-- 3. Check RLS policies
SELECT policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'profiles' AND schemaname = 'public';