-- Clear all existing data from Supabase tables
-- Run this script in your Supabase SQL Editor

-- Disable foreign key checks temporarily
SET session_replication_role = 'replica';

-- Clear all data from tables (in order to handle foreign key dependencies)
DELETE FROM public.workouts;
DELETE FROM public.activities;
DELETE FROM public.weight_logs;
DELETE FROM public.health_metrics;
DELETE FROM public.nutrition_entries;
DELETE FROM public.profiles;

-- Clear auth.users if you want to remove all user accounts as well
-- WARNING: This will remove all user accounts and require re-registration
-- Uncomment the next line only if you want to remove all users
-- DELETE FROM auth.users;

-- Re-enable foreign key checks
SET session_replication_role = 'origin';

-- Reset sequences/auto-increment counters (optional)
-- This ensures new records start from 1
ALTER SEQUENCE IF EXISTS workouts_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS activities_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS weight_logs_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS health_metrics_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS nutrition_entries_id_seq RESTART WITH 1;

-- Verify data has been cleared
SELECT 
    'profiles' as table_name, 
    COUNT(*) as record_count 
FROM profiles
UNION ALL
SELECT 
    'nutrition_entries', 
    COUNT(*) 
FROM nutrition_entries
UNION ALL
SELECT 
    'health_metrics', 
    COUNT(*) 
FROM health_metrics
UNION ALL
SELECT 
    'weight_logs', 
    COUNT(*) 
FROM weight_logs
UNION ALL
SELECT 
    'activities', 
    COUNT(*) 
FROM activities
UNION ALL
SELECT 
    'workouts', 
    COUNT(*) 
FROM workouts;

-- Success message
SELECT 'All data has been cleared successfully!' as message;