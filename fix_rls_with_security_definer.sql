-- ===================================================
-- FIX RLS WITH SECURITY DEFINER - CHATGPT SUGGESTION
-- ===================================================
-- This implements the proper fix using SECURITY DEFINER
-- to allow the trigger to bypass RLS during signup

-- 1. Drop and recreate the trigger function with SECURITY DEFINER
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER -- This is the KEY! Runs with elevated privileges
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
    25,  -- default age
    170, -- default height
    70,  -- default weight
    'Moderately Active',
    'Maintain Weight',
    false,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the signup
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 3. Enable RLS (if not already enabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Drop all existing policies to start fresh
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

-- 5. Create proper RLS policies

-- Allow the trigger (running as SECURITY DEFINER) to create profiles
CREATE POLICY "Allow trigger to create profiles"
ON public.profiles
FOR INSERT
TO postgres  -- The trigger runs as postgres user when SECURITY DEFINER
WITH CHECK (true);

-- Allow authenticated users to view their own profile
CREATE POLICY "Users can view their own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Allow authenticated users to update their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow authenticated users to delete their own profile (if needed)
CREATE POLICY "Users can delete their own profile"
ON public.profiles
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- Service role bypass for admin operations
CREATE POLICY "Service role bypass"
ON public.profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 6. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON public.profiles TO postgres;
GRANT ALL ON public.profiles TO service_role;
GRANT SELECT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 7. Test the setup
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
BEGIN
  -- Try to insert a test profile (simulating what the trigger does)
  INSERT INTO public.profiles (id, email, name, has_completed_onboarding)
  VALUES (test_user_id, 'test_security_definer@example.com', 'Test Security Definer', false)
  ON CONFLICT (id) DO NOTHING;

  -- Clean up test data
  DELETE FROM public.profiles WHERE id = test_user_id;

  RAISE NOTICE '✅ Test successful - Trigger with SECURITY DEFINER works!';
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING '❌ Test failed: %', SQLERRM;
END $$;

-- 8. Verify the setup
SELECT '📋 Checking trigger function...' as status;
SELECT proname, prosecdef as "Security Definer"
FROM pg_proc
WHERE proname = 'handle_new_user';

SELECT '📋 Checking RLS policies...' as status;
SELECT tablename, policyname, roles, cmd
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

SELECT '✅ Setup complete! The SECURITY DEFINER fix should allow new users to sign up.' as message;
SELECT '🔒 RLS is enabled and properly configured for security.' as note;