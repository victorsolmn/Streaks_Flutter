-- =====================================================
-- COMPREHENSIVE TEST DATA FOR STREAKS FLUTTER APP
-- =====================================================
-- Created: September 19, 2025
--
-- This script creates diverse test user personas with realistic data
-- covering all database tables and relationships for comprehensive testing.
--
-- SETUP INSTRUCTIONS:
-- 1. First create user accounts through the app's sign-up flow with these emails:
--    - elite.athlete@test.com (password: Test123!)
--    - busy.professional@test.com (password: Test123!)
--    - weekend.warrior@test.com (password: Test123!)
--    - new.beginner@test.com (password: Test123!)
--    - comeback.hero@test.com (password: Test123!)
--    - data.enthusiast@test.com (password: Test123!)
--    - casual.user@test.com (password: Test123!)
--    - health.focused@test.com (password: Test123!)
--
-- 2. Get the actual user IDs from Supabase Auth:
SELECT id, email FROM auth.users WHERE email IN (
    'elite.athlete@test.com',
    'busy.professional@test.com',
    'weekend.warrior@test.com',
    'new.beginner@test.com',
    'comeback.hero@test.com',
    'data.enthusiast@test.com',
    'casual.user@test.com',
    'health.focused@test.com'
);

-- 3. Replace all 'USER_ID_X' placeholders below with actual UUIDs
-- 4. Run this script in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- PERSONA 1: THE ELITE ATHLETE (400+ day streak legend)
-- Email: elite.athlete@test.com
-- Profile: Advanced athlete, daily workouts, perfect nutrition tracking
-- =====================================================

-- Profile Data
INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_1', 'elite.athlete@test.com', 'Marcus Rodriguez', 29, 185, 82,
    'Very Active', 'Build Strength', 'Advanced', 80, 'Daily',
    3200, 15000, 8.5, 4.0, true, true,
    NOW() - INTERVAL '450 days', NOW()
);

-- Health Metrics (Last 14 days - showing consistency)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Recent 7 days
('USER_ID_1', CURRENT_DATE, 16500, 65, 8.5, 650, 12.5, 90, 4.2, NOW(), NOW()),
('USER_ID_1', CURRENT_DATE - 1, 15800, 68, 8.0, 720, 11.8, 105, 4.0, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_1', CURRENT_DATE - 2, 17200, 62, 9.0, 680, 13.2, 95, 4.5, NOW() - INTERVAL '2 days', NOW()),
('USER_ID_1', CURRENT_DATE - 3, 16000, 70, 8.2, 700, 12.0, 110, 4.1, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_1', CURRENT_DATE - 4, 18500, 66, 8.8, 780, 14.5, 120, 4.3, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_1', CURRENT_DATE - 5, 15500, 64, 7.8, 650, 11.5, 85, 3.9, NOW() - INTERVAL '5 days', NOW()),
('USER_ID_1', CURRENT_DATE - 6, 19000, 69, 9.2, 820, 15.8, 130, 4.6, NOW() - INTERVAL '6 days', NOW()),
-- Previous week
('USER_ID_1', CURRENT_DATE - 7, 16800, 67, 8.3, 710, 12.8, 100, 4.2, NOW() - INTERVAL '7 days', NOW()),
('USER_ID_1', CURRENT_DATE - 8, 17500, 63, 8.7, 750, 13.8, 115, 4.4, NOW() - INTERVAL '8 days', NOW()),
('USER_ID_1', CURRENT_DATE - 9, 15200, 71, 8.0, 630, 11.2, 80, 3.8, NOW() - INTERVAL '9 days', NOW()),
('USER_ID_1', CURRENT_DATE - 10, 18200, 65, 9.1, 790, 14.2, 125, 4.5, NOW() - INTERVAL '10 days', NOW()),
('USER_ID_1', CURRENT_DATE - 11, 16500, 68, 8.4, 680, 12.5, 95, 4.1, NOW() - INTERVAL '11 days', NOW()),
('USER_ID_1', CURRENT_DATE - 12, 17800, 64, 8.9, 760, 13.5, 110, 4.3, NOW() - INTERVAL '12 days', NOW()),
('USER_ID_1', CURRENT_DATE - 13, 16200, 70, 8.1, 670, 12.0, 88, 4.0, NOW() - INTERVAL '13 days', NOW());

-- Nutrition Entries (Last 3 days - detailed tracking)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today
('USER_ID_1', CURRENT_DATE, 'breakfast', 'Protein oatmeal with berries', 420, 35, 55, 8, 12, NOW() - INTERVAL '6 hours'),
('USER_ID_1', CURRENT_DATE, 'pre_workout', 'Pre-workout shake', 180, 25, 20, 2, 0, NOW() - INTERVAL '4 hours'),
('USER_ID_1', CURRENT_DATE, 'lunch', 'Grilled chicken with quinoa', 580, 48, 52, 16, 8, NOW() - INTERVAL '3 hours'),
('USER_ID_1', CURRENT_DATE, 'post_workout', 'Recovery protein shake', 320, 45, 28, 4, 2, NOW() - INTERVAL '2 hours'),
('USER_ID_1', CURRENT_DATE, 'snack', 'Greek yogurt with almonds', 220, 20, 15, 12, 3, NOW() - INTERVAL '1 hour'),
('USER_ID_1', CURRENT_DATE, 'dinner', 'Salmon with sweet potato', 640, 52, 42, 22, 6, NOW()),
-- Yesterday
('USER_ID_1', CURRENT_DATE - 1, 'breakfast', 'Egg white omelet with spinach', 380, 32, 25, 15, 8, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - 1, 'lunch', 'Turkey and avocado wrap', 520, 38, 45, 18, 10, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - 1, 'snack', 'Protein bar', 280, 25, 30, 8, 5, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - 1, 'dinner', 'Lean beef with vegetables', 680, 55, 35, 25, 12, NOW() - INTERVAL '1 day'),
-- Day before yesterday
('USER_ID_1', CURRENT_DATE - 2, 'breakfast', 'Protein pancakes', 450, 30, 48, 12, 6, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - 2, 'lunch', 'Tuna salad with chickpeas', 480, 42, 38, 16, 15, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - 2, 'snack', 'Mixed nuts and fruit', 250, 8, 28, 15, 8, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - 2, 'dinner', 'Grilled fish with brown rice', 620, 48, 55, 18, 10, NOW() - INTERVAL '2 days');

-- Streak Data (Elite level)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_1', 'daily', 412, 412, CURRENT_DATE, true,
    NOW() - INTERVAL '450 days', NOW()
);

