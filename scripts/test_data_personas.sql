-- ================================================
-- TEST DATA PERSONAS FOR STREAKS FLUTTER APP
-- ================================================
-- Date: September 19, 2025
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

-- First, let's get the user IDs (you'll need to replace these with actual IDs after signup)
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
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_1', 'consistent@test.com', 'Alex Johnson', 28, 175, 75, 'moderate', 72, 2500, 150, 300, 80, NOW() - INTERVAL '10 days', NOW());

-- Nutrition entries for last 7 days
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Day 1 (7 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 'breakfast', 'Oatmeal with berries', 350, 12, 65, 8, NOW() - INTERVAL '7 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 'lunch', 'Grilled chicken salad', 450, 40, 25, 18, NOW() - INTERVAL '7 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 'snack', 'Protein shake', 200, 25, 10, 5, NOW() - INTERVAL '7 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 'dinner', 'Salmon with quinoa', 550, 45, 50, 20, NOW() - INTERVAL '7 days'),
-- Day 2 (6 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 'breakfast', 'Eggs and toast', 380, 20, 30, 18, NOW() - INTERVAL '6 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 'lunch', 'Turkey sandwich', 420, 35, 45, 12, NOW() - INTERVAL '6 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 'snack', 'Greek yogurt', 150, 15, 20, 3, NOW() - INTERVAL '6 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 'dinner', 'Stir fry with tofu', 480, 28, 55, 18, NOW() - INTERVAL '6 days'),
-- Day 3 (5 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 'breakfast', 'Smoothie bowl', 420, 15, 70, 12, NOW() - INTERVAL '5 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 'lunch', 'Chicken burrito bowl', 580, 42, 65, 18, NOW() - INTERVAL '5 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 'snack', 'Apple with peanut butter', 200, 7, 25, 10, NOW() - INTERVAL '5 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 'dinner', 'Pasta with meat sauce', 620, 38, 75, 22, NOW() - INTERVAL '5 days'),
-- Day 4 (4 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 'breakfast', 'Pancakes', 450, 12, 80, 12, NOW() - INTERVAL '4 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 'lunch', 'Tuna salad', 380, 35, 20, 18, NOW() - INTERVAL '4 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 'snack', 'Trail mix', 180, 6, 20, 10, NOW() - INTERVAL '4 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 'dinner', 'Grilled steak with vegetables', 550, 50, 25, 28, NOW() - INTERVAL '4 days'),
-- Day 5 (3 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 'breakfast', 'Avocado toast', 380, 10, 40, 22, NOW() - INTERVAL '3 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 'lunch', 'Soup and sandwich', 450, 25, 55, 15, NOW() - INTERVAL '3 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 'snack', 'Protein bar', 220, 20, 25, 8, NOW() - INTERVAL '3 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 'dinner', 'Fish tacos', 520, 38, 45, 22, NOW() - INTERVAL '3 days'),
-- Day 6 (2 days ago)
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 'breakfast', 'French toast', 420, 14, 65, 15, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 'lunch', 'Caesar salad with chicken', 480, 40, 25, 25, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 'snack', 'Banana and nuts', 180, 5, 30, 7, NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 'dinner', 'BBQ chicken with rice', 580, 45, 60, 18, NOW() - INTERVAL '2 days'),
-- Day 7 (yesterday)
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 'breakfast', 'Breakfast burrito', 480, 22, 50, 22, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Poke bowl', 520, 40, 55, 18, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Hummus and veggies', 150, 6, 20, 8, NOW() - INTERVAL '1 day'),
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 'dinner', 'Chicken parmesan', 620, 48, 55, 25, NOW() - INTERVAL '1 day'),
-- Today
('USER_ID_1', CURRENT_DATE, 'breakfast', 'Yogurt parfait', 320, 18, 45, 10, NOW()),
('USER_ID_1', CURRENT_DATE, 'lunch', 'Veggie wrap', 420, 15, 55, 18, NOW());

-- Streaks
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_1', 7, 7, CURRENT_DATE, 7, NOW() - INTERVAL '7 days', NOW());

-- Workouts for last 7 days
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_1', CURRENT_DATE - INTERVAL '7 days', 'cardio', 30, 350, 'Morning run', NOW() - INTERVAL '7 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '6 days', 'strength', 45, 280, 'Upper body workout', NOW() - INTERVAL '6 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '5 days', 'cardio', 35, 400, 'Cycling', NOW() - INTERVAL '5 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '4 days', 'strength', 40, 250, 'Leg day', NOW() - INTERVAL '4 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '3 days', 'flexibility', 30, 100, 'Yoga session', NOW() - INTERVAL '3 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '2 days', 'cardio', 45, 450, 'Swimming', NOW() - INTERVAL '2 days'),
('USER_ID_1', CURRENT_DATE - INTERVAL '1 day', 'strength', 50, 320, 'Full body workout', NOW() - INTERVAL '1 day');

-- User Goals
INSERT INTO public.user_goals (user_id, goal_type, target_value, current_value, deadline, is_active, created_at)
VALUES
('USER_ID_1', 'weight_loss', 3, 1.5, CURRENT_DATE + INTERVAL '30 days', true, NOW() - INTERVAL '7 days'),
('USER_ID_1', 'daily_calories', 2500, 2450, CURRENT_DATE, true, NOW() - INTERVAL '7 days'),
('USER_ID_1', 'weekly_workouts', 5, 7, CURRENT_DATE + INTERVAL '7 days', true, NOW() - INTERVAL '7 days');

-- User Achievements (7-day streak achievement)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, progress, created_at)
VALUES
('USER_ID_1', 'warm_up', NOW() - INTERVAL '1 day', 100, NOW() - INTERVAL '1 day');

