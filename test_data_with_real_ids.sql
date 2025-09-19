-- =====================================================
-- COMPREHENSIVE TEST DATA FOR STREAKS FLUTTER APP
-- =====================================================
-- Created: September 19, 2025
-- Updated with real user IDs from existing profiles
--
-- This script creates diverse test user personas with realistic data
-- covering all database tables and relationships for comprehensive testing.
--
-- USER IDs FROM YOUR EXISTING PROFILES:
-- Elite Athlete: ed858fbf-ca85-44fa-8dae-eb2fd99e09b8
-- Busy Professional: c600b93e-6aa4-48b8-95a1-0926b869f875
-- Weekend Warrior: 755d2aa4-929e-443a-9ae1-7b6d9aa3af8a
-- New Beginner: 722c1211-0810-413f-b37e-000065754496
-- Comeback Hero: 072d54c5-3258-495f-b684-da8631dfbf98
-- =====================================================

-- =====================================================
-- PERSONA 1: THE ELITE ATHLETE (400+ day streak legend)
-- Email: elite.athlete@test.com
-- Profile: Advanced athlete, daily workouts, perfect nutrition tracking
-- =====================================================

-- Health Metrics (Last 14 days - showing consistency)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, created_at, updated_at
) VALUES
-- Recent 7 days
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE, 16500, 65, 8.5, 650, 12.5, 90, NOW(), NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 15800, 68, 8.0, 720, 11.8, 105, NOW() - INTERVAL '1 day', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 2, 17200, 62, 9.0, 680, 13.2, 95, NOW() - INTERVAL '2 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 3, 16000, 70, 8.2, 700, 12.0, 110, NOW() - INTERVAL '3 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 4, 18500, 66, 8.8, 780, 14.5, 120, NOW() - INTERVAL '4 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 5, 15500, 64, 7.8, 650, 11.5, 85, NOW() - INTERVAL '5 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 6, 19000, 69, 9.2, 820, 15.8, 130, NOW() - INTERVAL '6 days', NOW()),
-- Previous week
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 7, 16800, 67, 8.3, 710, 12.8, 100, NOW() - INTERVAL '7 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 8, 17500, 63, 8.7, 750, 13.8, 115, NOW() - INTERVAL '8 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 9, 15200, 71, 8.0, 630, 11.2, 80, NOW() - INTERVAL '9 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 10, 18200, 65, 9.1, 790, 14.2, 125, NOW() - INTERVAL '10 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 11, 16500, 68, 8.4, 680, 12.5, 95, NOW() - INTERVAL '11 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 12, 17800, 64, 8.9, 760, 13.5, 110, NOW() - INTERVAL '12 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 13, 16200, 70, 8.1, 670, 12.0, 88, NOW() - INTERVAL '13 days', NOW());

-- Nutrition Entries (Last 3 days - detailed tracking)
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
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 1, 'dinner', 'Lean beef with vegetables', 680, 55, 35, 25, 12, NOW() - INTERVAL '1 day'),
-- Day before yesterday
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 2, 'breakfast', 'Protein pancakes', 450, 30, 48, 12, 6, NOW() - INTERVAL '2 days'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 2, 'lunch', 'Tuna salad with chickpeas', 480, 42, 38, 16, 15, NOW() - INTERVAL '2 days'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 2, 'snack', 'Mixed nuts and fruit', 250, 8, 28, 15, 8, NOW() - INTERVAL '2 days'),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 2, 'dinner', 'Grilled fish with brown rice', 620, 48, 55, 18, 10, NOW() - INTERVAL '2 days');

-- Streak Data (Elite level)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily', 412, 412, CURRENT_DATE, true,
    NOW() - INTERVAL '450 days', NOW()
);

-- User Goals (Advanced athlete goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily_protein', 180, 182, 'grams', true, NOW() - INTERVAL '100 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'weekly_workouts', 7, 7, 'sessions', true, NOW() - INTERVAL '100 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'body_fat_percentage', 8, 9.2, 'percent', true, NOW() - INTERVAL '80 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'daily_steps', 15000, 16500, 'steps', true, NOW() - INTERVAL '100 days', NOW());

