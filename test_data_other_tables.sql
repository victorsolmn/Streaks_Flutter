-- =====================================================
-- TEST DATA FOR OTHER TABLES (EXCLUDING PROFILES & HEALTH_METRICS)
-- =====================================================
-- Created: September 19, 2025
-- Uses existing user IDs from profiles table
--
-- USER IDs FROM YOUR EXISTING PROFILES:
-- Elite Athlete: ed858fbf-ca85-44fa-8dae-eb2fd99e09b8
-- Busy Professional: c600b93e-6aa4-48b8-95a1-0926b869f875
-- Weekend Warrior: 755d2aa4-929e-443a-9ae1-7b6d9aa3af8a
-- New Beginner: 722c1211-0810-413f-b37e-000065754496
-- Comeback Hero: 072d54c5-3258-495f-b684-da8631dfbf98
-- Victor Vegeta: 135b8ab5-a78d-4c02-8c84-443d3bc75106
-- =====================================================

-- Clear existing data first (optional - uncomment if needed)
-- DELETE FROM public.nutrition_entries WHERE user_id IN (
--     'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8',
--     'c600b93e-6aa4-48b8-95a1-0926b869f875',
--     '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a',
--     '722c1211-0810-413f-b37e-000065754496',
--     '072d54c5-3258-495f-b684-da8631dfbf98',
--     '135b8ab5-a78d-4c02-8c84-443d3bc75106'
-- );

-- =====================================================
-- NUTRITION ENTRIES
-- =====================================================

-- Elite Athlete (ed858fbf-ca85-44fa-8dae-eb2fd99e09b8)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'breakfast', 'Protein oatmeal with berries', 420, 35, 55, 8, 12, NOW() - INTERVAL '6 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'pre_workout', 'Pre-workout shake', 180, 25, 20, 2, 0, NOW() - INTERVAL '4 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'lunch', 'Grilled chicken with quinoa', 580, 48, 52, 16, 8, NOW() - INTERVAL '3 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'post_workout', 'Recovery protein shake', 320, 45, 28, 4, 2, NOW() - INTERVAL '2 hours'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'snack', 'Greek yogurt with almonds', 220, 20, 15, 12, 3, NOW() - INTERVAL '1 hour'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 'dinner', 'Salmon with sweet potato', 640, 52, 42, 22, 6, NOW()),
-- Yesterday
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 'breakfast', 'Egg white omelet with spinach', 380, 32, 25, 15, 8, NOW() - INTERVAL '1 day'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 'lunch', 'Turkey and avocado wrap', 520, 38, 45, 18, 10, NOW() - INTERVAL '1 day'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 'snack', 'Protein bar', 280, 25, 30, 8, 5, NOW() - INTERVAL '1 day'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 'dinner', 'Lean beef with vegetables', 680, 55, 35, 25, 12, NOW() - INTERVAL '1 day');

-- Busy Professional (c600b93e-6aa4-48b8-95a1-0926b869f875)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'breakfast', 'Overnight oats with protein powder', 350, 25, 45, 8, 10, NOW() - INTERVAL '8 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'lunch', 'Meal prep chicken bowl', 480, 38, 42, 16, 8, NOW() - INTERVAL '5 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'snack', 'Apple with almond butter', 180, 6, 22, 8, 5, NOW() - INTERVAL '3 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'dinner', 'Takeout sushi (tracked)', 420, 28, 55, 12, 3, NOW() - INTERVAL '1 hour');

-- Weekend Warrior (755d2aa4-929e-443a-9ae1-7b6d9aa3af8a)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'breakfast', 'Weekend pancake stack', 680, 18, 95, 22, 6, NOW() - INTERVAL '6 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'lunch', 'BBQ burger with fries', 950, 45, 78, 48, 8, NOW() - INTERVAL '3 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'snack', 'Craft beer', 180, 2, 15, 0, 0, NOW() - INTERVAL '2 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'dinner', 'Pizza night', 820, 35, 85, 35, 4, NOW() - INTERVAL '1 hour');

-- New Beginner (722c1211-0810-413f-b37e-000065754496)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'breakfast', 'Cereal with milk', 280, 8, 45, 6, 3, NOW() - INTERVAL '8 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'lunch', 'Sandwich and chips', 480, 20, 55, 18, 4, NOW() - INTERVAL '4 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'snack', 'Apple', 80, 0, 20, 0, 4, NOW() - INTERVAL '2 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'dinner', 'Chicken and rice', 520, 35, 58, 12, 2, NOW() - INTERVAL '1 hour');

-- Comeback Hero (072d54c5-3258-495f-b684-da8631dfbf98)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'breakfast', 'Protein smoothie bowl', 380, 28, 42, 12, 8, NOW() - INTERVAL '7 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'lunch', 'Grilled chicken salad', 420, 38, 25, 18, 12, NOW() - INTERVAL '4 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'snack', 'Protein bar', 220, 20, 25, 8, 5, NOW() - INTERVAL '2 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'dinner', 'Lean fish with vegetables', 480, 42, 35, 16, 10, NOW() - INTERVAL '1 hour');

-- Victor Vegeta (135b8ab5-a78d-4c02-8c84-443d3bc75106)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
('135b8ab5-a78d-4c02-8c84-443d3bc75106', CURRENT_DATE, 'breakfast', 'Power breakfast', 450, 30, 50, 15, 8, NOW() - INTERVAL '7 hours'),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', CURRENT_DATE, 'lunch', 'High protein meal', 550, 45, 45, 20, 10, NOW() - INTERVAL '4 hours'),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', CURRENT_DATE, 'dinner', 'Steak and vegetables', 650, 55, 30, 28, 8, NOW() - INTERVAL '1 hour');

-- =====================================================
-- STREAKS DATA
-- =====================================================

INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily', 412, 412, CURRENT_DATE, true, NOW() - INTERVAL '450 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily', 2, 8, CURRENT_DATE - 1, false, NOW() - INTERVAL '45 days', NOW()),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'daily', 0, 3, CURRENT_DATE - 5, false, NOW() - INTERVAL '60 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'daily', 4, 4, CURRENT_DATE, true, NOW() - INTERVAL '5 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'daily', 7, 89, CURRENT_DATE, true, NOW() - INTERVAL '180 days', NOW()),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'daily', 15, 45, CURRENT_DATE, true, NOW() - INTERVAL '90 days', NOW())
ON CONFLICT (user_id, streak_type)
DO UPDATE SET
    current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak,
    last_activity_date = EXCLUDED.last_activity_date,
    target_achieved = EXCLUDED.target_achieved,
    updated_at = NOW();

-- =====================================================
-- USER GOALS
-- =====================================================

-- Elite Athlete goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily_protein', 180, 182, 'grams', true, NOW() - INTERVAL '100 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'weekly_workouts', 7, 7, 'sessions', true, NOW() - INTERVAL '100 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'body_fat_percentage', 8, 9.2, 'percent', true, NOW() - INTERVAL '80 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily_steps', 15000, 16500, 'steps', true, NOW() - INTERVAL '100 days', NOW());

-- Busy Professional goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'weight_loss', 5, 2.8, 'kg', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily_calories', 1800, 1430, 'calories', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'weekly_workouts', 4, 2, 'sessions', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily_steps', 8000, 6800, 'steps', true, NOW() - INTERVAL '30 days', NOW());

-- Weekend Warrior goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'weekend_activities', 2, 2, 'sessions', true, NOW() - INTERVAL '40 days', NOW()),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'weekly_calories_burned', 2000, 2180, 'calories', true, NOW() - INTERVAL '40 days', NOW());

-- New Beginner goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('722c1211-0810-413f-b37e-000065754496', 'daily_steps', 6000, 7200, 'steps', true, NOW() - INTERVAL '5 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'track_meals', 3, 3, 'meals', true, NOW() - INTERVAL '4 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'weekly_workouts', 2, 1, 'sessions', true, NOW() - INTERVAL '3 days', NOW());

-- Comeback Hero goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('072d54c5-3258-495f-b684-da8631dfbf98', 'rebuild_streak', 30, 7, 'days', true, NOW() - INTERVAL '7 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'weight_loss', 10, 1.8, 'kg', true, NOW() - INTERVAL '20 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'daily_calories', 2200, 2080, 'calories', true, NOW() - INTERVAL '7 days', NOW());

-- Victor Vegeta goals
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'weight_loss', 20, 5.2, 'kg', true, NOW() - INTERVAL '60 days', NOW()),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'daily_calories', 2500, 2350, 'calories', true, NOW() - INTERVAL '45 days', NOW()),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'weekly_workouts', 5, 4, 'sessions', true, NOW() - INTERVAL '30 days', NOW());

-- =====================================================
-- USER ACHIEVEMENTS
-- =====================================================

