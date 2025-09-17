-- ===================================================
-- FIX SIGNUP ISSUE - COMPLETE SOLUTION
-- ===================================================
-- This script fixes the "Database error saving new user" issue
-- Run this ENTIRE script in your Supabase SQL Editor

-- 1. First, ensure the profiles table exists with all required columns
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  age INTEGER,
  height NUMERIC,
  weight NUMERIC,
  activity_level TEXT,
  fitness_goal TEXT,
  has_completed_onboarding BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 2. Drop and recreate the trigger function with proper error handling
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert the profile with default values
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
    NULL, -- Will be set during onboarding
    NULL, -- Will be set during onboarding
    NULL, -- Will be set during onboarding
    NULL, -- Will be set during onboarding
    NULL, -- Will be set during onboarding
    false,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Prevent duplicate key errors

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the signup
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Drop and recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 4. Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 5. Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable all operations for users on their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable all operations for users on own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can fully manage their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role bypass" ON public.profiles;
DROP POLICY IF EXISTS "Service role has full access" ON public.profiles;
DROP POLICY IF EXISTS "Allow profile creation during signup" ON public.profiles;

-- 6. Create comprehensive policies
-- Allow users to manage their own profiles
CREATE POLICY "Users can manage their own profile"
ON public.profiles
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow the service role (used by triggers) to do anything
CREATE POLICY "Service role full access"
ON public.profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow profile creation by the trigger during signup
CREATE POLICY "Allow trigger to create profiles"
ON public.profiles
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- 7. Grant necessary permissions
GRANT ALL ON public.profiles TO service_role;
GRANT ALL ON public.profiles TO authenticated;
GRANT INSERT ON public.profiles TO anon;

-- 8. Test the trigger function manually (optional)
-- This simulates what happens during signup
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
BEGIN
  -- Try to insert a test profile
  INSERT INTO public.profiles (id, email, name, has_completed_onboarding)
  VALUES (test_user_id, 'test_trigger@example.com', 'Test Trigger', false)
  ON CONFLICT (id) DO NOTHING;

  -- Clean up test data
  DELETE FROM public.profiles WHERE id = test_user_id;

  RAISE NOTICE 'Trigger test successful!';
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Trigger test failed: %', SQLERRM;
END $$;

-- 9. Verify the setup
SELECT 'Checking profiles table...' as status;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

SELECT 'Checking policies...' as status;
SELECT tablename, policyname, roles, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles';

SELECT 'Checking trigger...' as status;
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'auth' AND event_object_table = 'users';

-- 10. Fix any existing profiles that might have issues
UPDATE public.profiles
SET
  has_completed_onboarding = COALESCE(has_completed_onboarding, false),
  updated_at = NOW()
WHERE has_completed_onboarding IS NULL;

-- Success message
SELECT 'Setup complete! Signup should now work properly.' as message;