-- User Goals (Advanced athlete goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_1', 'daily_protein', 180, 182, 'grams', true, NOW() - INTERVAL '100 days', NOW()),
('USER_ID_1', 'weekly_workouts', 7, 7, 'sessions', true, NOW() - INTERVAL '100 days', NOW()),
('USER_ID_1', 'body_fat_percentage', 8, 9.2, 'percent', true, NOW() - INTERVAL '80 days', NOW()),
('USER_ID_1', 'daily_steps', 15000, 16500, 'steps', true, NOW() - INTERVAL '100 days', NOW());

-- Achievements (Multiple unlocked for elite user)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_1', 'warm_up', NOW() - INTERVAL '410 days', true, NOW() - INTERVAL '410 days', NOW()),
('USER_ID_1', 'no_excuses', NOW() - INTERVAL '407 days', true, NOW() - INTERVAL '407 days', NOW()),
('USER_ID_1', 'sweat_starter', NOW() - INTERVAL '403 days', true, NOW() - INTERVAL '403 days', NOW()),
('USER_ID_1', 'grind_machine', NOW() - INTERVAL '396 days', true, NOW() - INTERVAL '396 days', NOW()),
('USER_ID_1', 'beast_mode', NOW() - INTERVAL '389 days', true, NOW() - INTERVAL '389 days', NOW()),
('USER_ID_1', 'iron_month', NOW() - INTERVAL '380 days', true, NOW() - INTERVAL '380 days', NOW()),
('USER_ID_1', 'quarter_crusher', NOW() - INTERVAL '320 days', true, NOW() - INTERVAL '320 days', NOW()),
('USER_ID_1', 'half_year', NOW() - INTERVAL '230 days', true, NOW() - INTERVAL '230 days', NOW()),
('USER_ID_1', 'year_one', NOW() - INTERVAL '48 days', true, NOW() - INTERVAL '48 days', NOW()),
('USER_ID_1', 'sweatflix', NOW() - INTERVAL '350 days', true, NOW() - INTERVAL '350 days', NOW()),
('USER_ID_1', 'no_days_off', NOW() - INTERVAL '380 days', true, NOW() - INTERVAL '380 days', NOW());

-- Chat Sessions (AI coaching history)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_1', CURRENT_DATE, 1, 'Pre-Competition Nutrition',
 'Discussed carb loading strategy for upcoming competition',
 ARRAY['nutrition timing', 'competition prep', 'carb loading'],
 'Peak performance for competition in 2 weeks',
 'Increase carbs to 8g/kg bodyweight 3 days before event',
 'positive', 15, 12, NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 48 minutes',
 NOW(), NOW()),
(gen_random_uuid(), 'USER_ID_1', CURRENT_DATE - 3, 1, 'Recovery Protocol Review',
 'Optimized recovery routine after intense training block',
 ARRAY['recovery', 'sleep optimization', 'active rest'],
 'Maintain strength gains while improving recovery',
 'Add 15min meditation, prioritize 9h sleep during heavy weeks',
 'positive', 22, 18, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '18 minutes',
 NOW() - INTERVAL '3 days', NOW());

-- =====================================================
-- PERSONA 2: THE BUSY PROFESSIONAL (Inconsistent but trying)
-- Email: busy.professional@test.com
-- Profile: Works long hours, struggles with consistency, meal prep focused
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_2', 'busy.professional@test.com', 'Sarah Chen', 34, 168, 71,
    'Lightly Active', 'Lose Weight', 'Intermediate', 66, '3-4 times per week',
    1800, 8000, 7.0, 2.5, true, true,
    NOW() - INTERVAL '45 days', NOW()
);

