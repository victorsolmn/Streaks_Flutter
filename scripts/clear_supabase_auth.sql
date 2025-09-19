-- ================================================
-- CLEAR SUPABASE AUTHENTICATION USERS
-- ================================================
-- Date: September 19, 2025
-- This script clears all authentication users from Supabase
-- WARNING: This will delete ALL user accounts and they won't be able to sign in

-- Clear all users from Supabase Auth
-- Note: This requires admin privileges and should be run in Supabase SQL Editor

DELETE FROM auth.users;

-- Optional: Also clear related auth tables
DELETE FROM auth.identities;
DELETE FROM auth.sessions;
DELETE FROM auth.refresh_tokens;

-- Reset sequences (optional)
-- ALTER SEQUENCE auth.refresh_tokens_id_seq RESTART WITH 1;