-- Achievements (Multiple unlocked for elite user)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'warm_up', NOW() - INTERVAL '410 days', true, NOW() - INTERVAL '410 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'no_excuses', NOW() - INTERVAL '407 days', true, NOW() - INTERVAL '407 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'sweat_starter', NOW() - INTERVAL '403 days', true, NOW() - INTERVAL '403 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'grind_machine', NOW() - INTERVAL '396 days', true, NOW() - INTERVAL '396 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'beast_mode', NOW() - INTERVAL '389 days', true, NOW() - INTERVAL '389 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'iron_month', NOW() - INTERVAL '380 days', true, NOW() - INTERVAL '380 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'quarter_crusher', NOW() - INTERVAL '320 days', true, NOW() - INTERVAL '320 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'half_year', NOW() - INTERVAL '230 days', true, NOW() - INTERVAL '230 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'year_one', NOW() - INTERVAL '48 days', true, NOW() - INTERVAL '48 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'sweatflix', NOW() - INTERVAL '350 days', true, NOW() - INTERVAL '350 days', NOW()),
('ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', 'no_days_off', NOW() - INTERVAL '380 days', true, NOW() - INTERVAL '380 days', NOW());

-- Chat Sessions (AI coaching history)
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
 NOW(), NOW()),
(gen_random_uuid(), 'ed858fbf-ca85-44fa-8dae-eb2fd99e09b8', CURRENT_DATE - 3, 1, 'Recovery Protocol Review',
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

-- Health Metrics (Sporadic pattern - busy lifestyle)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, created_at, updated_at
) VALUES
-- Good days mixed with busy days
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 6800, 72, 6.5, 280, 4.2, 35, NOW(), NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 12500, 68, 7.2, 450, 8.5, 60, NOW() - INTERVAL '1 day', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 2, 4200, 75, 5.8, 180, 2.8, 20, NOW() - INTERVAL '2 days', NOW()), -- Busy day
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 3, 9800, 70, 7.5, 380, 6.8, 45, NOW() - INTERVAL '3 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 4, 11200, 69, 6.8, 420, 7.5, 55, NOW() - INTERVAL '4 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 5, 3800, 78, 5.5, 160, 2.5, 15, NOW() - INTERVAL '5 days', NOW()), -- Another busy day
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 6, 13500, 66, 8.0, 480, 9.2, 70, NOW() - INTERVAL '6 days', NOW()); -- Weekend

-- Nutrition Entries (Meal prep focused, some missed days)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today (good day)
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'breakfast', 'Overnight oats with protein powder', 350, 25, 45, 8, 10, NOW() - INTERVAL '8 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'lunch', 'Meal prep chicken bowl', 480, 38, 42, 16, 8, NOW() - INTERVAL '5 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'snack', 'Apple with almond butter', 180, 6, 22, 8, 5, NOW() - INTERVAL '3 hours'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE, 'dinner', 'Takeout sushi (tracked)', 420, 28, 55, 12, 3, NOW() - INTERVAL '1 hour'),
-- Yesterday (workout day)
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 'breakfast', 'Greek yogurt parfait', 280, 20, 35, 6, 4, NOW() - INTERVAL '1 day'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 'lunch', 'Salad with grilled protein', 380, 32, 25, 18, 12, NOW() - INTERVAL '1 day'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 'post_workout', 'Protein shake', 150, 25, 8, 2, 0, NOW() - INTERVAL '1 day'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 1, 'dinner', 'Stir fry with brown rice', 520, 28, 58, 18, 6, NOW() - INTERVAL '1 day'),
-- Day -2 was too busy (no entries)
-- Day -3 (partial tracking)
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 3, 'breakfast', 'Coffee and granola bar', 220, 5, 35, 8, 3, NOW() - INTERVAL '3 days'),
('c600b93e-6aa4-48b8-95a1-0926b869f875', CURRENT_DATE - 3, 'lunch', 'Work cafeteria meal', 450, 22, 48, 20, 4, NOW() - INTERVAL '3 days');

-- Streak Data (Recently broken, trying to rebuild)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    'c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily', 2, 8, CURRENT_DATE - 1, false,
    NOW() - INTERVAL '45 days', NOW()
);

-- User Goals (Weight loss focused)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'weight_loss', 5, 2.8, 'kg', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily_calories', 1800, 1430, 'calories', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'weekly_workouts', 4, 2, 'sessions', true, NOW() - INTERVAL '30 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'daily_steps', 8000, 6800, 'steps', true, NOW() - INTERVAL '30 days', NOW());

