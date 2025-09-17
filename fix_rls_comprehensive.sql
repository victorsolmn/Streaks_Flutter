-- ===================================================
-- COMPREHENSIVE FIX FOR RLS POLICIES
-- ===================================================
-- Run this in your Supabase SQL Editor

-- 1. First, disable RLS temporarily to fix existing data
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. Update victorvegeta007@gmail.com profile if it exists
UPDATE public.profiles
SET has_completed_onboarding = true,
    updated_at = NOW()
WHERE email = 'victorvegeta007@gmail.com';

-- 3. Drop ALL existing policies on profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable all operations for users on their own profile" ON public.profiles;

-- 4. Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 5. Create a single, comprehensive policy that allows ALL operations
CREATE POLICY "Enable all operations for users on own profile"
ON public.profiles
FOR ALL
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 6. Also create a service role bypass policy
CREATE POLICY "Service role bypass"
ON public.profiles
FOR ALL
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- 7. Verify the policies
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles';

-- 8. Check the profile data
SELECT id, email, name, has_completed_onboarding, created_at, updated_at
FROM public.profiles
WHERE email IN ('victorvegeta007@gmail.com', 'sample1@gmail.com');

-- 9. Test that the trigger still works for new users
-- (This is just for verification, not actually creating a user)
/*
INSERT INTO auth.users (id, email)
VALUES (gen_random_uuid(), 'test@example.com')
ON CONFLICT DO NOTHING;
*/