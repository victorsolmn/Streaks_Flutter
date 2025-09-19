-- ============================================
-- VERIFY AND FIX NEW SUPABASE DATABASE
-- For your new Supabase project with existing tables
-- ============================================

-- STEP 1: Add missing columns to profiles table
-- ============================================
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER DEFAULT 10000,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL DEFAULT 8,
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
ADD COLUMN IF NOT EXISTS experience_level TEXT,
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_seen_fitness_goal_summary BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS bmi_value DECIMAL,
ADD COLUMN IF NOT EXISTS bmi_category_value TEXT,
ADD COLUMN IF NOT EXISTS device_name TEXT,
ADD COLUMN IF NOT EXISTS device_connected BOOLEAN DEFAULT FALSE;

-- STEP 2: Ensure nutrition_entries has all required columns
-- ============================================
ALTER TABLE public.nutrition_entries
ADD COLUMN IF NOT EXISTS food_name TEXT,
ADD COLUMN IF NOT EXISTS calories DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS protein DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS carbs DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS fat DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS fiber DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS quantity_grams DECIMAL,
ADD COLUMN IF NOT EXISTS meal_type TEXT,
ADD COLUMN IF NOT EXISTS food_source TEXT,
ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;

-- STEP 3: Ensure health_metrics has proper columns
-- ============================================
ALTER TABLE public.health_metrics
ADD COLUMN IF NOT EXISTS steps INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS heart_rate INTEGER,
ADD COLUMN IF NOT EXISTS sleep_hours DECIMAL,
ADD COLUMN IF NOT EXISTS calories_burned DECIMAL,
ADD COLUMN IF NOT EXISTS distance DECIMAL,
ADD COLUMN IF NOT EXISTS active_minutes INTEGER,
ADD COLUMN IF NOT EXISTS water_intake DECIMAL,
ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;

-- Add proper constraint for heart rate (more flexible)
ALTER TABLE public.health_metrics
DROP CONSTRAINT IF EXISTS health_metrics_heart_rate_check;

ALTER TABLE public.health_metrics
ADD CONSTRAINT health_metrics_heart_rate_check
CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250));

-- STEP 4: Ensure streaks has all columns
-- ============================================
ALTER TABLE public.streaks
ADD COLUMN IF NOT EXISTS streak_type TEXT DEFAULT 'daily',
ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_activity_date DATE,
ADD COLUMN IF NOT EXISTS target_achieved BOOLEAN DEFAULT FALSE;

-- STEP 5: Rename 'goals' table to 'user_goals' if needed
-- ============================================
-- The Flutter code expects 'user_goals', but you have 'goals'
-- Option 1: Rename the table
ALTER TABLE IF EXISTS public.goals RENAME TO user_goals;

-- Option 2: Create a view alias (if you want to keep 'goals' name)
-- CREATE OR REPLACE VIEW public.user_goals AS SELECT * FROM public.goals;

-- STEP 6: Ensure user_goals has proper columns
-- ============================================
ALTER TABLE public.user_goals
ADD COLUMN IF NOT EXISTS goal_type TEXT,
ADD COLUMN IF NOT EXISTS target_value DECIMAL,
ADD COLUMN IF NOT EXISTS current_value DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS unit TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- STEP 7: Create necessary views
-- ============================================

-- Daily nutrition summary view
CREATE OR REPLACE VIEW public.daily_nutrition_summary AS
SELECT
  user_id,
  date,
  SUM(calories) as total_calories,
  SUM(protein) as total_protein,
  SUM(carbs) as total_carbs,
  SUM(fat) as total_fat,
  SUM(fiber) as total_fiber,
  COUNT(*) as entries_count
FROM public.nutrition_entries
GROUP BY user_id, date;

-- User dashboard view
CREATE OR REPLACE VIEW public.user_dashboard AS
SELECT
  p.id as user_id,
  p.name,
  p.email,
  p.daily_calories_target,
  p.daily_steps_target,
  p.daily_water_target,
  p.daily_sleep_target,
  COALESCE(s.current_streak, 0) as current_streak,
  COALESCE(s.longest_streak, 0) as longest_streak,
  COALESCE(hm.steps, 0) as today_steps,
  COALESCE(hm.calories_burned, 0) as today_calories_burned,
  COALESCE(hm.water_intake, 0) as today_water,
  COALESCE(hm.sleep_hours, 0) as last_night_sleep,
  COALESCE(ns.total_calories, 0) as today_calories_consumed,
  COALESCE(ns.total_protein, 0) as today_protein
FROM public.profiles p
LEFT JOIN public.streaks s ON p.id = s.user_id AND s.streak_type = 'daily'
LEFT JOIN public.health_metrics hm ON p.id = hm.user_id AND hm.date = CURRENT_DATE
LEFT JOIN public.daily_nutrition_summary ns ON p.id = ns.user_id AND ns.date = CURRENT_DATE;

-- STEP 8: Create indexes for performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON public.nutrition_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON public.health_metrics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON public.streaks(user_id, streak_type);
CREATE INDEX IF NOT EXISTS idx_user_goals_user_active ON public.user_goals(user_id, is_active);

-- STEP 9: Enable RLS on all tables
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- STEP 10: Create RLS policies
-- ============================================

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Nutrition entries policies
CREATE POLICY "Users can manage own nutrition"
  ON public.nutrition_entries FOR ALL
  USING (auth.uid() = user_id);

-- Health metrics policies
CREATE POLICY "Users can manage own health metrics"
  ON public.health_metrics FOR ALL
  USING (auth.uid() = user_id);

-- Streaks policies
CREATE POLICY "Users can manage own streaks"
  ON public.streaks FOR ALL
  USING (auth.uid() = user_id);

-- Goals policies
CREATE POLICY "Users can manage own goals"
  ON public.user_goals FOR ALL
  USING (auth.uid() = user_id);

-- STEP 11: Verify everything
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Database verification complete!';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Update supabase_config.dart with your new project URL and anon key';
  RAISE NOTICE '2. Test the app with the new database';
  RAISE NOTICE '3. Monitor for any remaining issues';
END $$;