-- Achievements (Few unlocked, working on consistency)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'warm_up', NOW() - INTERVAL '40 days', true, NOW() - INTERVAL '40 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'no_excuses', NOW() - INTERVAL '35 days', true, NOW() - INTERVAL '35 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'sweat_starter', NOW() - INTERVAL '25 days', true, NOW() - INTERVAL '25 days', NOW()),
('c600b93e-6aa4-48b8-95a1-0926b869f875', 'comeback_kid', NOW() - INTERVAL '5 days', true, NOW() - INTERVAL '5 days', NOW());

-- Chat Sessions (Seeking advice on time management)
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

-- =====================================================
-- PERSONA 3: THE WEEKEND WARRIOR
-- Email: weekend.warrior@test.com
-- Profile: Very active on weekends, sedentary during weekdays
-- =====================================================

-- Health Metrics (Weekend spikes, weekday lows)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, created_at, updated_at
) VALUES
-- This week pattern
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 22000, 72, 8.5, 980, 18.5, 150, NOW(), NOW()), -- Sunday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 1, 25500, 68, 8.0, 1200, 22.0, 180, NOW() - INTERVAL '1 day', NOW()), -- Saturday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 2, 4500, 70, 7.0, 220, 3.2, 25, NOW() - INTERVAL '2 days', NOW()), -- Friday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 3, 5200, 72, 7.2, 280, 3.8, 30, NOW() - INTERVAL '3 days', NOW()), -- Thursday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 4, 4800, 74, 6.8, 240, 3.5, 22, NOW() - INTERVAL '4 days', NOW()), -- Wednesday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 5, 6200, 71, 7.5, 320, 4.5, 35, NOW() - INTERVAL '5 days', NOW()), -- Tuesday
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 6, 5800, 73, 7.8, 300, 4.2, 32, NOW() - INTERVAL '6 days', NOW()), -- Monday
-- Previous weekend
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 7, 28000, 66, 9.0, 1400, 25.0, 200, NOW() - INTERVAL '7 days', NOW()); -- Sunday

-- Nutrition Entries (Indulgent weekends, lighter weekdays)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Weekend indulgence
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'breakfast', 'Weekend pancake stack', 680, 18, 95, 22, 6, NOW() - INTERVAL '6 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'lunch', 'BBQ burger with fries', 950, 45, 78, 48, 8, NOW() - INTERVAL '3 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'snack', 'Craft beer', 180, 2, 15, 0, 0, NOW() - INTERVAL '2 hours'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE, 'dinner', 'Pizza night', 820, 35, 85, 35, 4, NOW() - INTERVAL '1 hour'),
-- Saturday (active day)
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 1, 'breakfast', 'Sports drink and energy bar', 280, 8, 55, 6, 2, NOW() - INTERVAL '1 day'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 1, 'lunch', 'Post-hike sandwich', 580, 35, 65, 18, 8, NOW() - INTERVAL '1 day'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 1, 'dinner', 'Celebratory steak dinner', 920, 65, 45, 42, 6, NOW() - INTERVAL '1 day'),
-- Weekday (lighter)
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 3, 'breakfast', 'Coffee and muffin', 320, 6, 48, 12, 2, NOW() - INTERVAL '3 days'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 3, 'lunch', 'Desk salad', 380, 25, 30, 18, 10, NOW() - INTERVAL '3 days'),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', CURRENT_DATE - 3, 'dinner', 'Simple pasta', 520, 18, 78, 16, 4, NOW() - INTERVAL '3 days');

-- Streak Data (Poor consistency due to weekend-only pattern)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    '755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'daily', 0, 3, CURRENT_DATE - 5, false,
    NOW() - INTERVAL '60 days', NOW()
);

-- User Goals (Maintenance focused)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'weekend_activities', 2, 2, 'sessions', true, NOW() - INTERVAL '40 days', NOW()),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'weekly_calories_burned', 2000, 2180, 'calories', true, NOW() - INTERVAL '40 days', NOW());

-- Achievements (Weekend focused)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'warm_up', NOW() - INTERVAL '55 days', true, NOW() - INTERVAL '55 days', NOW()),
('755d2aa4-929e-443a-9ae1-7b6d9aa3af8a', 'sweatflix', NOW() - INTERVAL '50 days', true, NOW() - INTERVAL '50 days', NOW());

-- =====================================================
-- PERSONA 4: THE NEW BEGINNER
-- Email: new.beginner@test.com
-- Profile: Just started 5 days ago, learning the ropes
-- =====================================================

