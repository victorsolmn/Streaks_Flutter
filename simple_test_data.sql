-- =====================================================
-- SIMPLE TEST DATA - COPY & PASTE INTO SUPABASE SQL EDITOR
-- =====================================================

-- Test with just ONE user first (Elite Athlete)
-- User ID: ed858fbf-ca85-44fa-8dae-eb2fd99e09b8

-- 1. Insert a simple nutrition entry
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'breakfast', 'Test Meal', 400, 30, 50, 10, 5, NOW())
ON CONFLICT DO NOTHING;

-- 2. Insert/Update streak
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily', 10, 10, CURRENT_DATE, true, NOW(), NOW())
ON CONFLICT (user_id, streak_type)
DO UPDATE SET
    current_streak = 10,
    longest_streak = 10,
    last_activity_date = CURRENT_DATE,
    updated_at = NOW();

-- 3. Verify it worked
SELECT 'Success! Data inserted for Elite Athlete' as message;