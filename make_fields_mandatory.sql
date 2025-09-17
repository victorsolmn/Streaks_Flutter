-- ===================================================
-- MAKE ALL PROFILE FIELDS MANDATORY (NOT NULL)
-- ===================================================
-- Run this in your Supabase SQL Editor
-- This script makes all profile fields mandatory to prevent null values

-- IMPORTANT: First, we need to update any existing NULL values
-- Otherwise, the ALTER TABLE commands will fail

-- 1. Update any existing NULL values with defaults
UPDATE public.profiles
SET
  name = COALESCE(name, 'User'),
  age = COALESCE(age, 25),
  height = COALESCE(height, 170),
  weight = COALESCE(weight, 70),
  activity_level = COALESCE(activity_level, 'Moderately Active'),
  fitness_goal = COALESCE(fitness_goal, 'Maintain Weight'),
  has_completed_onboarding = COALESCE(has_completed_onboarding, false),
  updated_at = NOW()
WHERE
  name IS NULL
  OR age IS NULL
  OR height IS NULL
  OR weight IS NULL
  OR activity_level IS NULL
  OR fitness_goal IS NULL
  OR has_completed_onboarding IS NULL;

-- 2. Now alter the table to make fields NOT NULL
ALTER TABLE public.profiles
ALTER COLUMN name SET NOT NULL,
ALTER COLUMN age SET NOT NULL,
ALTER COLUMN height SET NOT NULL,
ALTER COLUMN weight SET NOT NULL,
ALTER COLUMN activity_level SET NOT NULL,
ALTER COLUMN fitness_goal SET NOT NULL,
ALTER COLUMN has_completed_onboarding SET NOT NULL;

-- 3. Add DEFAULT values for new profiles (for the trigger)
ALTER TABLE public.profiles
ALTER COLUMN name SET DEFAULT 'New User',
ALTER COLUMN age SET DEFAULT 25,
ALTER COLUMN height SET DEFAULT 170,
ALTER COLUMN weight SET DEFAULT 70,
ALTER COLUMN activity_level SET DEFAULT 'Moderately Active',
ALTER COLUMN fitness_goal SET DEFAULT 'Maintain Weight',
ALTER COLUMN has_completed_onboarding SET DEFAULT false;

-- 4. Update the trigger function to ensure all fields are populated
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    name,
    age,
    height,
    weight,
    activity_level,
    fitness_goal,
    has_completed_onboarding,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
    25,  -- default age
    170, -- default height in cm
    70,  -- default weight in kg
    'Moderately Active',
    'Maintain Weight',
    false,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Verify the constraints
SELECT
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN ('name', 'age', 'height', 'weight', 'activity_level', 'fitness_goal', 'has_completed_onboarding')
ORDER BY ordinal_position;

-- 6. Check current profile data
SELECT
  id,
  email,
  name,
  age,
  height,
  weight,
  activity_level,
  fitness_goal,
  has_completed_onboarding
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;