-- ================================================
-- PERSONA 2: THE COMEBACK KID (Lost streak, restarted)
-- Email: comeback@test.com
-- ================================================
-- Replace 'USER_ID_2' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_2', 'comeback@test.com', 'Sarah Martinez', 32, 165, 68, 'light', 65, 2000, 100, 250, 65, NOW() - INTERVAL '15 days', NOW());

-- Nutrition entries (consistent for 2 days, missed 3 days, restarted 2 days ago)
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- First streak (10 days ago - 2 days)
('USER_ID_2', CURRENT_DATE - INTERVAL '10 days', 'breakfast', 'Cereal with milk', 320, 10, 55, 8, NOW() - INTERVAL '10 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '10 days', 'lunch', 'Salad with grilled chicken', 380, 35, 25, 15, NOW() - INTERVAL '10 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '10 days', 'dinner', 'Pasta primavera', 450, 15, 70, 12, NOW() - INTERVAL '10 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '9 days', 'breakfast', 'Toast with jam', 280, 6, 50, 6, NOW() - INTERVAL '9 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '9 days', 'lunch', 'Turkey wrap', 420, 30, 45, 18, NOW() - INTERVAL '9 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '9 days', 'dinner', 'Grilled fish with rice', 480, 38, 50, 15, NOW() - INTERVAL '9 days'),
-- Gap of 3-4 days (missed streak)
-- Restart (2 days ago)
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 'breakfast', 'Smoothie', 280, 15, 45, 8, NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 'lunch', 'Quinoa bowl', 420, 18, 55, 15, NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 'snack', 'Apple', 80, 0, 20, 0, NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 'dinner', 'Chicken stir-fry', 520, 40, 45, 20, NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '1 day', 'breakfast', 'Omelette', 320, 25, 5, 22, NOW() - INTERVAL '1 day'),
('USER_ID_2', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Soup and bread', 380, 15, 50, 12, NOW() - INTERVAL '1 day'),
('USER_ID_2', CURRENT_DATE - INTERVAL '1 day', 'dinner', 'Beef tacos', 550, 35, 50, 25, NOW() - INTERVAL '1 day');

-- Streaks (current: 2, longest: 2)
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_2', 2, 2, CURRENT_DATE - INTERVAL '1 day', 4, NOW() - INTERVAL '10 days', NOW());

-- Workouts (sporadic)
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_2', CURRENT_DATE - INTERVAL '10 days', 'cardio', 25, 200, 'Treadmill', NOW() - INTERVAL '10 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '9 days', 'flexibility', 20, 80, 'Stretching', NOW() - INTERVAL '9 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '2 days', 'cardio', 30, 250, 'Elliptical', NOW() - INTERVAL '2 days'),
('USER_ID_2', CURRENT_DATE - INTERVAL '1 day', 'strength', 35, 180, 'Light weights', NOW() - INTERVAL '1 day');

-- User Goals
INSERT INTO public.user_goals (user_id, goal_type, target_value, current_value, deadline, is_active, created_at)
VALUES
('USER_ID_2', 'weight_loss', 3, 0.5, CURRENT_DATE + INTERVAL '45 days', true, NOW() - INTERVAL '10 days'),
('USER_ID_2', 'daily_calories', 2000, 1800, CURRENT_DATE, true, NOW() - INTERVAL '2 days');

-- ================================================
-- PERSONA 3: THE WEEKEND WARRIOR (Active on weekends only)
-- Email: weekend@test.com
-- ================================================
-- Replace 'USER_ID_3' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_3', 'weekend@test.com', 'Mike Chen', 35, 180, 82, 'light', 78, 2300, 120, 280, 75, NOW() - INTERVAL '30 days', NOW());

-- Nutrition entries (mainly weekends)
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Last weekend (2 days ago - Sunday)
('USER_ID_3', CURRENT_DATE - INTERVAL '2 days', 'breakfast', 'Pancakes', 480, 12, 85, 12, NOW() - INTERVAL '2 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '2 days', 'lunch', 'Burger and fries', 850, 35, 85, 40, NOW() - INTERVAL '2 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '2 days', 'dinner', 'Pizza', 680, 28, 80, 28, NOW() - INTERVAL '2 days'),
-- Saturday (3 days ago)
('USER_ID_3', CURRENT_DATE - INTERVAL '3 days', 'breakfast', 'Bacon and eggs', 420, 25, 5, 35, NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '3 days', 'lunch', 'Sandwich', 480, 25, 50, 20, NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '3 days', 'dinner', 'Steak dinner', 720, 55, 40, 35, NOW() - INTERVAL '3 days'),
-- Previous weekend (9-10 days ago)
('USER_ID_3', CURRENT_DATE - INTERVAL '9 days', 'breakfast', 'Waffles', 380, 8, 65, 12, NOW() - INTERVAL '9 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '9 days', 'lunch', 'Chinese takeout', 620, 25, 75, 25, NOW() - INTERVAL '9 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '10 days', 'breakfast', 'Continental breakfast', 450, 15, 60, 18, NOW() - INTERVAL '10 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '10 days', 'dinner', 'BBQ ribs', 780, 45, 50, 45, NOW() - INTERVAL '10 days');

-- Streaks (very low due to weekend-only activity)
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_3', 0, 2, CURRENT_DATE - INTERVAL '2 days', 6, NOW() - INTERVAL '30 days', NOW());

-- Workouts (weekend only)
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_3', CURRENT_DATE - INTERVAL '2 days', 'sports', 90, 650, 'Basketball game', NOW() - INTERVAL '2 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '3 days', 'cardio', 60, 500, 'Hiking', NOW() - INTERVAL '3 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '9 days', 'sports', 120, 800, 'Soccer match', NOW() - INTERVAL '9 days'),
('USER_ID_3', CURRENT_DATE - INTERVAL '10 days', 'strength', 45, 300, 'Gym session', NOW() - INTERVAL '10 days');

-- ================================================
-- PERSONA 4: THE BEGINNER (Just started 3 days ago)
-- Email: beginner@test.com
-- ================================================
-- Replace 'USER_ID_4' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_4', 'beginner@test.com', 'Emma Wilson', 24, 160, 58, 'sedentary', 55, 1800, 90, 225, 60, NOW() - INTERVAL '3 days', NOW());

-- Nutrition entries (just 3 days)
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Day 1 (3 days ago)
('USER_ID_4', CURRENT_DATE - INTERVAL '3 days', 'breakfast', 'Granola bar', 150, 3, 25, 5, NOW() - INTERVAL '3 days'),
('USER_ID_4', CURRENT_DATE - INTERVAL '3 days', 'lunch', 'Caesar salad', 320, 15, 20, 20, NOW() - INTERVAL '3 days'),
-- Day 2 (2 days ago) - more complete
('USER_ID_4', CURRENT_DATE - INTERVAL '2 days', 'breakfast', 'Yogurt', 120, 10, 15, 3, NOW() - INTERVAL '2 days'),
('USER_ID_4', CURRENT_DATE - INTERVAL '2 days', 'lunch', 'Chicken wrap', 380, 25, 40, 15, NOW() - INTERVAL '2 days'),
('USER_ID_4', CURRENT_DATE - INTERVAL '2 days', 'dinner', 'Spaghetti', 450, 15, 65, 15, NOW() - INTERVAL '2 days'),
-- Day 3 (yesterday)
('USER_ID_4', CURRENT_DATE - INTERVAL '1 day', 'breakfast', 'Toast and coffee', 180, 5, 30, 5, NOW() - INTERVAL '1 day'),
('USER_ID_4', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Soup', 250, 12, 35, 8, NOW() - INTERVAL '1 day'),
('USER_ID_4', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Fruit', 80, 1, 20, 0, NOW() - INTERVAL '1 day'),
('USER_ID_4', CURRENT_DATE - INTERVAL '1 day', 'dinner', 'Grilled chicken', 380, 40, 15, 18, NOW() - INTERVAL '1 day');

-- Streaks (just started)
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_4', 3, 3, CURRENT_DATE - INTERVAL '1 day', 3, NOW() - INTERVAL '3 days', NOW());

-- Workouts (1 workout to try)
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_4', CURRENT_DATE - INTERVAL '2 days', 'cardio', 20, 150, 'First workout! Walking', NOW() - INTERVAL '2 days');

-- User Goals (beginner goals)
INSERT INTO public.user_goals (user_id, goal_type, target_value, current_value, deadline, is_active, created_at)
VALUES
('USER_ID_4', 'weight_loss', 3, 0, CURRENT_DATE + INTERVAL '60 days', true, NOW() - INTERVAL '3 days'),
('USER_ID_4', 'daily_calories', 1800, 1200, CURRENT_DATE, true, NOW() - INTERVAL '3 days');

-- ================================================
-- PERSONA 5: THE VETERAN (365+ day streak)
-- Email: veteran@test.com
-- ================================================
-- Replace 'USER_ID_5' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_5', 'veteran@test.com', 'David Thompson', 42, 185, 85, 'very_active', 82, 3000, 180, 350, 100, NOW() - INTERVAL '400 days', NOW());

-- Recent nutrition entries (showing consistency)
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Today
('USER_ID_5', CURRENT_DATE, 'breakfast', 'Protein pancakes', 420, 35, 45, 12, NOW()),
('USER_ID_5', CURRENT_DATE, 'pre_workout', 'Pre-workout shake', 150, 20, 15, 2, NOW()),
('USER_ID_5', CURRENT_DATE, 'lunch', 'Chicken and rice', 580, 50, 65, 15, NOW()),
('USER_ID_5', CURRENT_DATE, 'post_workout', 'Recovery shake', 280, 40, 25, 3, NOW()),
('USER_ID_5', CURRENT_DATE, 'dinner', 'Steak and vegetables', 620, 55, 30, 28, NOW()),
('USER_ID_5', CURRENT_DATE, 'snack', 'Cottage cheese', 180, 20, 10, 8, NOW()),
-- Yesterday
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'breakfast', 'Eggs and oatmeal', 480, 30, 55, 18, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Tuna sandwich', 420, 40, 40, 12, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Protein bar', 250, 25, 25, 8, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'dinner', 'Salmon and quinoa', 580, 48, 55, 20, NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Greek yogurt', 150, 18, 12, 4, NOW() - INTERVAL '1 day');

-- Impressive streak
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_5', 368, 368, CURRENT_DATE, 380, NOW() - INTERVAL '400 days', NOW());

-- Recent workouts (daily routine)
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_5', CURRENT_DATE, 'strength', 60, 400, 'Chest and triceps', NOW()),
('USER_ID_5', CURRENT_DATE - INTERVAL '1 day', 'cardio', 45, 550, 'HIIT training', NOW() - INTERVAL '1 day'),
('USER_ID_5', CURRENT_DATE - INTERVAL '2 days', 'strength', 65, 420, 'Back and biceps', NOW() - INTERVAL '2 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '3 days', 'cardio', 30, 350, 'Running', NOW() - INTERVAL '3 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '4 days', 'strength', 70, 450, 'Legs', NOW() - INTERVAL '4 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '5 days', 'flexibility', 30, 100, 'Yoga', NOW() - INTERVAL '5 days'),
('USER_ID_5', CURRENT_DATE - INTERVAL '6 days', 'strength', 55, 380, 'Shoulders', NOW() - INTERVAL '6 days');

-- User Goals (advanced)
INSERT INTO public.user_goals (user_id, goal_type, target_value, current_value, deadline, is_active, created_at)
VALUES
('USER_ID_5', 'muscle_gain', 3, 2.5, CURRENT_DATE + INTERVAL '90 days', true, NOW() - INTERVAL '60 days'),
('USER_ID_5', 'daily_protein', 180, 178, CURRENT_DATE, true, NOW() - INTERVAL '30 days'),
('USER_ID_5', 'weekly_workouts', 7, 7, CURRENT_DATE + INTERVAL '7 days', true, NOW() - INTERVAL '365 days');

-- Multiple achievements unlocked
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, progress, created_at)
VALUES
('USER_ID_5', 'warm_up', NOW() - INTERVAL '361 days', 100, NOW() - INTERVAL '361 days'),
('USER_ID_5', 'no_excuses', NOW() - INTERVAL '354 days', 100, NOW() - INTERVAL '354 days'),
('USER_ID_5', 'sweat_starter', NOW() - INTERVAL '347 days', 100, NOW() - INTERVAL '347 days'),
('USER_ID_5', 'grind_machine', NOW() - INTERVAL '340 days', 100, NOW() - INTERVAL '340 days'),
('USER_ID_5', 'beast_mode', NOW() - INTERVAL '318 days', 100, NOW() - INTERVAL '318 days'),
('USER_ID_5', 'iron_month', NOW() - INTERVAL '278 days', 100, NOW() - INTERVAL '278 days'),
('USER_ID_5', 'quarter_crusher', NOW() - INTERVAL '188 days', 100, NOW() - INTERVAL '188 days'),
('USER_ID_5', 'half_year', NOW() - INTERVAL '3 days', 100, NOW() - INTERVAL '3 days'),
('USER_ID_5', 'year_one', NOW() - INTERVAL '3 days', 100, NOW() - INTERVAL '3 days');

-- ================================================
-- PERSONA 6: THE IRREGULAR USER (Sporadic usage)
-- Email: irregular@test.com
-- ================================================
-- Replace 'USER_ID_6' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_6', 'irregular@test.com', 'Lisa Brown', 29, 168, 62, 'light', 60, 2100, 105, 260, 70, NOW() - INTERVAL '60 days', NOW());

-- Sporadic nutrition entries
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Random day 1 week ago
('USER_ID_6', CURRENT_DATE - INTERVAL '7 days', 'lunch', 'Sandwich', 420, 20, 45, 18, NOW() - INTERVAL '7 days'),
-- Random day 2 weeks ago
('USER_ID_6', CURRENT_DATE - INTERVAL '14 days', 'breakfast', 'Cereal', 280, 8, 50, 6, NOW() - INTERVAL '14 days'),
('USER_ID_6', CURRENT_DATE - INTERVAL '14 days', 'dinner', 'Pasta', 520, 18, 70, 18, NOW() - INTERVAL '14 days'),
-- Random day 3 weeks ago
('USER_ID_6', CURRENT_DATE - INTERVAL '21 days', 'lunch', 'Salad', 350, 25, 30, 15, NOW() - INTERVAL '21 days'),
-- Yesterday (trying to restart)
('USER_ID_6', CURRENT_DATE - INTERVAL '1 day', 'breakfast', 'Smoothie', 320, 15, 50, 8, NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Wrap', 450, 30, 45, 20, NOW() - INTERVAL '1 day');

-- Streaks (poor consistency)
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_6', 1, 3, CURRENT_DATE - INTERVAL '1 day', 8, NOW() - INTERVAL '60 days', NOW());

-- Sporadic workouts
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_6', CURRENT_DATE - INTERVAL '1 day', 'cardio', 25, 200, 'Trying to get back', NOW() - INTERVAL '1 day'),
('USER_ID_6', CURRENT_DATE - INTERVAL '14 days', 'flexibility', 20, 80, 'Quick yoga', NOW() - INTERVAL '14 days'),
('USER_ID_6', CURRENT_DATE - INTERVAL '30 days', 'cardio', 30, 250, 'Treadmill', NOW() - INTERVAL '30 days');

-- ================================================
-- PERSONA 7: THE DATA ENTHUSIAST (Logs everything meticulously)
-- Email: dataenthusiast@test.com
-- ================================================
-- Replace 'USER_ID_7' with actual UUID

-- Profile
INSERT INTO public.profiles (id, email, name, age, height, weight, activity_level, target_weight, daily_calorie_goal, daily_protein_goal, daily_carbs_goal, daily_fat_goal, created_at, updated_at)
VALUES
('USER_ID_7', 'dataenthusiast@test.com', 'Robert Kim', 31, 178, 77, 'moderate', 75, 2600, 140, 320, 85, NOW() - INTERVAL '45 days', NOW());

-- Detailed nutrition entries (logs everything, even water and supplements)
INSERT INTO public.nutrition_entries (user_id, date, meal_type, food_name, calories, protein, carbs, fat, created_at)
VALUES
-- Today (extremely detailed)
('USER_ID_7', CURRENT_DATE, 'breakfast', '2 whole eggs, scrambled', 140, 12, 2, 10, NOW() - INTERVAL '8 hours'),
('USER_ID_7', CURRENT_DATE, 'breakfast', '2 slices whole wheat toast', 160, 6, 30, 2, NOW() - INTERVAL '8 hours'),
('USER_ID_7', CURRENT_DATE, 'breakfast', '1 medium banana', 105, 1, 27, 0, NOW() - INTERVAL '8 hours'),
('USER_ID_7', CURRENT_DATE, 'breakfast', 'Black coffee', 5, 0, 1, 0, NOW() - INTERVAL '8 hours'),
('USER_ID_7', CURRENT_DATE, 'snack', 'Whey protein shake (30g)', 120, 25, 3, 1, NOW() - INTERVAL '6 hours'),
('USER_ID_7', CURRENT_DATE, 'snack', '1 medium apple', 95, 0, 25, 0, NOW() - INTERVAL '6 hours'),
('USER_ID_7', CURRENT_DATE, 'lunch', '150g grilled chicken breast', 248, 46, 0, 6, NOW() - INTERVAL '4 hours'),
('USER_ID_7', CURRENT_DATE, 'lunch', '200g brown rice, cooked', 218, 5, 45, 2, NOW() - INTERVAL '4 hours'),
('USER_ID_7', CURRENT_DATE, 'lunch', 'Mixed vegetables (100g)', 35, 2, 7, 0, NOW() - INTERVAL '4 hours'),
('USER_ID_7', CURRENT_DATE, 'lunch', '1 tbsp olive oil', 120, 0, 0, 14, NOW() - INTERVAL '4 hours'),
('USER_ID_7', CURRENT_DATE, 'snack', '28g almonds', 164, 6, 6, 14, NOW() - INTERVAL '2 hours'),
('USER_ID_7', CURRENT_DATE, 'dinner', '170g salmon fillet', 354, 40, 0, 20, NOW() - INTERVAL '1 hour'),
('USER_ID_7', CURRENT_DATE, 'dinner', '200g sweet potato', 180, 4, 41, 0, NOW() - INTERVAL '1 hour'),
('USER_ID_7', CURRENT_DATE, 'dinner', 'Green salad with dressing', 120, 2, 8, 9, NOW() - INTERVAL '1 hour'),
-- Yesterday (similarly detailed)
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'breakfast', '1 cup oatmeal', 154, 6, 27, 3, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'breakfast', '2 tbsp peanut butter', 188, 8, 8, 16, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'breakfast', '1 cup blueberries', 84, 1, 21, 0, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Greek yogurt (170g)', 100, 17, 6, 0, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'snack', '1 tbsp honey', 64, 0, 17, 0, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'lunch', 'Turkey sandwich (detailed)', 420, 35, 42, 15, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'snack', 'Protein bar', 210, 20, 25, 7, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'dinner', '200g lean beef', 332, 50, 0, 14, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'dinner', '150g quinoa, cooked', 180, 7, 31, 3, NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'dinner', 'Steamed broccoli (100g)', 35, 3, 7, 0, NOW() - INTERVAL '1 day');

-- Consistent streak (tracks daily)
INSERT INTO public.streaks (user_id, current_streak, longest_streak, last_check_in, total_days_tracked, created_at, updated_at)
VALUES
('USER_ID_7', 42, 42, CURRENT_DATE, 42, NOW() - INTERVAL '42 days', NOW());

-- Detailed workout logs
INSERT INTO public.workouts (user_id, date, type, duration_minutes, calories_burned, notes, created_at)
VALUES
('USER_ID_7', CURRENT_DATE, 'strength', 65, 380, 'Push day: Bench press 3x8@185lbs, Shoulder press 3x10@135lbs, Dips 3x12, Tricep ext 3x15', NOW()),
('USER_ID_7', CURRENT_DATE - INTERVAL '1 day', 'cardio', 35, 420, 'Interval running: 5min warmup, 8x(1min sprint/90sec jog), 5min cooldown. Avg HR: 145', NOW() - INTERVAL '1 day'),
('USER_ID_7', CURRENT_DATE - INTERVAL '2 days', 'strength', 70, 400, 'Pull day: Deadlift 3x5@315lbs, Pull-ups 4x8, Rows 3x12@155lbs, Curls 3x15', NOW() - INTERVAL '2 days'),
('USER_ID_7', CURRENT_DATE - INTERVAL '3 days', 'cardio', 45, 380, 'Cycling: 15km in 35min, avg speed 25.7km/h, elevation gain 120m', NOW() - INTERVAL '3 days');

-- Detailed goals with metrics
INSERT INTO public.user_goals (user_id, goal_type, target_value, current_value, deadline, is_active, created_at)
VALUES
('USER_ID_7', 'weight_loss', 2, 1.2, CURRENT_DATE + INTERVAL '30 days', true, NOW() - INTERVAL '20 days'),
('USER_ID_7', 'daily_calories', 2600, 2587, CURRENT_DATE, true, NOW() - INTERVAL '42 days'),
('USER_ID_7', 'daily_protein', 140, 142, CURRENT_DATE, true, NOW() - INTERVAL '42 days'),
('USER_ID_7', 'weekly_workouts', 5, 4, CURRENT_DATE + INTERVAL '3 days', true, NOW() - INTERVAL '42 days');

-- Achievements based on consistency
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, progress, created_at)
VALUES
('USER_ID_7', 'warm_up', NOW() - INTERVAL '35 days', 100, NOW() - INTERVAL '35 days'),
('USER_ID_7', 'no_excuses', NOW() - INTERVAL '28 days', 100, NOW() - INTERVAL '28 days'),
('USER_ID_7', 'sweat_starter', NOW() - INTERVAL '21 days', 100, NOW() - INTERVAL '21 days'),
('USER_ID_7', 'grind_machine', NOW() - INTERVAL '12 days', 100, NOW() - INTERVAL '12 days');

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
--    - veteran@test.com - 365+ day streak legend
--    - irregular@test.com - Sporadic usage
--    - dataenthusiast@test.com - Logs everything in detail