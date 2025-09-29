-- REMOVE HARDCODED DEFAULT VALUES FROM PROFILES TABLE

-- Step 1: Check current column defaults
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name IN ('age', 'height', 'weight', 'activity_level', 'fitness_goal')
ORDER BY column_name;

-- Step 2: Remove ALL defaults from these columns
ALTER TABLE public.profiles
  ALTER COLUMN age DROP DEFAULT,
  ALTER COLUMN height DROP DEFAULT,
  ALTER COLUMN weight DROP DEFAULT,
  ALTER COLUMN activity_level DROP DEFAULT,
  ALTER COLUMN fitness_goal DROP DEFAULT;

-- Step 3: Check and drop any triggers that might set defaults
DROP TRIGGER IF EXISTS set_profile_defaults_trigger ON public.profiles;
DROP FUNCTION IF EXISTS set_profile_defaults();

-- Step 4: Find and modify the handle_new_user function if it sets defaults
-- First, let's see the current function
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'handle_new_user';

-- Step 5: Replace the handle_new_user function to NOT set any defaults
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Only insert basic required fields, NO DEFAULTS
  INSERT INTO public.profiles (id, email, created_at, updated_at)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Verify no defaults remain
SELECT
    column_name,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_default IS NOT NULL;

-- Step 7: Update existing test records to NULL (optional - only if you want to clean test data)
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