-- ============================================
-- STREAKS FLUTTER DATABASE SCHEMA FIXES
-- Generated: 2025-09-16
-- Based on Integration Test Results
-- ============================================

-- BACKUP REMINDER: Always backup your database before running migrations!
-- Run: pg_dump your_database > backup_$(date +%Y%m%d_%H%M%S).sql

-- ============================================
-- MIGRATION 1: Add missing daily_calories_target column
-- ============================================

-- Error identified: Could not find the 'daily_calories_target' column of 'profiles' in the schema cache
-- Solution: Add the missing column that the app expects

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000;

COMMENT ON COLUMN profiles.daily_calories_target IS 'Daily calorie target for user nutrition goals';

-- ============================================
-- MIGRATION 2: Fix heart rate constraints
-- ============================================

-- Error identified: new row for relation "health_metrics" violates check constraint "health_metrics_heart_rate_check"
-- Current constraint is too restrictive (40-200 BPM)
-- Solution: Expand range to allow 30-250 BPM or NULL

ALTER TABLE health_metrics
DROP CONSTRAINT IF EXISTS health_metrics_heart_rate_check;

ALTER TABLE health_metrics
ADD CONSTRAINT health_metrics_heart_rate_check
CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250));

COMMENT ON CONSTRAINT health_metrics_heart_rate_check ON health_metrics IS 'Heart rate must be between 30-250 BPM or NULL';

-- ============================================
-- MIGRATION 3: Fix table name references
-- ============================================

-- Error identified: Could not find the table 'public.user_streaks' in the schema cache
-- The app expects 'user_streaks' but database has 'streaks'
-- Solution: Create an alias view for backward compatibility (preferred over renaming)

CREATE OR REPLACE VIEW user_streaks AS
SELECT * FROM streaks;

COMMENT ON VIEW user_streaks IS 'Compatibility view for app expecting user_streaks table name';

-- Grant proper permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_streaks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_streaks TO anon;

-- ============================================
-- MIGRATION 4: Fix constraint issues in streaks table
-- ============================================

-- Error identified: there is no unique or exclusion constraint matching the ON CONFLICT specification
-- Solution: Add proper unique constraint for upsert operations

ALTER TABLE streaks
ADD CONSTRAINT IF NOT EXISTS streaks_user_type_unique
UNIQUE (user_id, streak_type);

COMMENT ON CONSTRAINT streaks_user_type_unique ON streaks IS 'Ensures one streak record per user per streak type for upsert operations';

-- ============================================
-- MIGRATION 5: Fix nutrition data type issues
-- ============================================

-- Error identified: type 'String' is not a subtype of type 'List<dynamic>' in type cast
-- This is likely due to JSON field handling in nutrition_entries
-- Solution: Ensure consistent data types and add helper functions

-- Check current data types in nutrition_entries
-- If any TEXT columns should be JSON/JSONB, convert them

-- Example: If food_ingredients is stored as TEXT but app expects JSON array
-- ALTER TABLE nutrition_entries
-- ALTER COLUMN food_ingredients TYPE JSONB USING food_ingredients::JSONB;

-- For now, we'll add a comment for manual inspection
COMMENT ON TABLE nutrition_entries IS 'Check data types - ensure JSON fields are properly typed as JSONB, not TEXT';

-- ============================================
-- MIGRATION 6: Add missing indexes for performance
-- ============================================

-- Performance optimization: Add indexes for common query patterns

CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON nutrition_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_meal_type ON nutrition_entries(user_id, meal_type);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON health_metrics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON streaks(user_id, streak_type);
CREATE INDEX IF NOT EXISTS idx_user_goals_user_active ON user_goals(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_goals_goal_type ON user_goals(user_id, goal_type);

-- ============================================
-- MIGRATION 7: Create missing views/tables
-- ============================================

-- Create daily_nutrition_summary view that the app expects
CREATE OR REPLACE VIEW daily_nutrition_summary AS
SELECT
    user_id,
    date,
    SUM(calories) as total_calories,
    SUM(protein) as total_protein,
    SUM(carbs) as total_carbs,
    SUM(fat) as total_fat,
    SUM(fiber) as total_fiber,
    COUNT(*) as entries_count,
    CURRENT_TIMESTAMP as calculated_at
FROM nutrition_entries
GROUP BY user_id, date;

COMMENT ON VIEW daily_nutrition_summary IS 'Aggregated daily nutrition data for dashboard display';

-- Grant permissions
GRANT SELECT ON daily_nutrition_summary TO authenticated;
GRANT SELECT ON daily_nutrition_summary TO anon;

-- Create user_dashboard view that the app expects
CREATE OR REPLACE VIEW user_dashboard AS
SELECT
    p.id,
    p.name,
    p.email,
    p.age,
    p.height,
    p.weight,
    p.activity_level,
    p.fitness_goal,
    p.daily_calories_target,
    s.current_streak,
    s.longest_streak,
    s.last_activity_date,
    hm.steps as today_steps,
    hm.calories_burned as today_calories_burned,
    hm.heart_rate as today_heart_rate,
    hm.sleep_hours as today_sleep_hours,
    hm.water_intake as today_water_intake,
    dn.total_calories as today_calories_consumed,
    dn.total_protein as today_protein,
    dn.total_carbs as today_carbs,
    dn.total_fat as today_fat,
    p.created_at as profile_created_at
FROM profiles p
LEFT JOIN streaks s ON p.id = s.user_id AND s.streak_type = 'daily'
LEFT JOIN health_metrics hm ON p.id = hm.user_id AND hm.date = CURRENT_DATE
LEFT JOIN daily_nutrition_summary dn ON p.id = dn.user_id AND dn.date = CURRENT_DATE;

COMMENT ON VIEW user_dashboard IS 'Comprehensive user dashboard with all key metrics';

-- Grant permissions
GRANT SELECT ON user_dashboard TO authenticated;
GRANT SELECT ON user_dashboard TO anon;

-- ============================================
-- MIGRATION 8: Fix RLS policies if needed
-- ============================================

-- Ensure Row Level Security policies exist for all tables
-- This prevents access issues when accessing data

-- Enable RLS on all tables (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies (if they don't exist)
-- Users can only access their own data

DO $$
BEGIN
    -- Profiles policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view own profile') THEN
        CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update own profile') THEN
        CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
    END IF;

    -- Nutrition entries policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'nutrition_entries' AND policyname = 'Users can manage own nutrition entries') THEN
        CREATE POLICY "Users can manage own nutrition entries" ON nutrition_entries FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Health metrics policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'health_metrics' AND policyname = 'Users can manage own health metrics') THEN
        CREATE POLICY "Users can manage own health metrics" ON health_metrics FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- Streaks policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'streaks' AND policyname = 'Users can manage own streaks') THEN
        CREATE POLICY "Users can manage own streaks" ON streaks FOR ALL USING (auth.uid() = user_id);
    END IF;

    -- User goals policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_goals' AND policyname = 'Users can manage own goals') THEN
        CREATE POLICY "Users can manage own goals" ON user_goals FOR ALL USING (auth.uid() = user_id);
    END IF;
END
$$;

-- ============================================
-- MIGRATION 9: Data validation and cleanup
-- ============================================

-- Update any existing NULL values in daily_calories_target
UPDATE profiles
SET daily_calories_target = 2000
WHERE daily_calories_target IS NULL;

-- Clean up any invalid heart rate values
UPDATE health_metrics
SET heart_rate = NULL
WHERE heart_rate IS NOT NULL AND (heart_rate < 30 OR heart_rate > 250);

-- ============================================
-- MIGRATION 10: Verify schema after changes
-- ============================================

-- Create a verification function to check schema health
CREATE OR REPLACE FUNCTION verify_schema_health()
RETURNS TABLE(
    table_name text,
    column_name text,
    status text,
    message text
) AS $$
BEGIN
    -- Check for daily_calories_target column
    RETURN QUERY
    SELECT
        'profiles'::text,
        'daily_calories_target'::text,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'profiles'
            AND column_name = 'daily_calories_target'
        ) THEN 'OK'::text ELSE 'MISSING'::text END,
        'Required for profile management'::text;

    -- Check for user_streaks view
    RETURN QUERY
    SELECT
        'user_streaks'::text,
        'view'::text,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.views
            WHERE table_name = 'user_streaks'
        ) THEN 'OK'::text ELSE 'MISSING'::text END,
        'Required for streaks compatibility'::text;

    -- Check heart rate constraint
    RETURN QUERY
    SELECT
        'health_metrics'::text,
        'heart_rate_check'::text,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.check_constraints
            WHERE constraint_name = 'health_metrics_heart_rate_check'
        ) THEN 'OK'::text ELSE 'MISSING'::text END,
        'Required for heart rate validation'::text;

END
$$ LANGUAGE plpgsql;

-- Run the verification
-- SELECT * FROM verify_schema_health();

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- NEXT STEPS:
-- 1. Run these migrations on your database
-- 2. Test the app CRUD operations
-- 3. Run the 10 dummy account test
-- 4. Monitor for any remaining errors
-- 5. Update app code if needed for any remaining type casting issues

-- ROLLBACK INSTRUCTIONS (if needed):
-- 1. DROP VIEW IF EXISTS user_streaks;
-- 2. ALTER TABLE profiles DROP COLUMN IF EXISTS daily_calories_target;
-- 3. Restore original heart rate constraint
-- 4. Drop added indexes and views
-- 5. Restore from backup if major issues

COMMENT ON SCHEMA public IS 'Schema updated for Streaks Flutter app compatibility - Migration completed on 2025-09-16';