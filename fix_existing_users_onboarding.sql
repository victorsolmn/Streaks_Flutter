-- ===================================================
-- FIX EXISTING USERS ONBOARDING STATUS
-- ===================================================
-- Run this in your Supabase SQL Editor to fix existing users
-- who have profile data but hasCompletedOnboarding is false

-- Update existing users who have complete profile data to mark onboarding as completed
UPDATE public.profiles
SET has_completed_onboarding = true
WHERE has_completed_onboarding = false
  AND name IS NOT NULL
  AND email IS NOT NULL
  AND age IS NOT NULL
  AND height IS NOT NULL
  AND weight IS NOT NULL
  AND activity_level IS NOT NULL
  AND fitness_goal IS NOT NULL;

-- Verify the update
SELECT
    email,
    name,
    age,
    height,
    weight,
    activity_level,
    fitness_goal,
    has_completed_onboarding
FROM public.profiles
ORDER BY created_at DESC;

-- Count users by onboarding status
SELECT
    has_completed_onboarding,
    COUNT(*) as user_count
FROM public.profiles
GROUP BY has_completed_onboarding;