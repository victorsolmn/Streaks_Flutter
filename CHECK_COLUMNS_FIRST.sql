-- ============================================
-- DIAGNOSTIC SCRIPT - RUN THIS FIRST
-- This will show what columns actually exist
-- ============================================

-- 1. Check what columns exist in profiles table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Check what columns exist in nutrition_entries table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'nutrition_entries'
ORDER BY ordinal_position;

-- 3. Check what columns exist in goals table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'goals'
ORDER BY ordinal_position;

-- 4. Check if user_goals table exists
SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('goals', 'user_goals');

-- 5. Check what columns exist in health_metrics table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'health_metrics'
ORDER BY ordinal_position;

-- 6. Check what columns exist in streaks table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'streaks'
ORDER BY ordinal_position;