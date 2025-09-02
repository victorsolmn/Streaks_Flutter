-- Supabase Schema for Streaks Flutter App
-- This creates all necessary tables for tracking user metrics and streaks

-- Enable RLS (Row Level Security) for all tables
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- User Daily Metrics Table
-- Stores all daily health and nutrition metrics for each user
CREATE TABLE IF NOT EXISTS public.user_daily_metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  
  -- Health Metrics
  steps INTEGER DEFAULT 0,
  calories_burned INTEGER DEFAULT 0,
  heart_rate INTEGER DEFAULT 0,
  sleep_hours DECIMAL(3,1) DEFAULT 0,
  distance DECIMAL(5,2) DEFAULT 0,
  water_glasses INTEGER DEFAULT 0,
  workouts INTEGER DEFAULT 0,
  
  -- Nutrition Metrics
  calories_consumed INTEGER DEFAULT 0,
  protein DECIMAL(5,1) DEFAULT 0,
  carbs DECIMAL(5,1) DEFAULT 0,
  fat DECIMAL(5,1) DEFAULT 0,
  fiber DECIMAL(5,1) DEFAULT 0,
  
  -- Weight Tracking
  weight DECIMAL(5,2),
  
  -- Goals for this day (can be different per day)
  steps_goal INTEGER DEFAULT 10000,
  calories_goal INTEGER DEFAULT 2000,
  sleep_goal DECIMAL(3,1) DEFAULT 8.0,
  water_goal INTEGER DEFAULT 8,
  protein_goal DECIMAL(5,1) DEFAULT 50,
  
  -- Goal Achievement Flags
  steps_achieved BOOLEAN DEFAULT FALSE,
  calories_achieved BOOLEAN DEFAULT FALSE,
  sleep_achieved BOOLEAN DEFAULT FALSE,
  water_achieved BOOLEAN DEFAULT FALSE,
  nutrition_achieved BOOLEAN DEFAULT FALSE,
  
  -- Overall daily goal achievement
  all_goals_achieved BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one entry per user per day
  UNIQUE(user_id, date)
);

-- User Streaks Table
-- Tracks streak history and current streak status
CREATE TABLE IF NOT EXISTS public.user_streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  
  -- Current Streak Info
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_days_completed INTEGER DEFAULT 0,
  
  -- Streak Dates
  streak_start_date DATE,
  last_completed_date DATE,
  last_checked_date DATE,
  
  -- Statistics
  total_steps BIGINT DEFAULT 0,
  total_calories_burned BIGINT DEFAULT 0,
  total_workouts INTEGER DEFAULT 0,
  average_sleep DECIMAL(3,1) DEFAULT 0,
  
  -- Achievements
  perfect_weeks INTEGER DEFAULT 0, -- 7 consecutive days
  perfect_months INTEGER DEFAULT 0, -- 30 consecutive days
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Streak History Table
-- Keeps a log of all streak achievements
CREATE TABLE IF NOT EXISTS public.streak_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  streak_day INTEGER NOT NULL,
  
  -- What goals were achieved
  goals_achieved JSONB DEFAULT '{}',
  
  -- Metrics snapshot for this day
  metrics JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, date)
);

-- User Goals Settings Table
-- Stores personalized goals for each user
CREATE TABLE IF NOT EXISTS public.user_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  
  -- Daily Goals
  daily_steps_goal INTEGER DEFAULT 10000,
  daily_calories_goal INTEGER DEFAULT 2000,
  daily_sleep_goal DECIMAL(3,1) DEFAULT 8.0,
  daily_water_goal INTEGER DEFAULT 8,
  daily_protein_goal DECIMAL(5,1) DEFAULT 50,
  daily_carbs_goal DECIMAL(5,1) DEFAULT 250,
  daily_fat_goal DECIMAL(5,1) DEFAULT 65,
  
  -- Weight Goals
  target_weight DECIMAL(5,2),
  weight_goal_type VARCHAR(20) DEFAULT 'maintain', -- 'lose', 'gain', 'maintain'
  
  -- Activity Goals
  weekly_workout_goal INTEGER DEFAULT 3,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_user_daily_metrics_user_date ON public.user_daily_metrics(user_id, date DESC);
