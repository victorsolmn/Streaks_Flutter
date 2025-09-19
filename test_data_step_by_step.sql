-- =====================================================
-- STEP-BY-STEP TEST DATA INSERTION
-- Run each section separately to identify errors
-- =====================================================

-- STEP 1: Clear existing test data (OPTIONAL - be careful!)
-- =====================================================
/*
DELETE FROM public.chat_sessions WHERE user_id IN (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
    'c600b93e-6aa4-48b8-95a1-0926b869f875',
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
    '722c1211-0810-413f-b37e-000065754496',
    '072d54c5-3258-495f-b684-da8631dfbf98',
    '135b8ab5-a78d-4c02-8c84-443d3bc75106'
);

DELETE FROM public.user_achievements WHERE user_id IN (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
    'c600b93e-6aa4-48b8-95a1-0926b869f875',
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
    '722c1211-0810-413f-b37e-000065754496',
    '072d54c5-3258-495f-b684-da8631dfbf98',
    '135b8ab5-a78d-4c02-8c84-443d3bc75106'
);

DELETE FROM public.user_goals WHERE user_id IN (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
    'c600b93e-6aa4-48b8-95a1-0926b869f875',
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
    '722c1211-0810-413f-b37e-000065754496',
    '072d54c5-3258-495f-b684-da8631dfbf98',
    '135b8ab5-a78d-4c02-8c84-443d3bc75106'
);

DELETE FROM public.streaks WHERE user_id IN (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
    'c600b93e-6aa4-48b8-95a1-0926b869f875',
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
    '722c1211-0810-413f-b37e-000065754496',
    '072d54c5-3258-495f-b684-da8631dfbf98',
    '135b8ab5-a78d-4c02-8c84-443d3bc75106'
);

DELETE FROM public.nutrition_entries WHERE user_id IN (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
    'c600b93e-6aa4-48b8-95a1-0926b869f875',
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
    '722c1211-0810-413f-b37e-000065754496',
    '072d54c5-3258-495f-b684-da8631dfbf98',
    '135b8ab5-a78d-4c02-8c84-443d3bc75106'
);
*/

-- STEP 2: Insert Nutrition Entries (Test this first)
-- =====================================================
-- Delete old nutrition entries first
DELETE FROM public.nutrition_entries
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8'
AND date >= CURRENT_DATE - INTERVAL '2 days';

-- Insert new nutrition entries for Elite Athlete
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'breakfast', 'Protein oatmeal', 420, 35, 55, 8, 12, NOW() - INTERVAL '6 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'lunch', 'Grilled chicken', 580, 48, 52, 16, 8, NOW() - INTERVAL '3 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'dinner', 'Salmon dinner', 640, 52, 42, 22, 6, NOW());

-- STEP 3: Insert Streaks (One at a time)
-- =====================================================
-- Elite Athlete streak
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily', 412, 412, CURRENT_DATE, true, NOW() - INTERVAL '450 days', NOW())
ON CONFLICT (user_id, streak_type)
DO UPDATE SET
    current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak,
    last_activity_date = EXCLUDED.last_activity_date,
    target_achieved = EXCLUDED.target_achieved,
    updated_at = NOW();

-- STEP 4: Insert User Goals (Test one user first)
-- =====================================================
-- Delete existing goals for this user
DELETE FROM public.user_goals WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8';

-- Insert new goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily_protein', 180, 182, 'grams', true, NOW() - INTERVAL '100 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'weekly_workouts', 7, 7, 'sessions', true, NOW() - INTERVAL '100 days', NOW());

-- STEP 5: Insert Achievements (Check if achievement_id exists first)
-- =====================================================
-- First, check what achievement IDs are available in your achievements table:
-- SELECT id FROM public.achievements;

-- Then insert user achievements (adjust achievement_id based on what exists)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'warm_up', NOW() - INTERVAL '410 days', true, NOW() - INTERVAL '410 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- STEP 6: Insert Chat Sessions (Simple version)
-- =====================================================
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 1, 'Test Session',
 'Test session for data verification',
 ARRAY['test'],
 'Test goal',
 'Test recommendation',
 'positive', 10, 10, NOW() - INTERVAL '1 hour', NOW() - INTERVAL '50 minutes',
 NOW(), NOW());

-- VERIFICATION: Check what was inserted
-- =====================================================
SELECT 'Nutrition Entries' as table_name, COUNT(*) as count
FROM public.nutrition_entries
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8'
UNION ALL
SELECT 'Streaks', COUNT(*)
FROM public.streaks
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8'
UNION ALL
SELECT 'User Goals', COUNT(*)
FROM public.user_goals
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8'
UNION ALL
SELECT 'Achievements', COUNT(*)
FROM public.user_achievements
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8'
UNION ALL
SELECT 'Chat Sessions', COUNT(*)
FROM public.chat_sessions
WHERE user_id = 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8';