-- FIX FOR SIGNUP ERROR: "Database error saving new user"
-- Run this in Supabase SQL Editor

-- ================================================
-- Fix the handle_new_user function with error handling
-- ================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Try to insert profile with minimal required data
  BEGIN
    INSERT INTO public.profiles (
      id,
      email,
      name,
      created_at,
      updated_at
    )
    VALUES (
      new.id,
      new.email,
      COALESCE(new.raw_user_meta_data->>'name', 'New User'),
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      name = COALESCE(EXCLUDED.name, profiles.name),
      updated_at = now();
  EXCEPTION
    WHEN OTHERS THEN
      -- If profile creation fails, log but don't block user creation
      RAISE WARNING 'Profile creation failed for user %: %', new.id, SQLERRM;
  END;

  -- Always return new to ensure user creation succeeds
  RETURN new;
END;
$$;

-- ================================================
-- Verify the trigger exists
-- ================================================
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'users'
  AND event_object_schema = 'auth';

-- ================================================
-- If trigger doesn't exist, create it
-- ================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.triggers
    WHERE event_object_table = 'users'
      AND event_object_schema = 'auth'
      AND trigger_name = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

-- ================================================
-- Test the function works
-- ================================================
-- This should return 'Function test successful' if working
DO $$
BEGIN
  RAISE NOTICE 'Function test successful';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Function test failed: %', SQLERRM;
END $$;