-- Elite Athlete achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'warm_up', NOW() - INTERVAL '410 days', true, NOW() - INTERVAL '410 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'no_excuses', NOW() - INTERVAL '407 days', true, NOW() - INTERVAL '407 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'sweat_starter', NOW() - INTERVAL '403 days', true, NOW() - INTERVAL '403 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'grind_machine', NOW() - INTERVAL '396 days', true, NOW() - INTERVAL '396 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'beast_mode', NOW() - INTERVAL '389 days', true, NOW() - INTERVAL '389 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'iron_month', NOW() - INTERVAL '380 days', true, NOW() - INTERVAL '380 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'quarter_crusher', NOW() - INTERVAL '320 days', true, NOW() - INTERVAL '320 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'half_year', NOW() - INTERVAL '230 days', true, NOW() - INTERVAL '230 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'year_one', NOW() - INTERVAL '48 days', true, NOW() - INTERVAL '48 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- Busy Professional achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'warm_up', NOW() - INTERVAL '40 days', true, NOW() - INTERVAL '40 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'no_excuses', NOW() - INTERVAL '35 days', true, NOW() - INTERVAL '35 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'comeback_kid', NOW() - INTERVAL '5 days', true, NOW() - INTERVAL '5 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- Weekend Warrior achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'warm_up', NOW() - INTERVAL '55 days', true, NOW() - INTERVAL '55 days', NOW()),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'sweatflix', NOW() - INTERVAL '50 days', true, NOW() - INTERVAL '50 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- New Beginner achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('722c1211-0810-413f-b37e-000065754496', 'warm_up', NOW() - INTERVAL '3 days', true, NOW() - INTERVAL '3 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'no_excuses', NOW() - INTERVAL '1 day', false, NOW() - INTERVAL '1 day', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- Comeback Hero achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('072d54c5-3258-495f-b684-da8631dfbf98', 'warm_up', NOW() - INTERVAL '175 days', true, NOW() - INTERVAL '175 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'no_excuses', NOW() - INTERVAL '172 days', true, NOW() - INTERVAL '172 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'sweat_starter', NOW() - INTERVAL '168 days', true, NOW() - INTERVAL '168 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'grind_machine', NOW() - INTERVAL '161 days', true, NOW() - INTERVAL '161 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'comeback_kid', NOW() - INTERVAL '5 days', false, NOW() - INTERVAL '5 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- Victor Vegeta achievements
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'warm_up', NOW() - INTERVAL '85 days', true, NOW() - INTERVAL '85 days', NOW()),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'no_excuses', NOW() - INTERVAL '82 days', true, NOW() - INTERVAL '82 days', NOW()),
('135b8ab5-a78d-4c02-8c84-443d3bc75106', 'sweat_starter', NOW() - INTERVAL '78 days', true, NOW() - INTERVAL '78 days', NOW())
ON CONFLICT (user_id, achievement_id) DO NOTHING;

-- =====================================================
-- CHAT SESSIONS
-- =====================================================

-- Elite Athlete chat sessions
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 1, 'Pre-Competition Nutrition',
 'Discussed carb loading strategy for upcoming competition',
 ARRAY['nutrition timing', 'competition prep', 'carb loading'],
 'Peak performance for competition in 2 weeks',
 'Increase carbs to 8g/kg bodyweight 3 days before event',
 'positive', 15, 12, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 48 minutes',
 NOW(), NOW());

-- Busy Professional chat sessions
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 1, 'Meal Prep Strategy',
 'Discussed efficient meal prep for busy work schedule',
 ARRAY['meal prep', 'time management', 'healthy eating'],
 'Lose 5kg while managing demanding work schedule',
 'Batch cook on Sundays, focus on protein and vegetables',
 'mixed', 18, 15, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '15 minutes',
 NOW() - INTERVAL '1 day', NOW());

-- New Beginner chat sessions
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), '722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 2, 1, 'Getting Started Guide',
 'Introduction to fitness tracking and setting realistic goals',
 ARRAY['fitness basics', 'goal setting', 'app navigation'],
 'Start building healthy habits gradually',
 'Focus on consistency over intensity, track 3 meals daily',
 'positive', 25, 20, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '20 minutes',
 NOW() - INTERVAL '2 days', NOW());

-- Comeback Hero chat sessions
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), '072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 1, 1, 'Comeback Strategy',
 'Discussed how to rebuild streak after major setback',
 ARRAY['motivation', 'streak rebuilding', 'avoiding burnout'],
 'Rebuild 90-day streak within 3 months',
 'Focus on consistency over perfection, celebrate small wins',
 'mixed', 28, 25, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '25 minutes',
 NOW() - INTERVAL '1 day', NOW());

-- Victor Vegeta chat sessions
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), '135b8ab5-a78d-4c02-8c84-443d3bc75106', CURRENT_DATE, 1, 'Weight Loss Journey',
 'Reviewed progress and adjusted calorie targets',
 ARRAY['weight loss', 'nutrition', 'exercise plan'],
 'Lose 20kg total, currently at 5.2kg lost',
 'Increase protein intake, add HIIT workouts 2x per week',
 'positive', 20, 18, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 42 minutes',
 NOW(), NOW());

-- =====================================================
-- SUMMARY
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ TEST DATA CREATED FOR OTHER TABLES!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Data inserted for existing users:';
    RAISE NOTICE '   • Nutrition entries for all 6 users';
    RAISE NOTICE '   • Streaks data with varied patterns';
    RAISE NOTICE '   • User goals covering different objectives';
    RAISE NOTICE '   • Achievements from beginner to elite';
    RAISE NOTICE '   • Chat sessions showing AI coaching';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Note: Using ON CONFLICT clauses to handle duplicates';
    RAISE NOTICE '   This allows safe re-running of the script';
END $$;

-- =====================================================
-- END OF TEST DATA SCRIPT
-- =====================================================