-- Health Metrics (Sporadic pattern - busy lifestyle)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Good days mixed with busy days
('USER_ID_2', CURRENT_DATE, 6800, 72, 6.5, 280, 4.2, 35, 2.1, NOW(), NOW()),
('USER_ID_2', CURRENT_DATE - 1, 12500, 68, 7.2, 450, 8.5, 60, 2.8, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_2', CURRENT_DATE - 2, 4200, 75, 5.8, 180, 2.8, 20, 1.8, NOW() - INTERVAL '2 days', NOW()), -- Busy day
('USER_ID_2', CURRENT_DATE - 3, 9800, 70, 7.5, 380, 6.8, 45, 2.6, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_2', CURRENT_DATE - 4, 11200, 69, 6.8, 420, 7.5, 55, 2.4, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_2', CURRENT_DATE - 5, 3800, 78, 5.5, 160, 2.5, 15, 1.5, NOW() - INTERVAL '5 days', NOW()), -- Another busy day
('USER_ID_2', CURRENT_DATE - 6, 13500, 66, 8.0, 480, 9.2, 70, 3.0, NOW() - INTERVAL '6 days', NOW()); -- Weekend

-- Nutrition Entries (Meal prep focused, some missed days)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today (good day)
('USER_ID_2', CURRENT_DATE, 'breakfast', 'Overnight oats with protein powder', 350, 25, 45, 8, 10, NOW() - INTERVAL '8 hours'),
('USER_ID_2', CURRENT_DATE, 'lunch', 'Meal prep chicken bowl', 480, 38, 42, 16, 8, NOW() - INTERVAL '5 hours'),
('USER_ID_2', CURRENT_DATE, 'snack', 'Apple with almond butter', 180, 6, 22, 8, 5, NOW() - INTERVAL '3 hours'),
('USER_ID_2', CURRENT_DATE, 'dinner', 'Takeout sushi (tracked)', 420, 28, 55, 12, 3, NOW() - INTERVAL '1 hour'),
-- Yesterday (workout day)
('USER_ID_2', CURRENT_DATE - 1, 'breakfast', 'Greek yogurt parfait', 280, 20, 35, 6, 4, NOW() - INTERVAL '1 day'),
('USER_ID_2', CURRENT_DATE - 1, 'lunch', 'Salad with grilled protein', 380, 32, 25, 18, 12, NOW() - INTERVAL '1 day'),
('USER_ID_2', CURRENT_DATE - 1, 'post_workout', 'Protein shake', 150, 25, 8, 2, 0, NOW() - INTERVAL '1 day'),
('USER_ID_2', CURRENT_DATE - 1, 'dinner', 'Stir fry with brown rice', 520, 28, 58, 18, 6, NOW() - INTERVAL '1 day'),
-- Day -2 was too busy (no entries)
-- Day -3 (partial tracking)
('USER_ID_2', CURRENT_DATE - 3, 'breakfast', 'Coffee and granola bar', 220, 5, 35, 8, 3, NOW() - INTERVAL '3 days'),
('USER_ID_2', CURRENT_DATE - 3, 'lunch', 'Work cafeteria meal', 450, 22, 48, 20, 4, NOW() - INTERVAL '3 days');

-- Streak Data (Recently broken, trying to rebuild)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_2', 'daily', 2, 8, CURRENT_DATE - 1, false,
    NOW() - INTERVAL '45 days', NOW()
);

-- User Goals (Weight loss focused)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_2', 'weight_loss', 5, 2.8, 'kg', true, NOW() - INTERVAL '30 days', NOW()),
('USER_ID_2', 'daily_calories', 1800, 1430, 'calories', true, NOW() - INTERVAL '30 days', NOW()),
('USER_ID_2', 'weekly_workouts', 4, 2, 'sessions', true, NOW() - INTERVAL '30 days', NOW()),
('USER_ID_2', 'daily_steps', 8000, 6800, 'steps', true, NOW() - INTERVAL '30 days', NOW());

-- Achievements (Few unlocked, working on consistency)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_2', 'warm_up', NOW() - INTERVAL '40 days', true, NOW() - INTERVAL '40 days', NOW()),
('USER_ID_2', 'no_excuses', NOW() - INTERVAL '35 days', true, NOW() - INTERVAL '35 days', NOW()),
('USER_ID_2', 'sweat_starter', NOW() - INTERVAL '25 days', true, NOW() - INTERVAL '25 days', NOW()),
('USER_ID_2', 'comeback_kid', NOW() - INTERVAL '5 days', true, NOW() - INTERVAL '5 days', NOW());

-- Chat Sessions (Seeking advice on time management)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_2', CURRENT_DATE - 1, 1, 'Meal Prep Strategy',
 'Discussed efficient meal prep for busy work schedule',
 ARRAY['meal prep', 'time management', 'healthy eating'],
 'Lose 5kg while managing demanding work schedule',
 'Batch cook on Sundays, focus on protein and vegetables',
 'mixed', 18, 15, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '15 minutes',
 NOW() - INTERVAL '1 day', NOW());

-- =====================================================
-- PERSONA 3: THE WEEKEND WARRIOR
-- Email: weekend.warrior@test.com
-- Profile: Very active on weekends, sedentary during weekdays
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_3', 'weekend.warrior@test.com', 'Mike Johnson', 31, 180, 85,
    'Moderately Active', 'Maintain Weight', 'Intermediate', 83, '1-2 times per week',
    2400, 7000, 7.5, 3.0, true, false,
    NOW() - INTERVAL '60 days', NOW()
);

-- Health Metrics (Weekend spikes, weekday lows)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- This week pattern
('USER_ID_3', CURRENT_DATE, 22000, 72, 8.5, 980, 18.5, 150, 4.2, NOW(), NOW()), -- Sunday
('USER_ID_3', CURRENT_DATE - 1, 25500, 68, 8.0, 1200, 22.0, 180, 4.8, NOW() - INTERVAL '1 day', NOW()), -- Saturday
('USER_ID_3', CURRENT_DATE - 2, 4500, 70, 7.0, 220, 3.2, 25, 2.5, NOW() - INTERVAL '2 days', NOW()), -- Friday
('USER_ID_3', CURRENT_DATE - 3, 5200, 72, 7.2, 280, 3.8, 30, 2.8, NOW() - INTERVAL '3 days', NOW()), -- Thursday
('USER_ID_3', CURRENT_DATE - 4, 4800, 74, 6.8, 240, 3.5, 22, 2.2, NOW() - INTERVAL '4 days', NOW()), -- Wednesday
('USER_ID_3', CURRENT_DATE - 5, 6200, 71, 7.5, 320, 4.5, 35, 3.0, NOW() - INTERVAL '5 days', NOW()), -- Tuesday
('USER_ID_3', CURRENT_DATE - 6, 5800, 73, 7.8, 300, 4.2, 32, 2.9, NOW() - INTERVAL '6 days', NOW()), -- Monday
-- Previous weekend
('USER_ID_3', CURRENT_DATE - 7, 28000, 66, 9.0, 1400, 25.0, 200, 5.0, NOW() - INTERVAL '7 days', NOW()); -- Sunday

