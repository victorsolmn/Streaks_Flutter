-- ===================================================
-- FIX RLS POLICIES FOR PROFILES TABLE
-- ===================================================
-- Run this in your Supabase SQL Editor to fix the profile update issue

-- First, drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;

-- Create comprehensive policy that allows users to fully manage their own profile
CREATE POLICY "Enable all operations for users on their own profile"
ON public.profiles
FOR ALL
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Alternative: Create separate policies for each operation (if preferred)
-- CREATE POLICY "Users can view their own profile"
-- ON public.profiles
-- FOR SELECT
-- USING (auth.uid() = id);

-- CREATE POLICY "Users can insert their own profile"
-- ON public.profiles
-- FOR INSERT
-- WITH CHECK (auth.uid() = id);

-- CREATE POLICY "Users can update their own profile"
-- ON public.profiles
-- FOR UPDATE
-- USING (auth.uid() = id)
-- WITH CHECK (auth.uid() = id);

-- CREATE POLICY "Users can delete their own profile"
-- ON public.profiles
-- FOR DELETE
-- USING (auth.uid() = id);

-- Verify the policy is working
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles';