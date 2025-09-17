-- Manual fix for sample1@gmail.com profile
-- Run this in Supabase SQL Editor if the profile still shows has_completed_onboarding as false

-- First, let's check the current state
SELECT id, email, name, age, height, weight, activity_level, fitness_goal, has_completed_onboarding
FROM public.profiles
WHERE email = 'sample1@gmail.com';

-- Update the profile to mark onboarding as complete
UPDATE public.profiles
SET
  has_completed_onboarding = true,
  updated_at = NOW()
WHERE email = 'sample1@gmail.com';

-- Verify the update
SELECT id, email, name, age, height, weight, activity_level, fitness_goal, has_completed_onboarding
FROM public.profiles
WHERE email = 'sample1@gmail.com';