-- Nutrition Entries (Indulgent weekends, lighter weekdays)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Weekend indulgence
('USER_ID_3', CURRENT_DATE, 'breakfast', 'Weekend pancake stack', 680, 18, 95, 22, 6, NOW() - INTERVAL '6 hours'),
('USER_ID_3', CURRENT_DATE, 'lunch', 'BBQ burger with fries', 950, 45, 78, 48, 8, NOW() - INTERVAL '3 hours'),
('USER_ID_3', CURRENT_DATE, 'snack', 'Craft beer', 180, 2, 15, 0, 0, NOW() - INTERVAL '2 hours'),
('USER_ID_3', CURRENT_DATE, 'dinner', 'Pizza night', 820, 35, 85, 35, 4, NOW() - INTERVAL '1 hour'),
-- Saturday (active day)
('USER_ID_3', CURRENT_DATE - 1, 'breakfast', 'Sports drink and energy bar', 280, 8, 55, 6, 2, NOW() - INTERVAL '1 day'),
('USER_ID_3', CURRENT_DATE - 1, 'lunch', 'Post-hike sandwich', 580, 35, 65, 18, 8, NOW() - INTERVAL '1 day'),
('USER_ID_3', CURRENT_DATE - 1, 'dinner', 'Celebratory steak dinner', 920, 65, 45, 42, 6, NOW() - INTERVAL '1 day'),
-- Weekday (lighter)
('USER_ID_3', CURRENT_DATE - 3, 'breakfast', 'Coffee and muffin', 320, 6, 48, 12, 2, NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - 3, 'lunch', 'Desk salad', 380, 25, 30, 18, 10, NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - 3, 'dinner', 'Simple pasta', 520, 18, 78, 16, 4, NOW() - INTERVAL '3 days');

-- Streak Data (Poor consistency due to weekend-only pattern)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_3', 'daily', 0, 3, CURRENT_DATE - 5, false,
    NOW() - INTERVAL '60 days', NOW()
);

-- User Goals (Maintenance focused)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_3', 'weekend_activities', 2, 2, 'sessions', true, NOW() - INTERVAL '40 days', NOW()),
('USER_ID_3', 'weekly_calories_burned', 2000, 2180, 'calories', true, NOW() - INTERVAL '40 days', NOW());

-- Achievements (Weekend focused)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_3', 'warm_up', NOW() - INTERVAL '55 days', true, NOW() - INTERVAL '55 days', NOW()),
('USER_ID_3', 'sweatflix', NOW() - INTERVAL '50 days', true, NOW() - INTERVAL '50 days', NOW());

-- =====================================================
-- PERSONA 4: THE NEW BEGINNER
-- Email: new.beginner@test.com
-- Profile: Just started 5 days ago, learning the ropes
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_4', 'new.beginner@test.com', 'Emma Wilson', 26, 162, 58,
    'Sedentary', 'Improve Fitness', 'Beginner', 55, 'Rarely',
    1600, 6000, 8.0, 2.0, true, false,
    NOW() - INTERVAL '5 days', NOW()
);

-- Health Metrics (Just started tracking)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
('USER_ID_4', CURRENT_DATE, 7200, 78, 7.5, 220, 4.8, 30, 2.2, NOW(), NOW()),
('USER_ID_4', CURRENT_DATE - 1, 6800, 80, 8.2, 200, 4.5, 25, 2.0, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_4', CURRENT_DATE - 2, 8500, 76, 7.8, 280, 6.2, 40, 2.5, NOW() - INTERVAL '2 days', NOW()),
('USER_ID_4', CURRENT_DATE - 3, 5200, 82, 7.0, 150, 3.8, 20, 1.8, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_4', CURRENT_DATE - 4, 6500, 79, 8.5, 190, 4.2, 28, 2.1, NOW() - INTERVAL '4 days', NOW());

-- Nutrition Entries (Learning to track, simple meals)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today (getting better at tracking)
('USER_ID_4', CURRENT_DATE, 'breakfast', 'Cereal with milk', 280, 8, 45, 6, 3, NOW() - INTERVAL '8 hours'),
('USER_ID_4', CURRENT_DATE, 'lunch', 'Sandwich and chips', 480, 20, 55, 18, 4, NOW() - INTERVAL '4 hours'),
('USER_ID_4', CURRENT_DATE, 'snack', 'Apple', 80, 0, 20, 0, 4, NOW() - INTERVAL '2 hours'),
('USER_ID_4', CURRENT_DATE, 'dinner', 'Chicken and rice', 520, 35, 58, 12, 2, NOW() - INTERVAL '1 hour'),
-- Yesterday
('USER_ID_4', CURRENT_DATE - 1, 'breakfast', 'Toast with butter', 220, 6, 35, 8, 2, NOW() - INTERVAL '1 day'),
('USER_ID_4', CURRENT_DATE - 1, 'lunch', 'Salad with dressing', 320, 15, 25, 18, 8, NOW() - INTERVAL '1 day'),
('USER_ID_4', CURRENT_DATE - 1, 'dinner', 'Pasta with sauce', 450, 15, 78, 12, 4, NOW() - INTERVAL '1 day'),
-- Day -2 (first real attempt)
('USER_ID_4', CURRENT_DATE - 2, 'breakfast', 'Yogurt', 150, 12, 18, 5, 0, NOW() - INTERVAL '2 days'),
('USER_ID_4', CURRENT_DATE - 2, 'lunch', 'Leftovers', 380, 22, 35, 16, 3, NOW() - INTERVAL '2 days');

-- Streak Data (Just getting started)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_4', 'daily', 4, 4, CURRENT_DATE, true,
    NOW() - INTERVAL '5 days', NOW()
);

-- User Goals (Beginner-friendly goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_4', 'daily_steps', 6000, 7200, 'steps', true, NOW() - INTERVAL '5 days', NOW()),
('USER_ID_4', 'track_meals', 3, 3, 'meals', true, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_4', 'weekly_workouts', 2, 1, 'sessions', true, NOW() - INTERVAL '3 days', NOW());

-- Achievements (Early achievements)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_4', 'warm_up', NOW() - INTERVAL '3 days', true, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_4', 'no_excuses', NOW() - INTERVAL '1 day', false, NOW() - INTERVAL '1 day', NOW());

-- Chat Sessions (Getting started guidance)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_4', CURRENT_DATE - 2, 1, 'Getting Started Guide',
 'Introduction to fitness tracking and setting realistic goals',
 ARRAY['fitness basics', 'goal setting', 'app navigation'],
 'Start building healthy habits gradually',
 'Focus on consistency over intensity, track 3 meals daily',
 'positive', 25, 20, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '20 minutes',
 NOW() - INTERVAL '2 days', NOW());

-- =====================================================
-- PERSONA 5: THE COMEBACK HERO
-- Email: comeback.hero@test.com
-- Profile: Had a long streak, lost it, now rebuilding with determination
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_5', 'comeback.hero@test.com', 'David Martinez', 38, 175, 78,
    'Moderately Active', 'Lose Weight', 'Advanced', 73, '5-6 times per week',
    2200, 12000, 7.5, 3.5, true, true,
    NOW() - INTERVAL '180 days', NOW()
);

