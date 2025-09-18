-- COMPLETE FIX FOR ONBOARDING ISSUES
-- Run this entire script in Supabase SQL Editor

-- ========================================
-- STEP 1: REMOVE DEFAULT VALUES
-- ========================================
-- These fields should be NULL until user provides them during onboarding
ALTER TABLE profiles
  ALTER COLUMN age DROP DEFAULT,
  ALTER COLUMN height DROP DEFAULT,
  ALTER COLUMN weight DROP DEFAULT;

-- ========================================
-- STEP 2: FIX ROW LEVEL SECURITY POLICIES
-- ========================================
-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON public.profiles;

-- Create proper policies that allow users to manage their own profiles
CREATE POLICY "Users can view own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile"
ON public.profiles FOR DELETE
USING (auth.uid() = id);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;

-- ========================================
-- STEP 3: CHECK/FIX TRIGGER (if exists)
-- ========================================
-- Check if there's a trigger setting default values
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'profiles';

-- If there's a trigger setting defaults, you'll need to modify it
-- Example of what the trigger should look like (only creates basic profile):
/*
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    now(),
    now()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/

-- ========================================
-- STEP 4: FIX EXISTING BAD DATA (Optional)
-- ========================================
-- Fix records that have the fake default values
-- Only run this if you want to reset test accounts
UPDATE profiles
SET
  age = NULL,
  height = NULL,
  weight = NULL
WHERE
  has_completed_onboarding = false
  AND age = 25
  AND height = 170
  AND weight = 70;

-- ========================================
-- STEP 5: VERIFY THE FIXES
-- ========================================
-- Check that policies are correct
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- Check that defaults are removed
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('age', 'height', 'weight', 'has_completed_onboarding')
ORDER BY column_name;

-- ========================================
-- EXPECTED RESULTS AFTER RUNNING THIS:
-- ========================================
-- 1. age, height, weight columns should have NO defaults (column_default = NULL)
-- 2. RLS policies should allow users to SELECT, INSERT, UPDATE, DELETE their own profiles
-- 3. New signups will have NULL for age, height, weight until onboarding
-- 4. Onboarding will be able to update these fields with user's real data