CREATE INDEX idx_user_daily_metrics_date ON public.user_daily_metrics(date);
CREATE INDEX idx_streak_history_user_date ON public.streak_history(user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE public.user_daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
-- Users can only access their own data
CREATE POLICY "Users can view own metrics" ON public.user_daily_metrics
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own streaks" ON public.user_streaks
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own streak history" ON public.streak_history
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own goals" ON public.user_goals
  FOR ALL USING (auth.uid() = user_id);

-- Function to calculate if all goals are achieved
CREATE OR REPLACE FUNCTION check_daily_goals_achieved()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if all individual goals are met
  NEW.steps_achieved := NEW.steps >= NEW.steps_goal;
  NEW.calories_achieved := NEW.calories_consumed <= NEW.calories_goal;
  NEW.sleep_achieved := NEW.sleep_hours >= NEW.sleep_goal;
  NEW.water_achieved := NEW.water_glasses >= NEW.water_goal;
  NEW.nutrition_achieved := NEW.calories_consumed > 0; -- Has logged food
  
  -- All goals must be achieved for streak
  NEW.all_goals_achieved := 
    NEW.steps_achieved AND 
    NEW.calories_achieved AND 
    NEW.sleep_achieved AND 
    NEW.water_achieved AND 
    NEW.nutrition_achieved;
  
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically check goals
CREATE TRIGGER check_goals_on_update
  BEFORE INSERT OR UPDATE ON public.user_daily_metrics
  FOR EACH ROW
  EXECUTE FUNCTION check_daily_goals_achieved();

-- Function to update streak when goals are achieved
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
DECLARE
  v_user_streak RECORD;
  v_yesterday DATE;
  v_streak_continues BOOLEAN;
BEGIN
  -- Only process if all goals are achieved
  IF NEW.all_goals_achieved THEN
    v_yesterday := NEW.date - INTERVAL '1 day';
    
    -- Get or create user streak record
    SELECT * INTO v_user_streak FROM public.user_streaks WHERE user_id = NEW.user_id;
    
    IF v_user_streak IS NULL THEN
      -- Create new streak record
      INSERT INTO public.user_streaks (
        user_id,
        current_streak,
        longest_streak,
        total_days_completed,
        streak_start_date,
        last_completed_date,
        total_steps,
        total_calories_burned
      ) VALUES (
        NEW.user_id,
        1,
        1,
        1,
        NEW.date,
        NEW.date,
        NEW.steps,
        NEW.calories_burned
      );
    ELSE
      -- Check if streak continues from yesterday
      v_streak_continues := v_user_streak.last_completed_date = v_yesterday;
      
      IF v_streak_continues THEN
        -- Continue streak
        UPDATE public.user_streaks
        SET
          current_streak = current_streak + 1,
          longest_streak = GREATEST(longest_streak, current_streak + 1),
          total_days_completed = total_days_completed + 1,
          last_completed_date = NEW.date,
          total_steps = total_steps + NEW.steps,
          total_calories_burned = total_calories_burned + NEW.calories_burned,
          updated_at = NOW()
        WHERE user_id = NEW.user_id;
      ELSIF v_user_streak.last_completed_date < NEW.date THEN
        -- Streak broken, start new
        UPDATE public.user_streaks
        SET
          current_streak = 1,
          total_days_completed = total_days_completed + 1,
          streak_start_date = NEW.date,
          last_completed_date = NEW.date,
          total_steps = total_steps + NEW.steps,
          total_calories_burned = total_calories_burned + NEW.calories_burned,
          updated_at = NOW()
        WHERE user_id = NEW.user_id;
      END IF;
    END IF;
    
    -- Log to streak history
    INSERT INTO public.streak_history (user_id, date, streak_day, goals_achieved, metrics)
    VALUES (
      NEW.user_id,
      NEW.date,
      COALESCE(v_user_streak.current_streak, 0) + 1,
      jsonb_build_object(
        'steps', NEW.steps_achieved,
        'calories', NEW.calories_achieved,
        'sleep', NEW.sleep_achieved,
        'water', NEW.water_achieved,
        'nutrition', NEW.nutrition_achieved
      ),
      jsonb_build_object(
        'steps', NEW.steps,
        'calories_burned', NEW.calories_burned,
        'calories_consumed', NEW.calories_consumed,
        'sleep', NEW.sleep_hours,
        'water', NEW.water_glasses
      )
    ) ON CONFLICT (user_id, date) DO UPDATE
    SET
      goals_achieved = EXCLUDED.goals_achieved,
      metrics = EXCLUDED.metrics;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update streaks
CREATE TRIGGER update_streak_on_goals_achieved
  AFTER INSERT OR UPDATE ON public.user_daily_metrics
  FOR EACH ROW
  WHEN (NEW.all_goals_achieved = TRUE)
  EXECUTE FUNCTION update_user_streak();

-- Function to get current user stats
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE (
  current_streak INTEGER,
  longest_streak INTEGER,
  total_days INTEGER,
  todays_progress JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.current_streak,
    s.longest_streak,
    s.total_days_completed,
    json_build_object(
      'steps', m.steps,
      'steps_goal', m.steps_goal,
      'calories', m.calories_consumed,
      'calories_goal', m.calories_goal,
      'sleep', m.sleep_hours,
      'sleep_goal', m.sleep_goal,
      'water', m.water_glasses,
      'water_goal', m.water_goal,
      'all_goals_achieved', m.all_goals_achieved
    ) as todays_progress
  FROM public.user_streaks s
  LEFT JOIN public.user_daily_metrics m ON m.user_id = s.user_id AND m.date = CURRENT_DATE
  WHERE s.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Real-time subscriptions
-- Enable realtime for the tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_daily_metrics;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_streaks;