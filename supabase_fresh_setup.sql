-- ===================================================
-- COMPLETE SUPABASE DATABASE SETUP FOR STREAKS APP
-- ===================================================
-- Run this entire script in your new Supabase SQL Editor

-- ===================================================
-- 1. PROFILES TABLE (Main user profile data)
-- ===================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  -- Primary key using Supabase Auth user ID
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Basic profile information
  name TEXT,
  email TEXT NOT NULL,
  phone TEXT,
  date_of_birth DATE,
  gender TEXT,

  -- Physical measurements
  age INTEGER,
  height DECIMAL(5,2), -- in cm
  weight DECIMAL(5,2), -- in kg

  -- Activity and fitness information
  activity_level TEXT,
  fitness_goal TEXT,
  experience_level TEXT,

  -- Workout preferences
  preferred_workout_time TEXT,
  workout_days_per_week INTEGER,

  -- Onboarding status
  has_completed_onboarding BOOLEAN DEFAULT false,

  -- Profile metadata
  profile_picture_url TEXT,
  bio TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add constraints for data validation
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_age_check
    CHECK (age IS NULL OR (age >= 13 AND age <= 120)),
  ADD CONSTRAINT profiles_height_check
    CHECK (height IS NULL OR (height >= 50 AND height <= 300)),
  ADD CONSTRAINT profiles_weight_check
    CHECK (weight IS NULL OR (weight >= 20 AND weight <= 500)),
  ADD CONSTRAINT profiles_activity_level_check
    CHECK (activity_level IS NULL OR activity_level IN (
      'Sedentary',
      'Lightly Active',
      'Moderately Active',
      'Very Active',
      'Extra Active'
    )),
  ADD CONSTRAINT profiles_fitness_goal_check
    CHECK (fitness_goal IS NULL OR fitness_goal IN (
      'Lose Weight',
      'Maintain Weight',
      'Gain Muscle',
      'Improve Fitness',
      'Build Strength'
    )),
  ADD CONSTRAINT profiles_experience_level_check
    CHECK (experience_level IS NULL OR experience_level IN (
      'Beginner',
      'Intermediate',
      'Advanced'
    )),
  ADD CONSTRAINT profiles_gender_check
    CHECK (gender IS NULL OR gender IN ('Male', 'Female', 'Other'));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding ON public.profiles(has_completed_onboarding);
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON public.profiles(updated_at);

-- ===================================================
-- 2. NUTRITION TABLE
-- ===================================================

CREATE TABLE IF NOT EXISTS public.nutrition (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Date tracking
  date DATE NOT NULL,

  -- Nutrition data
  calories INTEGER,
  protein DECIMAL(8,2),
  carbs DECIMAL(8,2),
  fat DECIMAL(8,2),
  fiber DECIMAL(8,2),
  sugar DECIMAL(8,2),
  sodium DECIMAL(8,2),
  water_intake DECIMAL(8,2), -- in liters

  -- Meal tracking
  meals JSONB DEFAULT '[]'::jsonb,

  -- Goals
  calorie_goal INTEGER,
  protein_goal DECIMAL(8,2),
  carbs_goal DECIMAL(8,2),
  fat_goal DECIMAL(8,2),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint to prevent duplicate entries per user per day
  UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_user_date ON public.nutrition(user_id, date);

-- ===================================================
-- 3. HEALTH METRICS TABLE
-- ===================================================

CREATE TABLE IF NOT EXISTS public.health_metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Date and time tracking
  date DATE NOT NULL,
  time TIME,

  -- Vital signs
  heart_rate INTEGER,
  blood_pressure_systolic INTEGER,
  blood_pressure_diastolic INTEGER,
  blood_oxygen DECIMAL(5,2),
  body_temperature DECIMAL(5,2),

  -- Activity metrics
  steps INTEGER,
  distance DECIMAL(8,2), -- in km
  active_minutes INTEGER,
  calories_burned INTEGER,
  floors_climbed INTEGER,

  -- Sleep metrics
  sleep_hours DECIMAL(4,2),
  sleep_quality INTEGER, -- 1-10 scale
  deep_sleep_hours DECIMAL(4,2),
  rem_sleep_hours DECIMAL(4,2),

  -- Body measurements
  body_weight DECIMAL(5,2), -- in kg
  body_fat_percentage DECIMAL(5,2),
  muscle_mass DECIMAL(5,2), -- in kg

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint to prevent duplicate entries per user per day
  UNIQUE(user_id, date)
);

-- Add constraint for heart rate (fixing the issue from before)
ALTER TABLE public.health_metrics
  ADD CONSTRAINT health_metrics_heart_rate_check
    CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250));

CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON public.health_metrics(user_id, date);

-- ===================================================
-- 4. STREAKS TABLE
-- ===================================================

CREATE TABLE IF NOT EXISTS public.streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Streak data
  streak_type TEXT NOT NULL, -- 'workout', 'nutrition', 'meditation', etc.
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint to prevent duplicate streak types per user
  UNIQUE(user_id, streak_type)
);

CREATE INDEX IF NOT EXISTS idx_streaks_user ON public.streaks(user_id);

-- ===================================================
-- 5. WORKOUTS TABLE
-- ===================================================

CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Workout details
  name TEXT NOT NULL,
  date DATE NOT NULL,
  duration_minutes INTEGER,
  type TEXT, -- 'cardio', 'strength', 'flexibility', 'mixed'
  intensity TEXT, -- 'low', 'moderate', 'high'
  calories_burned INTEGER,

  -- Exercises (stored as JSON array)
  exercises JSONB DEFAULT '[]'::jsonb,

  -- Notes
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_date ON public.workouts(user_id, date);

-- ===================================================
-- 6. UPDATED_AT TRIGGER FUNCTION
-- ===================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nutrition_updated_at BEFORE UPDATE ON public.nutrition
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_metrics_updated_at BEFORE UPDATE ON public.health_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_streaks_updated_at BEFORE UPDATE ON public.streaks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON public.workouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ===================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

-- Profiles table policies
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Nutrition table policies
CREATE POLICY "Users can manage their own nutrition data" ON public.nutrition
    FOR ALL USING (auth.uid() = user_id);

-- Health metrics table policies
CREATE POLICY "Users can manage their own health metrics" ON public.health_metrics
    FOR ALL USING (auth.uid() = user_id);

-- Streaks table policies
CREATE POLICY "Users can manage their own streaks" ON public.streaks
    FOR ALL USING (auth.uid() = user_id);

-- Workouts table policies
CREATE POLICY "Users can manage their own workouts" ON public.workouts
    FOR ALL USING (auth.uid() = user_id);

-- ===================================================
-- 8. INITIAL PROFILE CREATION FUNCTION
-- ===================================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ===================================================
-- 9. GRANT PERMISSIONS
-- ===================================================

-- Grant permissions to authenticated users
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.nutrition TO authenticated;
GRANT ALL ON public.health_metrics TO authenticated;
GRANT ALL ON public.streaks TO authenticated;
GRANT ALL ON public.workouts TO authenticated;

-- Grant select permissions to anon users (for checking if user exists)
GRANT SELECT ON public.profiles TO anon;

-- ===================================================
-- VERIFICATION QUERIES
-- ===================================================

-- Check all tables were created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;