-- Health Metrics (Recently restarted with high motivation)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Strong comeback streak
('USER_ID_5', CURRENT_DATE, 14500, 70, 7.8, 520, 10.5, 75, 3.8, NOW(), NOW()),
('USER_ID_5', CURRENT_DATE - 1, 13800, 72, 7.5, 480, 9.8, 70, 3.6, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_5', CURRENT_DATE - 2, 15200, 68, 8.0, 580, 11.2, 85, 4.0, NOW() - INTERVAL '2 days', NOW()),
('USER_ID_5', CURRENT_DATE - 3, 12500, 74, 7.2, 450, 9.0, 65, 3.4, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_5', CURRENT_DATE - 4, 16800, 66, 8.2, 650, 12.8, 95, 4.2, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_5', CURRENT_DATE - 5, 13200, 71, 7.6, 500, 9.5, 72, 3.7, NOW() - INTERVAL '5 days', NOW()),
('USER_ID_5', CURRENT_DATE - 6, 14000, 69, 7.9, 530, 10.2, 78, 3.9, NOW() - INTERVAL '6 days', NOW()),
-- Gap where streak was lost (simulating missed days)
('USER_ID_5', CURRENT_DATE - 12, 11500, 73, 7.0, 420, 8.5, 60, 3.2, NOW() - INTERVAL '12 days', NOW()),
('USER_ID_5', CURRENT_DATE - 13, 10800, 75, 6.8, 380, 7.8, 55, 3.0, NOW() - INTERVAL '13 days', NOW());

-- Nutrition Entries (Disciplined approach after restart)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Recent days showing discipline
('USER_ID_5', CURRENT_DATE, 'breakfast', 'Protein smoothie bowl', 380, 28, 42, 12, 8, NOW() - INTERVAL '7 hours'),
('USER_ID_5', CURRENT_DATE, 'lunch', 'Grilled chicken salad', 420, 38, 25, 18, 12, NOW() - INTERVAL '4 hours'),
('USER_ID_5', CURRENT_DATE, 'snack', 'Protein bar', 220, 20, 25, 8, 5, NOW() - INTERVAL '2 hours'),
('USER_ID_5', CURRENT_DATE, 'dinner', 'Lean fish with vegetables', 480, 42, 35, 16, 10, NOW() - INTERVAL '1 hour'),
('USER_ID_5', CURRENT_DATE - 1, 'breakfast', 'Oatmeal with berries', 320, 15, 55, 8, 12, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - 1, 'lunch', 'Turkey wrap', 450, 32, 48, 16, 8, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - 1, 'dinner', 'Salmon with quinoa', 580, 45, 52, 22, 6, NOW() - INTERVAL '1 day');

-- Streak Data (Lost previous long streak, rebuilding)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_5', 'daily', 7, 89, CURRENT_DATE, true,
    NOW() - INTERVAL '180 days', NOW()
);

-- User Goals (Focused on rebuilding)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_5', 'rebuild_streak', 30, 7, 'days', true, NOW() - INTERVAL '7 days', NOW()),
('USER_ID_5', 'weight_loss', 5, 1.8, 'kg', true, NOW() - INTERVAL '20 days', NOW()),
('USER_ID_5', 'daily_calories', 2200, 2080, 'calories', true, NOW() - INTERVAL '7 days', NOW());

-- Achievements (Had many, now rebuilding)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_5', 'warm_up', NOW() - INTERVAL '175 days', true, NOW() - INTERVAL '175 days', NOW()),
('USER_ID_5', 'no_excuses', NOW() - INTERVAL '172 days', true, NOW() - INTERVAL '172 days', NOW()),
('USER_ID_5', 'sweat_starter', NOW() - INTERVAL '168 days', true, NOW() - INTERVAL '168 days', NOW()),
('USER_ID_5', 'grind_machine', NOW() - INTERVAL '161 days', true, NOW() - INTERVAL '161 days', NOW()),
('USER_ID_5', 'beast_mode', NOW() - INTERVAL '154 days', true, NOW() - INTERVAL '154 days', NOW()),
('USER_ID_5', 'iron_month', NOW() - INTERVAL '145 days', true, NOW() - INTERVAL '145 days', NOW()),
('USER_ID_5', 'quarter_crusher', NOW() - INTERVAL '86 days', true, NOW() - INTERVAL '86 days', NOW()),
('USER_ID_5', 'comeback_kid', NOW() - INTERVAL '5 days', false, NOW() - INTERVAL '5 days', NOW());

-- Chat Sessions (Motivation and strategy)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_5', CURRENT_DATE - 1, 1, 'Comeback Strategy',
 'Discussed how to rebuild streak after major setback',
 ARRAY['motivation', 'streak rebuilding', 'avoiding burnout'],
 'Rebuild 90-day streak within 3 months',
 'Focus on consistency over perfection, celebrate small wins',
 'mixed', 28, 25, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '25 minutes',
 NOW() - INTERVAL '1 day', NOW());

