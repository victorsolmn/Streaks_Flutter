-- ================================================
-- CORRECTED TEST DATA PERSONAS FOR STREAKS FLUTTER APP
-- ================================================
-- Date: September 19, 2025
-- Based on ACTUAL Supabase schema analysis
--
-- IMPORTANT: First create these user accounts through the app's sign-up flow:
-- 1. consistent@test.com - password: Test123!
-- 2. comeback@test.com - password: Test123!
-- 3. weekend@test.com - password: Test123!
-- 4. beginner@test.com - password: Test123!
-- 5. veteran@test.com - password: Test123!
-- 6. irregular@test.com - password: Test123!
-- 7. dataenthusiast@test.com - password: Test123!
--
-- After creating accounts, run this SQL to populate test data
-- ================================================

-- First, get the user IDs (you'll need to replace these with actual IDs after signup)
-- Run this query first to get the actual user IDs:
SELECT id, email FROM auth.users WHERE email IN (
    'consistent@test.com',
    'comeback@test.com',
    'weekend@test.com',
    'beginner@test.com',
    'veteran@test.com',
    'irregular@test.com',
    'dataenthusiast@test.com'
);

-- ================================================
-- PERSONA 1: THE CONSISTENT ACHIEVER (7-day streak)
-- Email: consistent@test.com
-- ================================================
-- Replace 'USER_ID_1' with actual UUID from above query

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_1', 'Alex Johnson', 'consistent@test.com', true, 28, 175.0, 75.0,
    'Moderately Active', 'Lose Weight', 'Intermediate', 72.0,
    '5-6 times per week', 2500, 10000, 8.0, 8,
    false, NOW() - INTERVAL '10 days', NOW()
);

