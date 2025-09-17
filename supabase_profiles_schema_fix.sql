-- ===================================================
-- SUPABASE PROFILES TABLE - COMPLETE SCHEMA FIX
-- ===================================================
-- Run this in your Supabase SQL Editor to add all missing columns

-- First, let's see what columns currently exist
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'profiles' ORDER BY ordinal_position;

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

-- Add constraints for data validation
ALTER TABLE public.profiles
ADD CONSTRAINT IF NOT EXISTS profiles_age_check CHECK (age >= 13 AND age <= 120),
ADD CONSTRAINT IF NOT EXISTS profiles_height_check CHECK (height >= 50 AND height <= 300), -- 50cm to 3m
ADD CONSTRAINT IF NOT EXISTS profiles_weight_check CHECK (weight >= 20 AND weight <= 500), -- 20kg to 500kg
ADD CONSTRAINT IF NOT EXISTS profiles_target_weight_check CHECK (target_weight >= 20 AND target_weight <= 500),
ADD CONSTRAINT IF NOT EXISTS profiles_daily_calories_check CHECK (daily_calories_target >= 800 AND daily_calories_target <= 5000),
ADD CONSTRAINT IF NOT EXISTS profiles_daily_steps_check CHECK (daily_steps_target >= 1000 AND daily_steps_target <= 50000),
ADD CONSTRAINT IF NOT EXISTS profiles_daily_sleep_check CHECK (daily_sleep_target >= 3.0 AND daily_sleep_target <= 12.0),
ADD CONSTRAINT IF NOT EXISTS profiles_daily_water_check CHECK (daily_water_target >= 0.5 AND daily_water_target <= 10.0);

-- Add valid values constraints
ALTER TABLE public.profiles
ADD CONSTRAINT IF NOT EXISTS profiles_activity_level_check
CHECK (activity_level IN ('Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active')),

ADD CONSTRAINT IF NOT EXISTS profiles_fitness_goal_check
CHECK (fitness_goal IN ('Lose Weight', 'Maintain Weight', 'Gain Muscle', 'Improve Fitness', 'Build Strength')),

ADD CONSTRAINT IF NOT EXISTS profiles_experience_level_check
CHECK (experience_level IN ('Beginner', 'Intermediate', 'Advanced')),

ADD CONSTRAINT IF NOT EXISTS profiles_workout_consistency_check
CHECK (workout_consistency IN ('Never', 'Rarely', 'Sometimes', 'Often', 'Always')),

ADD CONSTRAINT IF NOT EXISTS profiles_gender_check
CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),

ADD CONSTRAINT IF NOT EXISTS profiles_preferred_units_check
CHECK (preferred_units IN ('metric', 'imperial'));

-- Create updated_at trigger
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

-- Create RLS policy to allow users to access only their own profile
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
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Check constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'profiles';

-- 3. Check RLS policies
SELECT policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'profiles';

-- ===================================================
-- SAMPLE DATA INSERT TEST
-- ===================================================
-- After running the schema, test with sample data:
/*
INSERT INTO public.profiles (
    id, name, email, age, height, weight, target_weight,
    activity_level, fitness_goal, experience_level, workout_consistency,
    has_completed_onboarding, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, gender, preferred_units
) VALUES (
    'your-user-id-here',
    'Test User',
    'test@example.com',
    30,
    175.5,
    70.0,
    65.0,
    'Moderately Active',
    'Lose Weight',
    'Intermediate',
    'Often',
    true,
    2000,
    10000,
    8.0,
    2.5,
    'Male',
    'metric'
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    age = EXCLUDED.age,
    height = EXCLUDED.height,
    weight = EXCLUDED.weight,
    target_weight = EXCLUDED.target_weight,
    activity_level = EXCLUDED.activity_level,
    fitness_goal = EXCLUDED.fitness_goal,
    experience_level = EXCLUDED.experience_level,
    workout_consistency = EXCLUDED.workout_consistency,
    has_completed_onboarding = EXCLUDED.has_completed_onboarding,
    daily_calories_target = EXCLUDED.daily_calories_target,
    daily_steps_target = EXCLUDED.daily_steps_target,
    daily_sleep_target = EXCLUDED.daily_sleep_target,
    daily_water_target = EXCLUDED.daily_water_target,
    gender = EXCLUDED.gender,
    preferred_units = EXCLUDED.preferred_units;
*/