-- =====================================================
-- PERSONA 6: THE DATA ENTHUSIAST
-- Email: data.enthusiast@test.com
-- Profile: Tracks everything meticulously, loves metrics and optimization
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_6', 'data.enthusiast@test.com', 'Alex Thompson', 33, 172, 69,
    'Very Active', 'Build Strength', 'Advanced', 71, 'Daily',
    2800, 14000, 8.0, 3.8, true, true,
    NOW() - INTERVAL '90 days', NOW()
);

-- Health Metrics (Extremely detailed tracking)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Precise daily tracking
('USER_ID_6', CURRENT_DATE, 14247, 62, 8.17, 615, 11.85, 88, 3.85, NOW(), NOW()),
('USER_ID_6', CURRENT_DATE - 1, 13892, 65, 7.93, 587, 11.42, 92, 3.92, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_6', CURRENT_DATE - 2, 15183, 61, 8.25, 672, 12.68, 105, 4.12, NOW() - INTERVAL '2 days', NOW()),
('USER_ID_6', CURRENT_DATE - 3, 14536, 64, 8.08, 628, 12.15, 95, 3.78, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_6', CURRENT_DATE - 4, 13675, 66, 7.85, 594, 11.28, 87, 3.65, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_6', CURRENT_DATE - 5, 16025, 59, 8.42, 715, 13.92, 112, 4.25, NOW() - INTERVAL '5 days', NOW()),
('USER_ID_6', CURRENT_DATE - 6, 14789, 63, 8.03, 641, 12.32, 98, 3.88, NOW() - INTERVAL '6 days', NOW());

-- Nutrition Entries (Extremely detailed, weighed and measured)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today (macro-precise entries)
('USER_ID_6', CURRENT_DATE, 'breakfast', '45g oats + 250ml skim milk + 80g blueberries', 387, 18.2, 67.5, 4.8, 12.3, NOW() - INTERVAL '8 hours'),
('USER_ID_6', CURRENT_DATE, 'pre_workout', '30g whey protein + 200ml water', 118, 24.6, 2.1, 0.9, 0, NOW() - INTERVAL '6 hours'),
('USER_ID_6', CURRENT_DATE, 'lunch', '150g chicken breast + 100g brown rice + 200g mixed vegetables', 567, 48.2, 52.8, 8.4, 11.2, NOW() - INTERVAL '4 hours'),
('USER_ID_6', CURRENT_DATE, 'post_workout', '35g whey protein + 1 large banana', 225, 28.8, 27.6, 1.2, 3.1, NOW() - INTERVAL '2 hours'),
('USER_ID_6', CURRENT_DATE, 'snack', '28g almonds + 1 medium apple', 259, 7.8, 24.3, 14.2, 8.4, NOW() - INTERVAL '90 minutes'),
('USER_ID_6', CURRENT_DATE, 'dinner', '180g salmon + 150g sweet potato + 120g asparagus', 612, 45.6, 42.8, 18.9, 9.6, NOW() - INTERVAL '30 minutes'),
-- Yesterday (similarly detailed)
('USER_ID_6', CURRENT_DATE - 1, 'breakfast', '3 large eggs + 2 slices whole grain toast + 1 tbsp olive oil', 485, 22.4, 32.1, 26.8, 6.2, NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - 1, 'lunch', '120g lean beef + 80g quinoa + mixed salad with 15ml dressing', 528, 38.6, 41.2, 16.8, 7.9, NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - 1, 'snack', '170g Greek yogurt + 20g honey + 15g walnuts', 312, 15.8, 28.4, 12.6, 2.1, NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - 1, 'dinner', '140g cod + 200g broccoli + 100g wild rice', 421, 36.2, 52.8, 3.9, 8.8, NOW() - INTERVAL '1 day');

-- Streak Data (Consistent long-term tracking)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_6', 'daily', 87, 87, CURRENT_DATE, true,
    NOW() - INTERVAL '90 days', NOW()
);

-- User Goals (Multiple detailed goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_6', 'daily_protein', 140, 142.8, 'grams', true, NOW() - INTERVAL '85 days', NOW()),
('USER_ID_6', 'body_fat_percentage', 12, 13.2, 'percent', true, NOW() - INTERVAL '60 days', NOW()),
('USER_ID_6', 'vo2_max', 55, 52.8, 'ml/kg/min', true, NOW() - INTERVAL '45 days', NOW()),
('USER_ID_6', 'weekly_training_volume', 8, 8.5, 'hours', true, NOW() - INTERVAL '30 days', NOW()),
('USER_ID_6', 'hydration_consistency', 95, 97.2, 'percent', true, NOW() - INTERVAL '20 days', NOW());

-- Achievements (Many unlocked through consistent tracking)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_6', 'warm_up', NOW() - INTERVAL '87 days', true, NOW() - INTERVAL '87 days', NOW()),
('USER_ID_6', 'no_excuses', NOW() - INTERVAL '84 days', true, NOW() - INTERVAL '84 days', NOW()),
('USER_ID_6', 'sweat_starter', NOW() - INTERVAL '80 days', true, NOW() - INTERVAL '80 days', NOW()),
('USER_ID_6', 'grind_machine', NOW() - INTERVAL '73 days', true, NOW() - INTERVAL '73 days', NOW()),
('USER_ID_6', 'beast_mode', NOW() - INTERVAL '66 days', true, NOW() - INTERVAL '66 days', NOW()),
('USER_ID_6', 'iron_month', NOW() - INTERVAL '57 days', true, NOW() - INTERVAL '57 days', NOW()),
('USER_ID_6', 'no_days_off', NOW() - INTERVAL '80 days', true, NOW() - INTERVAL '80 days', NOW());

-- Chat Sessions (Data analysis and optimization)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_6', CURRENT_DATE, 1, 'Macro Optimization Analysis',
 'Deep dive into protein timing and workout performance correlation',
 ARRAY['macro timing', 'performance metrics', 'data analysis'],
 'Optimize protein synthesis and reduce body fat to 12%',
 'Increase post-workout protein to 40g, track HRV for recovery',
 'positive', 32, 28, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 32 minutes',
 NOW(), NOW()),
