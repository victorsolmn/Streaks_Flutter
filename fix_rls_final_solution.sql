-- ===================================================
-- ULTIMATE FIX FOR RLS POLICIES - COMPLETE SOLUTION
-- ===================================================
-- Run this ENTIRE script in your Supabase SQL Editor
-- This will completely fix the RLS policy issue

-- 1. First, check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'profiles';

-- 2. Temporarily disable RLS to clean up
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 3. Drop ALL existing policies (clean slate)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.policyname);
    END LOOP;
END $$;

-- 4. Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 5. Create a single comprehensive policy using auth.uid()
CREATE POLICY "Users can fully manage their own profile"
ON public.profiles
AS PERMISSIVE
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 6. Create a policy for the service role (admin access)
CREATE POLICY "Service role has full access"
ON public.profiles
AS PERMISSIVE
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 7. Create a policy for anon role during signup
CREATE POLICY "Allow profile creation during signup"
ON public.profiles
AS PERMISSIVE
FOR INSERT
TO anon
WITH CHECK (true);

-- 8. Grant proper permissions
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT INSERT ON public.profiles TO anon;

-- 9. Update the trigger function to handle profile creation properly
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = NEW.id) THEN
    -- Update existing profile with metadata
    UPDATE public.profiles
    SET
      email = COALESCE(NEW.email, email),
      name = COALESCE(NEW.raw_user_meta_data->>'name', name),
      updated_at = NOW()
    WHERE id = NEW.id;
  ELSE
    -- Create new profile
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
    )
    ON CONFLICT (id) DO UPDATE
    SET
      email = EXCLUDED.email,
      name = COALESCE(EXCLUDED.name, public.profiles.name),
      updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 11. Test the policies are working
SELECT
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

-- 12. Manually update the problematic profiles to ensure they have correct data
UPDATE public.profiles
SET
  has_completed_onboarding = true,
  updated_at = NOW()
WHERE email IN ('victorvegeta007@gmail.com', 'sample1@gmail.com');

-- 13. Verify the data
SELECT
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
FROM public.profiles
WHERE email IN ('victorvegeta007@gmail.com', 'sample1@gmail.com')
ORDER BY created_at DESC;

-- 14. Test with a sample UPDATE to ensure RLS works
-- This should work if you're logged in as the user
/*
UPDATE public.profiles
SET
  name = 'Test Update',
  updated_at = NOW()
WHERE id = auth.uid();
*/

-- 15. Check if there are any users without profiles
SELECT
  u.id AS user_id,
  u.email AS user_email,
  p.id AS profile_id
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;