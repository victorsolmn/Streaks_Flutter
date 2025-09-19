-- Supabase Database Cleanup Script
-- Purpose: Clear all test data while preserving table structure
-- Date: September 19, 2025
-- WARNING: This will DELETE all data from your tables!

-- ================================================
-- STEP 1: Disable RLS temporarily for cleanup
-- ================================================
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.nutrition_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.health_data DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.streaks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.workouts DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.achievements DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_achievements DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.smartwatch_data DISABLE ROW LEVEL SECURITY;

-- ================================================
-- STEP 2: Clear all data from tables
-- ================================================

-- Clear user achievements first (has foreign key to achievements)
DELETE FROM public.user_achievements WHERE 1=1;

-- Clear chat messages
DELETE FROM public.chat_messages WHERE 1=1;

-- Clear health-related data
DELETE FROM public.health_data WHERE 1=1;
DELETE FROM public.nutrition_entries WHERE 1=1;
DELETE FROM public.smartwatch_data WHERE 1=1;

-- Clear streaks and goals
DELETE FROM public.streaks WHERE 1=1;
DELETE FROM public.user_goals WHERE 1=1;

-- Clear workouts
DELETE FROM public.workouts WHERE 1=1;

-- Clear user profiles (do this last as other tables reference it)
DELETE FROM public.user_profiles WHERE 1=1;

-- Do NOT delete achievements table as it contains predefined badge definitions
-- Only reset user progress
UPDATE public.achievements
SET
    current_value = 0,
    is_unlocked = false,
    unlocked_at = NULL,
    progress = 0
WHERE 1=1;

-- ================================================
-- STEP 3: Reset sequences/auto-increment counters
-- ================================================

-- Reset any sequences if they exist
-- Note: Adjust these based on your actual sequence names
SELECT setval(pg_get_serial_sequence('public.nutrition_entries', 'id'), 1, false)
WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'nutrition_entries_id_seq');

SELECT setval(pg_get_serial_sequence('public.health_data', 'id'), 1, false)
WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'health_data_id_seq');

SELECT setval(pg_get_serial_sequence('public.streaks', 'id'), 1, false)
WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'streaks_id_seq');

SELECT setval(pg_get_serial_sequence('public.workouts', 'id'), 1, false)
WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'workouts_id_seq');

SELECT setval(pg_get_serial_sequence('public.chat_messages', 'id'), 1, false)
WHERE EXISTS (SELECT 1 FROM pg_class WHERE relname = 'chat_messages_id_seq');

-- ================================================
-- STEP 4: Re-enable RLS
-- ================================================
ALTER TABLE IF EXISTS public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.health_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.smartwatch_data ENABLE ROW LEVEL SECURITY;

-- ================================================
-- STEP 5: Verify cleanup
-- ================================================

-- Check record counts after cleanup
SELECT
    'user_profiles' as table_name, COUNT(*) as record_count FROM public.user_profiles
UNION ALL
SELECT
    'nutrition_entries', COUNT(*) FROM public.nutrition_entries
UNION ALL
SELECT
    'health_data', COUNT(*) FROM public.health_data
UNION ALL
SELECT
    'streaks', COUNT(*) FROM public.streaks
UNION ALL
SELECT
    'user_goals', COUNT(*) FROM public.user_goals
UNION ALL
SELECT
    'workouts', COUNT(*) FROM public.workouts
UNION ALL
SELECT
    'user_achievements', COUNT(*) FROM public.user_achievements
UNION ALL
SELECT
    'chat_messages', COUNT(*) FROM public.chat_messages
UNION ALL
SELECT
    'smartwatch_data', COUNT(*) FROM public.smartwatch_data
ORDER BY table_name;

-- ================================================
-- SUCCESS MESSAGE
-- ================================================
-- If you see record_count = 0 for all tables above,
-- the cleanup was successful!