-- Health Metrics (Just started tracking)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, created_at, updated_at
) VALUES
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 7200, 78, 7.5, 220, 4.8, 30, NOW(), NOW()),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 1, 6800, 80, 8.2, 200, 4.5, 25, NOW() - INTERVAL '1 day', NOW()),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 2, 8500, 76, 7.8, 280, 6.2, 40, NOW() - INTERVAL '2 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 3, 5200, 82, 7.0, 150, 3.8, 20, NOW() - INTERVAL '3 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 4, 6500, 79, 8.5, 190, 4.2, 28, NOW() - INTERVAL '4 days', NOW());

-- Nutrition Entries (Learning to track, simple meals)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Today (getting better at tracking)
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'breakfast', 'Cereal with milk', 280, 8, 45, 6, 3, NOW() - INTERVAL '8 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'lunch', 'Sandwich and chips', 480, 20, 55, 18, 4, NOW() - INTERVAL '4 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'snack', 'Apple', 80, 0, 20, 0, 4, NOW() - INTERVAL '2 hours'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE, 'dinner', 'Chicken and rice', 520, 35, 58, 12, 2, NOW() - INTERVAL '1 hour'),
-- Yesterday
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 1, 'breakfast', 'Toast with butter', 220, 6, 35, 8, 2, NOW() - INTERVAL '1 day'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 1, 'lunch', 'Salad with dressing', 320, 15, 25, 18, 8, NOW() - INTERVAL '1 day'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 1, 'dinner', 'Pasta with sauce', 450, 15, 78, 12, 4, NOW() - INTERVAL '1 day'),
-- Day -2 (first real attempt)
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 2, 'breakfast', 'Yogurt', 150, 12, 18, 5, 0, NOW() - INTERVAL '2 days'),
('722c1211-0810-413f-b37e-000065754496', CURRENT_DATE - 2, 'lunch', 'Leftovers', 380, 22, 35, 16, 3, NOW() - INTERVAL '2 days');

-- Streak Data (Just getting started)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    '722c1211-0810-413f-b37e-000065754496', 'daily', 4, 4, CURRENT_DATE, true,
    NOW() - INTERVAL '5 days', NOW()
);

-- User Goals (Beginner-friendly goals)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('722c1211-0810-413f-b37e-000065754496', 'daily_steps', 6000, 7200, 'steps', true, NOW() - INTERVAL '5 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'track_meals', 3, 3, 'meals', true, NOW() - INTERVAL '4 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'weekly_workouts', 2, 1, 'sessions', true, NOW() - INTERVAL '3 days', NOW());

-- Achievements (Early achievements)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('722c1211-0810-413f-b37e-000065754496', 'warm_up', NOW() - INTERVAL '3 days', true, NOW() - INTERVAL '3 days', NOW()),
('722c1211-0810-413f-b37e-000065754496', 'no_excuses', NOW() - INTERVAL '1 day', false, NOW() - INTERVAL '1 day', NOW());

-- Chat Sessions (Getting started guidance)
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

-- =====================================================
-- PERSONA 5: THE COMEBACK HERO
-- Email: comeback.hero@test.com
-- Profile: Had a long streak, lost it, now rebuilding with determination
-- =====================================================

-- Health Metrics (Recently restarted with high motivation)
INSERT INTO public.health_metrics (
    user_id, date, steps, heart_rate, sleep_hours, calories_burned,
    distance, active_minutes, created_at, updated_at
) VALUES
-- Strong comeback streak
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 14500, 70, 7.8, 520, 10.5, 75, NOW(), NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 1, 13800, 72, 7.5, 480, 9.8, 70, NOW() - INTERVAL '1 day', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 2, 15200, 68, 8.0, 580, 11.2, 85, NOW() - INTERVAL '2 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 3, 12500, 74, 7.2, 450, 9.0, 65, NOW() - INTERVAL '3 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 4, 16800, 66, 8.2, 650, 12.8, 95, NOW() - INTERVAL '4 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 5, 13200, 71, 7.6, 500, 9.5, 72, NOW() - INTERVAL '5 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 6, 14000, 69, 7.9, 530, 10.2, 78, NOW() - INTERVAL '6 days', NOW()),
-- Gap where streak was lost (simulating missed days)
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 12, 11500, 73, 7.0, 420, 8.5, 60, NOW() - INTERVAL '12 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 13, 10800, 75, 6.8, 380, 7.8, 55, NOW() - INTERVAL '13 days', NOW());

