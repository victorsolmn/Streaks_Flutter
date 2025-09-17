-- ===================================================
-- NEW SIMPLE USER PROFILES TABLE
-- ===================================================
-- Run this in your Supabase SQL Editor

-- Drop existing table if you want a fresh start (CAUTION: This will delete all data)
-- DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Create new clean user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  -- Primary key using Supabase Auth user ID
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Basic profile information
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  age INTEGER NOT NULL,
  height DECIMAL(5,2) NOT NULL, -- in cm, allows 999.99
  weight DECIMAL(5,2) NOT NULL, -- in kg, allows 999.99

  -- Activity and fitness information
  activity_level TEXT NOT NULL,
  fitness_goal TEXT NOT NULL,
  experience_level TEXT NOT NULL,

  -- Onboarding status
  has_completed_onboarding BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add constraints for data validation
ALTER TABLE public.user_profiles
  ADD CONSTRAINT user_profiles_age_check
    CHECK (age >= 13 AND age <= 120),
  ADD CONSTRAINT user_profiles_height_check
    CHECK (height >= 50 AND height <= 300),
  ADD CONSTRAINT user_profiles_weight_check
    CHECK (weight >= 20 AND weight <= 500),
  ADD CONSTRAINT user_profiles_activity_level_check
    CHECK (activity_level IN ('Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active')),
  ADD CONSTRAINT user_profiles_fitness_goal_check
    CHECK (fitness_goal IN ('Lose Weight', 'Maintain Weight', 'Gain Muscle', 'Improve Fitness', 'Build Strength')),
  ADD CONSTRAINT user_profiles_experience_level_check
    CHECK (experience_level IN ('Beginner', 'Intermediate', 'Advanced'));

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to user_profiles table
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can manage own profile" ON public.user_profiles;
CREATE POLICY "Users can manage own profile" ON public.user_profiles
    FOR ALL USING (auth.uid() = id);

-- Grant permissions
GRANT ALL ON public.user_profiles TO authenticated;
GRANT SELECT ON public.user_profiles TO anon;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding ON public.user_profiles(has_completed_onboarding);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON public.user_profiles(updated_at);

-- ===================================================
-- VERIFICATION QUERIES
-- ===================================================

-- Check the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'user_profiles' AND table_schema = 'public';

-- Check RLS policies
SELECT policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'user_profiles' AND schemaname = 'public';