(gen_random_uuid(), 'USER_ID_6', CURRENT_DATE - 7, 1, 'Weekly Performance Review',
 'Analyzed weekly trends in sleep, nutrition, and performance metrics',
 ARRAY['weekly analysis', 'trend identification', 'optimization'],
 'Maintain current trajectory while fine-tuning recovery',
 'Sleep quality correlates with performance, aim for 8.2h average',
 'positive', 24, 22, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '22 minutes',
 NOW() - INTERVAL '7 days', NOW());

-- =====================================================
-- PERSONA 7: THE CASUAL USER
-- Email: casual.user@test.com
-- Profile: Uses app occasionally, inconsistent tracking, moderate goals
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_7', 'casual.user@test.com', 'Lisa Parker', 28, 165, 63,
    'Lightly Active', 'Maintain Weight', 'Beginner', 62, 'Rarely',
    2000, 8000, 7.0, 2.5, false, false,
    NOW() - INTERVAL '90 days', NOW()
);

-- Health Metrics (Sporadic tracking)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Irregular pattern
('USER_ID_7', CURRENT_DATE, 9200, 75, 7.2, 320, 6.5, 45, 2.8, NOW(), NOW()),
('USER_ID_7', CURRENT_DATE - 3, 12500, 72, 8.0, 450, 8.8, 65, 3.2, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_7', CURRENT_DATE - 8, 6800, 78, 6.5, 220, 4.2, 25, 2.0, NOW() - INTERVAL '8 days', NOW()),
('USER_ID_7', CURRENT_DATE - 12, 11000, 74, 7.5, 380, 7.5, 55, 2.9, NOW() - INTERVAL '12 days', NOW()),
('USER_ID_7', CURRENT_DATE - 18, 8500, 76, 7.0, 280, 5.8, 35, 2.4, NOW() - INTERVAL '18 days', NOW());

-- Nutrition Entries (Very sporadic, simple entries)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Recent attempt
('USER_ID_7', CURRENT_DATE, 'lunch', 'Salad from cafe', 380, 18, 32, 22, 8, NOW() - INTERVAL '3 hours'),
('USER_ID_7', CURRENT_DATE, 'dinner', 'Takeout Thai food', 620, 28, 85, 22, 4, NOW() - INTERVAL '1 hour'),
-- Previous entries (weeks apart)
('USER_ID_7', CURRENT_DATE - 12, 'breakfast', 'Granola bar', 180, 4, 32, 6, 2, NOW() - INTERVAL '12 days'),
('USER_ID_7', CURRENT_DATE - 12, 'lunch', 'Sandwich', 420, 22, 48, 16, 4, NOW() - INTERVAL '12 days'),
('USER_ID_7', CURRENT_DATE - 25, 'dinner', 'Pizza slice', 320, 15, 38, 12, 2, NOW() - INTERVAL '25 days');

-- Streak Data (Poor consistency)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_7', 'daily', 1, 4, CURRENT_DATE, false,
    NOW() - INTERVAL '90 days', NOW()
);

-- User Goals (Simple, low-commitment goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_7', 'weekly_check_ins', 3, 1, 'sessions', true, NOW() - INTERVAL '30 days', NOW());

-- Achievements (Minimal)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_7', 'warm_up', NOW() - INTERVAL '80 days', true, NOW() - INTERVAL '80 days', NOW());

-- =====================================================
-- PERSONA 8: THE HEALTH-FOCUSED USER
-- Email: health.focused@test.com
-- Profile: Primarily interested in health metrics, weight management
-- =====================================================

INSERT INTO public.profiles (
    id, email, name, age, height, weight, activity_level, fitness_goal,
    experience_level, target_weight, workout_consistency,
    daily_calories_target, daily_steps_target, daily_sleep_target, daily_water_target,
    has_completed_onboarding, device_connected, created_at, updated_at
) VALUES (
    'USER_ID_8', 'health.focused@test.com', 'Dr. Jennifer Walsh', 41, 170, 74,
    'Moderately Active', 'Lose Weight', 'Intermediate', 68, '3-4 times per week',
    1900, 10000, 8.0, 3.0, true, true,
    NOW() - INTERVAL '120 days', NOW()
);

-- Health Metrics (Consistent health monitoring)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, water_intake, created_at, updated_at
) VALUES
-- Daily health tracking
('USER_ID_8', CURRENT_DATE, 11500, 68, 8.2, 420, 8.5, 55, 3.2, NOW(), NOW()),
('USER_ID_8', CURRENT_DATE - 1, 10800, 70, 7.8, 380, 7.8, 50, 3.0, NOW() - INTERVAL '1 day', NOW()),
('USER_ID_8', CURRENT_DATE - 2, 12200, 66, 8.5, 460, 9.2, 65, 3.4, NOW() - INTERVAL '2 days', NOW()),
('USER_ID_8', CURRENT_DATE - 3, 9800, 72, 7.5, 350, 7.2, 45, 2.8, NOW() - INTERVAL '3 days', NOW()),
('USER_ID_8', CURRENT_DATE - 4, 13500, 64, 8.8, 520, 10.5, 75, 3.6, NOW() - INTERVAL '4 days', NOW()),
('USER_ID_8', CURRENT_DATE - 5, 11000, 69, 8.0, 400, 8.0, 52, 3.1, NOW() - INTERVAL '5 days', NOW()),
('USER_ID_8', CURRENT_DATE - 6, 10500, 71, 7.9, 370, 7.5, 48, 2.9, NOW() - INTERVAL '6 days', NOW());

