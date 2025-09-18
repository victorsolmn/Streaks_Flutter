-- RUN THIS SCRIPT IN SUPABASE SQL EDITOR
-- This will fix the hardcoded default values issue

-- ================================================
-- STEP 1: Check current defaults (for verification)
-- ================================================
SELECT
    column_name,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN ('age', 'height', 'weight', 'activity_level', 'fitness_goal');

-- ================================================
-- STEP 2: Remove ALL default values
-- ================================================
ALTER TABLE public.profiles
  ALTER COLUMN age DROP DEFAULT,
  ALTER COLUMN height DROP DEFAULT,
  ALTER COLUMN weight DROP DEFAULT,
  ALTER COLUMN activity_level DROP DEFAULT,
  ALTER COLUMN fitness_goal DROP DEFAULT;

-- ================================================
-- STEP 3: Fix the handle_new_user function
-- ================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only insert minimal required fields - NO DEFAULTS!
  INSERT INTO public.profiles (
    id,
    email,
    created_at,
    updated_at
  )
  VALUES (
    new.id,
    new.email,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = now();

  RETURN new;
END;
$$;

-- ================================================
-- STEP 4: Verify changes
-- ================================================
SELECT
    column_name,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_default IS NOT NULL;

-- ================================================
-- STEP 5: Clean up test data (OPTIONAL)
-- Only run this if you want to reset test user data
-- ================================================
-- UPDATE public.profiles
-- SET
--   age = NULL,
--   height = NULL,
--   weight = NULL,
--   activity_level = NULL,
--   fitness_goal = NULL
-- WHERE email LIKE '%yopmail.com%'
--   AND age = 25
--   AND height = '170.00'
--   AND weight = '70.00';

-- ================================================
-- SUCCESS MESSAGE
-- ================================================
-- After running this script:
-- 1. No more hardcoded defaults (25, 170, 70)
-- 2. User-entered values will be saved properly
-- 3. Onboarding data will persist correctly