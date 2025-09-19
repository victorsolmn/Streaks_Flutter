-- ============================================
-- STREAKS FLUTTER - COMPLETE DATABASE FIX
-- Run this entire script in Supabase SQL Editor
-- Generated: December 2024
-- ============================================

-- STEP 1: Create Missing Tables
-- ============================================

-- 1.1 Create nutrition_entries table
CREATE TABLE IF NOT EXISTS public.nutrition_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  food_name TEXT NOT NULL,
  calories DECIMAL NOT NULL DEFAULT 0,
  protein DECIMAL DEFAULT 0,
  carbs DECIMAL DEFAULT 0,
  fat DECIMAL DEFAULT 0,
  fiber DECIMAL DEFAULT 0,
  quantity_grams DECIMAL,
  meal_type TEXT,
  food_source TEXT,
  foods JSONB, -- Store array of foods as JSONB
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1.2 Create health_metrics table
CREATE TABLE IF NOT EXISTS public.health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE DEFAULT CURRENT_DATE,
  steps INTEGER DEFAULT 0,
  heart_rate INTEGER,
  sleep_hours DECIMAL,
  calories_burned DECIMAL,
  distance DECIMAL,
  active_minutes INTEGER,
  water_intake DECIMAL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_date UNIQUE(user_id, date),
  CONSTRAINT valid_heart_rate CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250))
);

-- 1.3 Create streaks table
CREATE TABLE IF NOT EXISTS public.streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  streak_type TEXT DEFAULT 'daily',
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  target_achieved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_streak_type UNIQUE(user_id, streak_type)
);

-- 1.4 Create user_goals table
CREATE TABLE IF NOT EXISTS public.user_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL,
  target_value DECIMAL NOT NULL,
  current_value DECIMAL DEFAULT 0,
  unit TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 2: Fix Profiles Table
-- ============================================

-- Add missing columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000,
ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
ADD COLUMN IF NOT EXISTS experience_level TEXT,
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER DEFAULT 10000,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL DEFAULT 8,
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS fitness_goal TEXT,
ADD COLUMN IF NOT EXISTS activity_level TEXT,
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS bmi_value DECIMAL,
ADD COLUMN IF NOT EXISTS bmi_category_value TEXT;

-- Ensure proper data types for existing columns
ALTER TABLE public.profiles
ALTER COLUMN age TYPE INTEGER USING age::INTEGER,
ALTER COLUMN height TYPE DECIMAL USING height::DECIMAL,
ALTER COLUMN weight TYPE DECIMAL USING weight::DECIMAL;

-- STEP 3: Create Views for Aggregated Data
-- ============================================

-- 3.1 Create daily_nutrition_summary view
CREATE OR REPLACE VIEW public.daily_nutrition_summary AS
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
FROM public.nutrition_entries
GROUP BY user_id, date;

-- 3.2 Create user_dashboard view
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
  COALESCE(hm.sleep_hours, 0) as last_night_sleep
FROM public.profiles p
LEFT JOIN public.streaks s ON p.id = s.user_id AND s.streak_type = 'daily'
LEFT JOIN public.health_metrics hm ON p.id = hm.user_id AND hm.date = CURRENT_DATE;

-- STEP 4: Create Indexes for Performance
-- ============================================

-- Indexes for nutrition_entries
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_id ON public.nutrition_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_date ON public.nutrition_entries(date DESC);
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON public.nutrition_entries(user_id, date);

-- Indexes for health_metrics
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_id ON public.health_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_health_metrics_date ON public.health_metrics(date DESC);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON public.health_metrics(user_id, date);

-- Indexes for streaks
CREATE INDEX IF NOT EXISTS idx_streaks_user_id ON public.streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON public.streaks(user_id, streak_type);

-- Indexes for user_goals
CREATE INDEX IF NOT EXISTS idx_user_goals_user_id ON public.user_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_user_goals_user_active ON public.user_goals(user_id, is_active);

-- STEP 5: Enable Row Level Security (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for nutrition_entries
CREATE POLICY "Users can view own nutrition entries"
  ON public.nutrition_entries FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition entries"
  ON public.nutrition_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition entries"
  ON public.nutrition_entries FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition entries"
  ON public.nutrition_entries FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for health_metrics
CREATE POLICY "Users can view own health metrics"
  ON public.health_metrics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health metrics"
  ON public.health_metrics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health metrics"
  ON public.health_metrics FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health metrics"
  ON public.health_metrics FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for streaks
CREATE POLICY "Users can view own streaks"
  ON public.streaks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaks"
  ON public.streaks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks"
  ON public.streaks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own streaks"
  ON public.streaks FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for user_goals
CREATE POLICY "Users can view own goals"
  ON public.user_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals"
  ON public.user_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals"
  ON public.user_goals FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own goals"
  ON public.user_goals FOR DELETE
  USING (auth.uid() = user_id);

-- STEP 6: Create Update Triggers
-- ============================================

-- Create or replace updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all tables
CREATE TRIGGER handle_nutrition_entries_updated_at
  BEFORE UPDATE ON public.nutrition_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_health_metrics_updated_at
  BEFORE UPDATE ON public.health_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_streaks_updated_at
  BEFORE UPDATE ON public.streaks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_user_goals_updated_at
  BEFORE UPDATE ON public.user_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- STEP 7: Verify Installation
-- ============================================

-- Check if all tables exist
DO $$
DECLARE
  table_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'nutrition_entries', 'health_metrics', 'streaks', 'user_goals', 'chat_sessions');

  RAISE NOTICE '✅ Tables created: % out of 6 expected', table_count;

  IF table_count = 6 THEN
    RAISE NOTICE '🎉 All tables successfully created!';
  ELSE
    RAISE NOTICE '⚠️ Some tables may be missing. Please check manually.';
  END IF;
END $$;

-- STEP 8: Grant Permissions
-- ============================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant permissions on tables
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.nutrition_entries TO authenticated;
GRANT ALL ON public.health_metrics TO authenticated;
GRANT ALL ON public.streaks TO authenticated;
GRANT ALL ON public.user_goals TO authenticated;

-- Grant permissions on views
GRANT SELECT ON public.daily_nutrition_summary TO authenticated;
GRANT SELECT ON public.user_dashboard TO authenticated;

-- ============================================
-- MIGRATION COMPLETE!
-- ============================================
--
-- Next Steps:
-- 1. Run this entire script in Supabase SQL Editor
-- 2. Verify all tables are created
-- 3. Test the app functionality
-- 4. Monitor for any errors
--
-- If you encounter any issues, check:
-- - Supabase Dashboard > Database > Tables
-- - Ensure all tables are listed
-- - Check RLS policies are enabled
-- ============================================