-- Nutrition Entries (Health-conscious, balanced meals)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Balanced, health-focused nutrition
('USER_ID_8', CURRENT_DATE, 'breakfast', 'Steel-cut oats with walnuts', 350, 12, 55, 12, 10, NOW() - INTERVAL '7 hours'),
('USER_ID_8', CURRENT_DATE, 'lunch', 'Mediterranean salad with salmon', 420, 32, 28, 22, 12, NOW() - INTERVAL '4 hours'),
('USER_ID_8', CURRENT_DATE, 'snack', 'Green tea and almonds', 160, 6, 8, 12, 4, NOW() - INTERVAL '2 hours'),
('USER_ID_8', CURRENT_DATE, 'dinner', 'Quinoa bowl with vegetables', 480, 18, 68, 16, 15, NOW() - INTERVAL '1 hour'),
('USER_ID_8', CURRENT_DATE - 1, 'breakfast', 'Greek yogurt with berries', 280, 20, 32, 8, 8, NOW() - INTERVAL '1 day'),
('USER_ID_8', CURRENT_DATE - 1, 'lunch', 'Lentil soup with whole grain bread', 380, 18, 58, 8, 18, NOW() - INTERVAL '1 day'),
('USER_ID_8', CURRENT_DATE - 1, 'dinner', 'Grilled chicken with roasted vegetables', 450, 38, 32, 18, 10, NOW() - INTERVAL '1 day');

-- Streak Data (Moderate consistency focused on health)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'USER_ID_8', 'daily', 23, 45, CURRENT_DATE, true,
    NOW() - INTERVAL '120 days', NOW()
);

-- User Goals (Health and weight management focused)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('USER_ID_8', 'weight_loss', 6, 3.8, 'kg', true, NOW() - INTERVAL '90 days', NOW()),
('USER_ID_8', 'resting_heart_rate', 65, 69, 'bpm', true, NOW() - INTERVAL '60 days', NOW()),
('USER_ID_8', 'daily_fiber', 35, 32, 'grams', true, NOW() - INTERVAL '45 days', NOW()),
('USER_ID_8', 'weekly_meal_prep', 5, 4, 'days', true, NOW() - INTERVAL '30 days', NOW());

-- Achievements (Health-focused milestones)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('USER_ID_8', 'warm_up', NOW() - INTERVAL '115 days', true, NOW() - INTERVAL '115 days', NOW()),
('USER_ID_8', 'no_excuses', NOW() - INTERVAL '112 days', true, NOW() - INTERVAL '112 days', NOW()),
('USER_ID_8', 'sweat_starter', NOW() - INTERVAL '108 days', true, NOW() - INTERVAL '108 days', NOW()),
('USER_ID_8', 'grind_machine', NOW() - INTERVAL '101 days', true, NOW() - INTERVAL '101 days', NOW()),
('USER_ID_8', 'beast_mode', NOW() - INTERVAL '94 days', true, NOW() - INTERVAL '94 days', NOW());

-- Chat Sessions (Health optimization discussions)
INSERT INTO public.chat_sessions (
    id, user_id, session_date, session_number, session_title, session_summary,
    topics_discussed, user_goals_discussed, recommendations_given, user_sentiment,
    message_count, duration_minutes, started_at, ended_at, created_at, updated_at
) VALUES
(gen_random_uuid(), 'USER_ID_8', CURRENT_DATE - 5, 1, 'Heart Rate Zones',
 'Discussed optimal heart rate zones for fat burning and cardiovascular health',
 ARRAY['heart rate training', 'fat burning', 'cardiovascular health'],
 'Improve cardiovascular health while losing weight safely',
 'Train in Zone 2 (60-70% max HR) for fat burning, monitor resting HR trends',
 'positive', 20, 18, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '18 minutes',
 NOW() - INTERVAL '5 days', NOW());

-- =====================================================
-- SUMMARY AND VERIFICATION
-- =====================================================

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ COMPREHENSIVE TEST DATA CREATED!';
    RAISE NOTICE '';
    RAISE NOTICE '👥 User Personas Created:';
    RAISE NOTICE '   1. Elite Athlete (400+ day streak, advanced training)';
    RAISE NOTICE '   2. Busy Professional (inconsistent, meal prep focused)';
    RAISE NOTICE '   3. Weekend Warrior (weekend spikes, weekday lows)';
    RAISE NOTICE '   4. New Beginner (just started, learning basics)';
    RAISE NOTICE '   5. Comeback Hero (rebuilding after losing long streak)';
    RAISE NOTICE '   6. Data Enthusiast (tracks everything precisely)';
    RAISE NOTICE '   7. Casual User (sporadic usage, simple goals)';
    RAISE NOTICE '   8. Health-Focused (medical/wellness oriented)';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Data Coverage:';
    RAISE NOTICE '   • Profiles with diverse demographics and goals';
    RAISE NOTICE '   • Health metrics showing different activity patterns';
    RAISE NOTICE '   • Nutrition entries from simple to detailed tracking';
    RAISE NOTICE '   • Streaks ranging from 0 to 400+ days';
    RAISE NOTICE '   • Goals covering fitness, nutrition, and health metrics';
    RAISE NOTICE '   • Achievements from beginner to elite levels';
    RAISE NOTICE '   • Chat sessions showing AI coaching interactions';
    RAISE NOTICE '';
    RAISE NOTICE '🔗 Next Steps:';
    RAISE NOTICE '   1. Replace USER_ID_X placeholders with actual UUIDs';
    RAISE NOTICE '   2. Test app functionality with each persona';
    RAISE NOTICE '   3. Verify data relationships and constraints';
    RAISE NOTICE '   4. Use for comprehensive feature testing';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Perfect for testing:';
    RAISE NOTICE '   • Streak calculations and edge cases';
    RAISE NOTICE '   • Achievement unlocking logic';
    RAISE NOTICE '   • Nutrition tracking variations';
    RAISE NOTICE '   • Goal progress calculations';
    RAISE NOTICE '   • AI coaching context building';
    RAISE NOTICE '   • User onboarding flows';
    RAISE NOTICE '   • Data visualization components';
    RAISE NOTICE '   • Performance with different usage patterns';
END $$;

-- =====================================================
-- END OF COMPREHENSIVE TEST DATA SCRIPT
-- =====================================================