-- Nutrition Entries (Disciplined approach after restart)
INSERT INTO public.nutrition_entries (
    user_id, date, meal_type, food_name, calories, protein, carbs, fat, fiber, created_at
) VALUES
-- Recent days showing discipline
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'breakfast', 'Protein smoothie bowl', 380, 28, 42, 12, 8, NOW() - INTERVAL '7 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'lunch', 'Grilled chicken salad', 420, 38, 25, 18, 12, NOW() - INTERVAL '4 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'snack', 'Protein bar', 220, 20, 25, 8, 5, NOW() - INTERVAL '2 hours'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE, 'dinner', 'Lean fish with vegetables', 480, 42, 35, 16, 10, NOW() - INTERVAL '1 hour'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 1, 'breakfast', 'Oatmeal with berries', 320, 15, 55, 8, 12, NOW() - INTERVAL '1 day'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 1, 'lunch', 'Turkey wrap', 450, 32, 48, 16, 8, NOW() - INTERVAL '1 day'),
('072d54c5-3258-495f-b684-da8631dfbf98', CURRENT_DATE - 1, 'dinner', 'Salmon with quinoa', 580, 45, 52, 22, 6, NOW() - INTERVAL '1 day');

-- Streak Data (Lost previous long streak, rebuilding)
INSERT INTO public.streaks (
    user_id, streak_type, current_streak, longest_streak, last_activity_date,
    target_achieved, created_at, updated_at
) VALUES (
    '072d54c5-3258-495f-b684-da8631dfbf98', 'daily', 7, 89, CURRENT_DATE, true,
    NOW() - INTERVAL '180 days', NOW()
);

-- User Goals (Focused on rebuilding)
INSERT INTO public.user_goals (
    user_id, goal_type, target_value, current_value, unit, is_active, created_at, updated_at
) VALUES
('072d54c5-3258-495f-b684-da8631dfbf98', 'rebuild_streak', 30, 7, 'days', true, NOW() - INTERVAL '7 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'weight_loss', 5, 1.8, 'kg', true, NOW() - INTERVAL '20 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'daily_calories', 2200, 2080, 'calories', true, NOW() - INTERVAL '7 days', NOW());

-- Achievements (Had many, now rebuilding)
INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at, notified, created_at, updated_at) VALUES
('072d54c5-3258-495f-b684-da8631dfbf98', 'warm_up', NOW() - INTERVAL '175 days', true, NOW() - INTERVAL '175 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'no_excuses', NOW() - INTERVAL '172 days', true, NOW() - INTERVAL '172 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'sweat_starter', NOW() - INTERVAL '168 days', true, NOW() - INTERVAL '168 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'grind_machine', NOW() - INTERVAL '161 days', true, NOW() - INTERVAL '161 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'beast_mode', NOW() - INTERVAL '154 days', true, NOW() - INTERVAL '154 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'iron_month', NOW() - INTERVAL '145 days', true, NOW() - INTERVAL '145 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'quarter_crusher', NOW() - INTERVAL '86 days', true, NOW() - INTERVAL '86 days', NOW()),
('072d54c5-3258-495f-b684-da8631dfbf98', 'comeback_kid', NOW() - INTERVAL '5 days', false, NOW() - INTERVAL '5 days', NOW());

-- Chat Sessions (Motivation and strategy)
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

-- =====================================================
-- SUMMARY
-- =====================================================

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ TEST DATA WITH REAL USER IDs CREATED!';
    RAISE NOTICE '';
    RAISE NOTICE '👥 User Personas with Real IDs:';
    RAISE NOTICE '   1. Elite Athlete: ed858fbf-ca85-44fa-8dae-eb2fd99e09b8';
    RAISE NOTICE '   2. Busy Professional: c600b93e-6aa4-48b8-95a1-0926b869f875';
    RAISE NOTICE '   3. Weekend Warrior: 755d2aa4-929e-443a-9ae1-7b6d9aa3af8a';
    RAISE NOTICE '   4. New Beginner: 722c1211-0810-413f-b37e-000065754496';
    RAISE NOTICE '   5. Comeback Hero: 072d54c5-3258-495f-b684-da8631dfbf98';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Ready for comprehensive testing!';
END $$;

-- =====================================================
-- END OF TEST DATA SCRIPT
-- =====================================================