-- Health metrics for the last 7 days
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Day 1 (7 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 12500, 350, 8.2, 8, 1, 2480, 155, 305, 78, 75.0, 10000, 2500, 8.0, 8, 150, true, true, true, true, true, true, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
-- Day 2 (6 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 11800, 280, 7.8, 9, 1, 2520, 148, 295, 82, 74.8, 10000, 2500, 8.0, 8, 150, true, true, false, true, true, false, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
-- Day 3 (5 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 13200, 420, 8.5, 7, 1, 2450, 162, 315, 75, 74.6, 10000, 2500, 8.0, 8, 150, true, true, true, false, true, false, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
-- Day 4 (4 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 10800, 250, 8.0, 8, 1, 2580, 145, 335, 85, 74.4, 10000, 2500, 8.0, 8, 150, true, true, true, true, false, false, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
-- Day 5 (3 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 12000, 380, 8.3, 8, 1, 2470, 158, 290, 80, 74.2, 10000, 2500, 8.0, 8, 150, true, true, true, true, true, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
-- Day 6 (2 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 11500, 320, 7.9, 9, 1, 2490, 152, 300, 82, 74.0, 10000, 2500, 8.0, 8, 150, true, true, false, true, true, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
-- Day 7 (yesterday)
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 13500, 450, 8.4, 8, 1, 2510, 165, 310, 78, 73.8, 10000, 2500, 8.0, 8, 150, true, true, true, true, true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Nutrition entries for last 7 days
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Day 1 (7 days ago)
('USER_ID_1', 'Oatmeal with berries', 350, 12, 65, 8, 8, 200, 'breakfast', 'manual', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('USER_ID_1', 'Grilled chicken salad', 450, 40, 25, 18, 5, 300, 'lunch', 'manual', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('USER_ID_1', 'Protein shake', 200, 25, 10, 5, 2, 250, 'snack', 'manual', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('USER_ID_1', 'Salmon with quinoa', 550, 45, 50, 20, 6, 350, 'dinner', 'manual', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
-- Day 2 (6 days ago)
('USER_ID_1', 'Eggs and toast', 380, 20, 30, 18, 3, 200, 'breakfast', 'manual', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('USER_ID_1', 'Turkey sandwich', 420, 35, 45, 12, 4, 250, 'lunch', 'manual', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('USER_ID_1', 'Greek yogurt', 150, 15, 20, 3, 0, 170, 'snack', 'manual', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('USER_ID_1', 'Stir fry with tofu', 480, 28, 55, 18, 7, 400, 'dinner', 'manual', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days');

-- Streaks record
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_1', 7, 7, 7, 0, 0, 2,
    CURRENT_DATE - INTERVAL '7 days', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day',
    87500, 2450, 7, 8.1, 1, 0,
    NOW() - INTERVAL '7 days', NOW()
);

-- User achievements (7-day streak achievement)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at)
VALUES ('USER_ID_1', 'warm_up', NOW() - INTERVAL '1 day', false, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Achievement progress
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_1', 'warm_up', 7, 7, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_1', 'no_excuses', 7, 14, NOW(), NOW()),
('USER_ID_1', 'sweat_starter', 7, 21, NOW(), NOW());

-- ================================================
-- PERSONA 2: THE COMEBACK KID (Lost streak, restarted)
-- Email: comeback@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_2', 'Sarah Martinez', 'comeback@test.com', true, 32, 165.0, 68.0,
    'Lightly Active', 'Lose Weight', 'Beginner', 65.0,
    '3-4 times per week', 2000, 8000, 8.0, 8,
    false, NOW() - INTERVAL '15 days', NOW()
);

-- Health metrics (2 days consistent, gap, then 2 days restart)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Initial streak (10-9 days ago)
('USER_ID_2', CURRENT_DATE - INTERVAL '10 days', 8500, 200, 7.5, 6, 1, 1980, 95, 245, 65, 68.0, 8000, 2000, 8.0, 8, 100, true, true, false, false, false, false, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '9 days', 9200, 250, 7.8, 7, 1, 2020, 105, 255, 68, 67.8, 8000, 2000, 8.0, 8, 100, true, true, false, false, true, false, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days'),
-- Gap (missed days)
-- Restart (2-1 days ago)
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 8800, 220, 7.2, 8, 1, 1950, 98, 240, 62, 67.5, 8000, 2000, 8.0, 8, 100, true, true, false, true, false, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '1 day', 9500, 280, 8.1, 8, 1, 2010, 108, 250, 65, 67.3, 8000, 2000, 8.0, 8, 100, true, true, true, true, true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Nutrition entries (sporadic pattern)
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- First streak
('USER_ID_2', 'Cereal with milk', 320, 10, 55, 8, 3, 150, 'breakfast', 'manual', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('USER_ID_2', 'Salad with chicken', 380, 35, 25, 15, 4, 250, 'lunch', 'manual', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('USER_ID_2', 'Pasta primavera', 450, 15, 70, 12, 5, 300, 'dinner', 'manual', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
-- Restart period
('USER_ID_2', 'Smoothie', 280, 15, 45, 8, 6, 300, 'breakfast', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_2', 'Quinoa bowl', 420, 18, 55, 15, 8, 350, 'lunch', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_2', 'Chicken stir-fry', 520, 40, 45, 20, 6, 400, 'dinner', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days');

-- Streaks record (comeback story)
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_2', 2, 2, 4, 0, 0, 2,
    CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day',
    36000, 950, 4, 7.6, 0, 0,
    NOW() - INTERVAL '10 days', NOW()
);

-- Achievement progress (working toward first achievement)
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_2', 'warm_up', 2, 7, NOW(), NOW());

-- ================================================
-- PERSONA 3: THE WEEKEND WARRIOR (Active on weekends only)
-- Email: weekend@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_3', 'Mike Chen', 'weekend@test.com', true, 35, 180.0, 82.0,
    'Lightly Active', 'Maintain Weight', 'Intermediate', 78.0,
    '1-2 times per week', 2300, 8000, 7.5, 6,
    false, NOW() - INTERVAL '30 days', NOW()
);

-- Health metrics (weekend only)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Last weekend
('USER_ID_3', CURRENT_DATE - INTERVAL '3 days', 15000, 650, 8.5, 6, 1, 2280, 120, 285, 75, 82.0, 8000, 2300, 7.5, 6, 120, true, true, true, true, true, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '2 days', 12000, 500, 9.0, 5, 1, 2350, 125, 295, 78, 81.8, 8000, 2300, 7.5, 6, 120, true, true, true, false, true, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
-- Previous weekend
('USER_ID_3', CURRENT_DATE - INTERVAL '10 days', 14500, 800, 8.0, 4, 1, 2400, 130, 300, 80, 82.2, 8000, 2300, 7.5, 6, 120, true, true, true, false, true, false, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '9 days', 11000, 450, 8.8, 6, 1, 2250, 115, 280, 72, 82.0, 8000, 2300, 7.5, 6, 120, true, true, true, true, false, false, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days');

-- Nutrition entries (weekend focus)
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Last weekend
('USER_ID_3', 'Pancakes', 480, 12, 85, 12, 2, 200, 'breakfast', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_3', 'Burger and fries', 850, 35, 85, 40, 4, 400, 'lunch', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_3', 'Pizza', 680, 28, 80, 28, 3, 300, 'dinner', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_3', 'Bacon and eggs', 420, 25, 5, 35, 0, 150, 'breakfast', 'manual', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('USER_ID_3', 'Steak dinner', 720, 55, 40, 35, 2, 350, 'dinner', 'manual', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

-- Streaks record (poor consistency)
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_3', 0, 2, 4, 5, 1, 1,
    CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE - INTERVAL '2 days',
    52500, 2400, 4, 8.3, 0, 0,
    NOW() - INTERVAL '30 days', NOW()
);

-- ================================================
-- PERSONA 4: THE BEGINNER (Just started 3 days ago)
-- Email: beginner@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_4', 'Emma Wilson', 'beginner@test.com', true, 24, 160.0, 58.0,
    'Sedentary', 'Lose Weight', 'Beginner', 55.0,
    '1-2 times per week', 1800, 6000, 8.0, 8,
    false, NOW() - INTERVAL '3 days', NOW()
);

-- Health metrics (just 3 days)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Day 1 (3 days ago) - incomplete logging
('USER_ID_4', CURRENT_DATE - INTERVAL '3 days', 4500, 100, 7.0, 4, 0, 1200, 45, 150, 30, 58.0, 6000, 1800, 8.0, 8, 90, false, false, false, false, false, false, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
-- Day 2 (2 days ago) - better
('USER_ID_4', CURRENT_DATE - INTERVAL '2 days', 6500, 150, 7.8, 6, 1, 1750, 85, 220, 45, 57.8, 6000, 1800, 8.0, 8, 90, true, true, false, false, false, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
-- Day 3 (yesterday) - good day
('USER_ID_4', CURRENT_DATE - INTERVAL '1 day', 7200, 180, 8.2, 8, 0, 1820, 92, 235, 48, 57.6, 6000, 1800, 8.0, 8, 90, true, true, true, true, true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Nutrition entries (learning pattern)
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Day 1 - minimal logging
('USER_ID_4', 'Granola bar', 150, 3, 25, 5, 2, 35, 'snack', 'manual', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('USER_ID_4', 'Caesar salad', 320, 15, 20, 20, 3, 200, 'lunch', 'manual', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
-- Day 2 - more complete
('USER_ID_4', 'Yogurt', 120, 10, 15, 3, 0, 170, 'breakfast', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_4', 'Chicken wrap', 380, 25, 40, 15, 4, 250, 'lunch', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_4', 'Spaghetti', 450, 15, 65, 15, 3, 300, 'dinner', 'manual', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
-- Day 3 - good logging
('USER_ID_4', 'Toast and coffee', 180, 5, 30, 5, 2, 100, 'breakfast', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_4', 'Soup', 250, 12, 35, 8, 4, 300, 'lunch', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_4', 'Fruit', 80, 1, 20, 0, 3, 150, 'snack', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_4', 'Grilled chicken', 380, 40, 15, 18, 0, 200, 'dinner', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Streaks record (just started)
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_4', 1, 1, 1, 0, 0, 2,
    CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day',
    18200, 430, 1, 7.7, 0, 0,
    NOW() - INTERVAL '3 days', NOW()
);

-- Achievement progress (just starting)
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_4', 'warm_up', 1, 7, NOW(), NOW());

-- ================================================
-- PERSONA 5: THE VETERAN (365+ day streak)
-- Email: veteran@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_5', 'David Thompson', 'veteran@test.com', true, 42, 185.0, 85.0,
    'Very Active', 'Build Strength', 'Advanced', 82.0,
    'Daily', 3000, 12000, 8.0, 10,
    true, NOW() - INTERVAL '400 days', NOW()
);

-- Health metrics (recent days showing consistency)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Recent perfect days
('USER_ID_5', CURRENT_DATE, 15000, 550, 8.2, 12, 1, 2980, 185, 345, 98, 84.8, 12000, 3000, 8.0, 10, 180, true, true, true, true, true, true, NOW(), NOW()),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 14500, 480, 8.1, 11, 1, 3020, 190, 350, 95, 84.9, 12000, 3000, 8.0, 10, 180, true, true, true, true, true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '2 days', 16000, 620, 8.3, 10, 1, 2950, 182, 340, 102, 85.0, 12000, 3000, 8.0, 10, 180, true, true, true, true, true, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '3 days', 13800, 420, 7.9, 12, 1, 3080, 195, 365, 100, 85.1, 12000, 3000, 8.0, 10, 180, true, true, false, true, true, false, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '4 days', 15500, 580, 8.4, 11, 1, 2970, 188, 355, 96, 85.2, 12000, 3000, 8.0, 10, 180, true, true, true, true, true, true, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days');

-- Nutrition entries (detailed veteran logging)
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Today
('USER_ID_5', 'Protein pancakes', 420, 35, 45, 12, 5, 200, 'breakfast', 'manual', NOW(), NOW()),
('USER_ID_5', 'Pre-workout shake', 150, 20, 15, 2, 1, 250, 'snack', 'manual', NOW(), NOW()),
('USER_ID_5', 'Chicken and rice', 580, 50, 65, 15, 3, 400, 'lunch', 'manual', NOW(), NOW()),
('USER_ID_5', 'Recovery shake', 280, 40, 25, 3, 0, 300, 'snack', 'manual', NOW(), NOW()),
('USER_ID_5', 'Steak and vegetables', 620, 55, 30, 28, 8, 350, 'dinner', 'manual', NOW(), NOW()),
('USER_ID_5', 'Cottage cheese', 180, 20, 10, 8, 0, 200, 'snack', 'manual', NOW(), NOW()),
-- Yesterday
('USER_ID_5', 'Eggs and oatmeal', 480, 30, 55, 18, 6, 250, 'breakfast', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_5', 'Tuna sandwich', 420, 40, 40, 12, 4, 300, 'lunch', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_5', 'Protein bar', 250, 25, 25, 8, 3, 60, 'snack', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_5', 'Salmon and quinoa', 580, 48, 55, 20, 5, 400, 'dinner', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

-- Impressive streak
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_5', 368, 368, 380, 0, 0, 2,
    CURRENT_DATE - INTERVAL '368 days', CURRENT_DATE, CURRENT_DATE,
    5520000, 184000, 380, 8.2, 52, 12,
    NOW() - INTERVAL '400 days', NOW()
);

-- Multiple achievements unlocked
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at)
VALUES
('USER_ID_5', 'warm_up', NOW() - INTERVAL '361 days', true, NOW() - INTERVAL '361 days', NOW() - INTERVAL '361 days'),
('USER_ID_5', 'no_excuses', NOW() - INTERVAL '354 days', true, NOW() - INTERVAL '354 days', NOW() - INTERVAL '354 days'),
('USER_ID_5', 'sweat_starter', NOW() - INTERVAL '347 days', true, NOW() - INTERVAL '347 days', NOW() - INTERVAL '347 days'),
('USER_ID_5', 'grind_machine', NOW() - INTERVAL '340 days', true, NOW() - INTERVAL '340 days', NOW() - INTERVAL '340 days'),
('USER_ID_5', 'beast_mode', NOW() - INTERVAL '318 days', true, NOW() - INTERVAL '318 days', NOW() - INTERVAL '318 days'),
('USER_ID_5', 'iron_month', NOW() - INTERVAL '278 days', true, NOW() - INTERVAL '278 days', NOW() - INTERVAL '278 days'),
('USER_ID_5', 'quarter_crusher', NOW() - INTERVAL '188 days', true, NOW() - INTERVAL '188 days', NOW() - INTERVAL '188 days'),
('USER_ID_5', 'half_year', NOW() - INTERVAL '3 days', true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('USER_ID_5', 'year_one', NOW() - INTERVAL '3 days', false, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

-- Achievement progress for veteran
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_5', 'streak_titan', 368, 500, NOW(), NOW()),
('USER_ID_5', 'immortal', 368, 1000, NOW(), NOW());

-- ================================================
-- PERSONA 6: THE IRREGULAR USER (Sporadic usage)
-- Email: irregular@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_6', 'Lisa Brown', 'irregular@test.com', true, 29, 168.0, 62.0,
    'Lightly Active', 'Improve Fitness', 'Beginner', 60.0,
    'Rarely', 2100, 7000, 7.5, 6,
    false, NOW() - INTERVAL '60 days', NOW()
);

-- Health metrics (sporadic entries)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Random entries over time
('USER_ID_6', CURRENT_DATE - INTERVAL '1 day', 6500, 180, 6.5, 5, 1, 1950, 85, 235, 60, 62.0, 7000, 2100, 7.5, 6, 105, false, true, false, false, false, false, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - INTERVAL '7 days', 5200, 120, 7.0, 4, 0, 1800, 70, 210, 55, 62.2, 7000, 2100, 7.5, 6, 105, false, false, false, false, false, false, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('USER_ID_6', CURRENT_DATE - INTERVAL '21 days', 8000, 200, 8.0, 7, 1, 2080, 95, 250, 65, 62.5, 7000, 2100, 7.5, 6, 105, true, true, true, true, false, false, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('USER_ID_6', CURRENT_DATE - INTERVAL '35 days', 4800, 100, 6.8, 3, 0, 1600, 60, 180, 45, 62.8, 7000, 2100, 7.5, 6, 105, false, false, false, false, false, false, NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days');

-- Sparse nutrition entries
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Random entries over time
('USER_ID_6', 'Smoothie', 320, 15, 50, 8, 4, 300, 'breakfast', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_6', 'Wrap', 450, 30, 45, 20, 5, 250, 'lunch', 'manual', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_6', 'Sandwich', 420, 20, 45, 18, 3, 200, 'lunch', 'manual', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('USER_ID_6', 'Salad', 350, 25, 30, 15, 6, 300, 'lunch', 'manual', NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days');

-- Streaks record (poor consistency)
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_6', 1, 3, 4, 6, 2, 0,
    CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE - INTERVAL '1 day',
    24500, 600, 2, 7.1, 0, 0,
    NOW() - INTERVAL '60 days', NOW()
);

-- Minimal achievement progress
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_6', 'warm_up', 1, 7, NOW(), NOW());

-- ================================================
-- PERSONA 7: THE DATA ENTHUSIAST (Logs everything meticulously)
-- Email: dataenthusiast@test.com
-- ================================================

-- Profile
INSERT INTO public.profiles (
    id, name, email, has_completed_onboarding, age, height, weight,
    activity_level, fitness_goal, experience_level, target_weight,
    workout_consistency, daily_calories_target, daily_steps_target,
    daily_sleep_target, daily_water_target, device_connected,
    created_at, updated_at
) VALUES (
    'USER_ID_7', 'Robert Kim', 'dataenthusiast@test.com', true, 31, 178.0, 77.0,
    'Moderately Active', 'Lose Weight', 'Advanced', 75.0,
    '5-6 times per week', 2600, 11000, 8.0, 9,
    true, NOW() - INTERVAL '45 days', NOW()
);

-- Health metrics (perfect detailed tracking)
INSERT INTO public.health_metrics (
    user_id, date, steps, calories_burned, sleep_hours, water_glasses, workouts,
    calories_consumed, protein, carbs, fat, weight, steps_goal, calories_goal,
    sleep_goal, water_goal, protein_goal, steps_achieved, calories_achieved,
    sleep_achieved, water_achieved, nutrition_achieved, all_goals_achieved,
    created_at, updated_at
) VALUES
-- Perfect tracking days
('USER_ID_7', CURRENT_DATE, 11500, 420, 8.1, 9, 1, 2587, 142, 320, 85, 76.8, 11000, 2600, 8.0, 9, 140, true, true, true, true, true, true, NOW(), NOW()),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 12200, 380, 8.3, 10, 1, 2610, 145, 315, 88, 76.9, 11000, 2600, 8.0, 9, 140, true, true, true, true, true, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '2 days', 10800, 450, 7.9, 8, 1, 2580, 138, 325, 82, 77.0, 11000, 2600, 8.0, 9, 140, false, true, false, false, false, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('USER_ID_7', CURRENT_DATE - INTERVAL '3 days', 11800, 350, 8.2, 9, 1, 2620, 148, 310, 90, 77.1, 11000, 2600, 8.0, 9, 140, true, true, true, true, true, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

-- Detailed nutrition entries (logs everything)
INSERT INTO public.nutrition_entries (
    user_id, food_name, calories, protein, carbs, fat, fiber, quantity_grams,
    meal_type, food_source, created_at, updated_at
) VALUES
-- Today (extremely detailed)
('USER_ID_7', '2 whole eggs, scrambled', 140, 12, 2, 10, 0, 100, 'breakfast', 'manual', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),
('USER_ID_7', '2 slices whole wheat toast', 160, 6, 30, 2, 4, 60, 'breakfast', 'manual', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),
('USER_ID_7', '1 medium banana', 105, 1, 27, 0, 3, 120, 'breakfast', 'manual', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),
('USER_ID_7', 'Black coffee', 5, 0, 1, 0, 0, 240, 'breakfast', 'manual', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),
('USER_ID_7', 'Whey protein shake (30g)', 120, 25, 3, 1, 0, 250, 'snack', 'manual', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
('USER_ID_7', '1 medium apple', 95, 0, 25, 0, 4, 180, 'snack', 'manual', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
('USER_ID_7', '150g grilled chicken breast', 248, 46, 0, 6, 0, 150, 'lunch', 'manual', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
('USER_ID_7', '200g brown rice, cooked', 218, 5, 45, 2, 3, 200, 'lunch', 'manual', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
('USER_ID_7', 'Mixed vegetables (100g)', 35, 2, 7, 0, 3, 100, 'lunch', 'manual', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
('USER_ID_7', '1 tbsp olive oil', 120, 0, 0, 14, 0, 15, 'lunch', 'manual', NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),
('USER_ID_7', '28g almonds', 164, 6, 6, 14, 4, 28, 'snack', 'manual', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'),
('USER_ID_7', '170g salmon fillet', 354, 40, 0, 20, 0, 170, 'dinner', 'manual', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'),
('USER_ID_7', '200g sweet potato', 180, 4, 41, 0, 6, 200, 'dinner', 'manual', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'),
('USER_ID_7', 'Green salad with dressing', 120, 2, 8, 9, 3, 150, 'dinner', 'manual', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour');

-- Consistent streak
INSERT INTO public.streaks (
    user_id, current_streak, longest_streak, total_days_completed,
    consecutive_missed_days, grace_days_used, grace_days_available,
    streak_start_date, last_completed_date, last_checked_date,
    total_steps, total_calories_burned, total_workouts, average_sleep,
    perfect_weeks, perfect_months, created_at, updated_at
) VALUES (
    'USER_ID_7', 42, 42, 42, 0, 0, 2,
    CURRENT_DATE - INTERVAL '42 days', CURRENT_DATE, CURRENT_DATE,
    462000, 16800, 36, 8.1, 6, 1,
    NOW() - INTERVAL '42 days', NOW()
);

-- Multiple achievements unlocked
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at)
VALUES
('USER_ID_7', 'warm_up', NOW() - INTERVAL '35 days', true, NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('USER_ID_7', 'no_excuses', NOW() - INTERVAL '28 days', true, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('USER_ID_7', 'sweat_starter', NOW() - INTERVAL '21 days', true, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('USER_ID_7', 'grind_machine', NOW() - INTERVAL '12 days', false, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days');

-- Achievement progress
INSERT INTO public.achievement_progress (user_id, achievement_id, current_value, target_value, last_updated, created_at)
VALUES
('USER_ID_7', 'beast_mode', 42, 50, NOW(), NOW()),
('USER_ID_7', 'iron_month', 42, 90, NOW(), NOW());

-- ================================================
-- FINAL NOTES
-- ================================================
-- 1. First create the user accounts through your app's sign-up flow
-- 2. Get the actual user IDs from Supabase Auth
-- 3. Replace all 'USER_ID_X' placeholders with the actual UUIDs
-- 4. Run this SQL in your Supabase SQL Editor
-- 5. Test each persona by logging in with their credentials:
--    - consistent@test.com - 7-day streak achiever
--    - comeback@test.com - Lost streak, restarting
--    - weekend@test.com - Weekend-only user
--    - beginner@test.com - Just started 3 days ago
--    - veteran@test.com - 368-day streak legend
--    - irregular@test.com - Sporadic usage
--    - dataenthusiast@test.com - Logs everything in detail