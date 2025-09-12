-- SQL Script to Clean Up Test Users from Supabase
-- Run this in Supabase SQL Editor

-- 1. First, let's see what users exist
SELECT id, email, created_at 
FROM auth.users 
WHERE email LIKE '%test%' OR email LIKE '%example.com%'
ORDER BY created_at DESC;

-- 2. Delete test users (uncomment and run after reviewing above)
-- DELETE FROM auth.users 
-- WHERE email LIKE 'test%@example.com';

-- 3. Delete specific user (replace with actual email)
-- DELETE FROM auth.users 
-- WHERE email = 'victorsolmn@gmail.com';

-- 4. To delete ALL users (BE CAREFUL!)
-- DELETE FROM auth.users;

-- Note: Deleting from auth.users will cascade delete related data
-- in public.users, public.user_profiles, etc.