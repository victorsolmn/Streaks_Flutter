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
  
  -- Grace Period System (NEW)
  consecutive_missed_days INTEGER DEFAULT 0, -- Track consecutive missed days
  grace_days_used INTEGER DEFAULT 0, -- How many grace days currently used (0-2)
  grace_days_available INTEGER DEFAULT 2, -- Max grace days available (reset to 2 after successful day)
  last_grace_reset_date DATE, -- When grace period was last reset
  
  -- Streak Dates
  streak_start_date DATE,
  last_completed_date DATE,
  last_checked_date DATE,
  last_attempted_date DATE, -- NEW: Last day user tried (even if failed)
  
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

-- Nutrition Entries Table
-- Stores individual food entries for detailed tracking
CREATE TABLE IF NOT EXISTS public.nutrition_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Food Details
  food_name VARCHAR(255) NOT NULL,
  calories INTEGER NOT NULL DEFAULT 0,
  protein DECIMAL(6,2) DEFAULT 0,
  carbs DECIMAL(6,2) DEFAULT 0,
  fat DECIMAL(6,2) DEFAULT 0,
  fiber DECIMAL(6,2) DEFAULT 0,
  
  -- Portion and source info
  quantity_grams INTEGER DEFAULT 100,
  meal_type VARCHAR(50) DEFAULT 'snack', -- breakfast, lunch, dinner, snack
  food_source VARCHAR(100), -- AI recognized, manual entry, etc
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Index for efficient queries
  CONSTRAINT nutrition_entries_user_date_idx 
    UNIQUE(user_id, food_name, created_at)
);

-- Index for fast daily queries
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date 
ON public.nutrition_entries(user_id, DATE(created_at));

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

-- Function to update streak with grace period logic
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
DECLARE
  v_user_streak RECORD;
  v_yesterday DATE;
  v_days_since_completion INTEGER;
  v_new_current_streak INTEGER;
  v_new_longest_streak INTEGER;
BEGIN
  v_yesterday := NEW.date - INTERVAL '1 day';
  
  -- Get or create user streak record
  SELECT * INTO v_user_streak FROM public.user_streaks WHERE user_id = NEW.user_id;
  
  IF v_user_streak IS NULL THEN
    -- Create new streak record
    IF NEW.all_goals_achieved THEN
      -- Start with successful day
      INSERT INTO public.user_streaks (
        user_id,
        current_streak,
        longest_streak,
        total_days_completed,
        consecutive_missed_days,
        grace_days_used,
        grace_days_available,
        streak_start_date,
        last_completed_date,
        last_attempted_date,
        last_grace_reset_date,
        total_steps,
        total_calories_burned
      ) VALUES (
        NEW.user_id,
        1, -- Start streak
        1,
        1,
        0, -- No missed days
        0, -- No grace days used
        2, -- Full grace available
        NEW.date,
        NEW.date,
        NEW.date,
        NEW.date, -- Grace reset on first success
        NEW.steps,
        NEW.calories_burned
      );
    ELSE
      -- Start with failed day
      INSERT INTO public.user_streaks (
        user_id,
        current_streak,
        longest_streak,
        total_days_completed,
        consecutive_missed_days,
        grace_days_used,
        grace_days_available,
        last_attempted_date
      ) VALUES (
        NEW.user_id,
        0, -- No streak yet
        0,
        0,
        1, -- First missed day
        0, -- No grace used yet (no streak to protect)
        2,
        NEW.date
      );
    END IF;
  ELSE
    -- Update existing streak record
    UPDATE public.user_streaks SET last_attempted_date = NEW.date WHERE user_id = NEW.user_id;
    
    -- Calculate days since last completion
    IF v_user_streak.last_completed_date IS NOT NULL THEN
      v_days_since_completion := NEW.date - v_user_streak.last_completed_date;
    ELSE
      v_days_since_completion := 999; -- Large number if never completed
    END IF;
    
    IF NEW.all_goals_achieved THEN
      -- GOALS ACHIEVED - SUCCESS DAY
      
      IF v_days_since_completion = 1 THEN
        -- Perfect continuation (yesterday was completed)
        v_new_current_streak := v_user_streak.current_streak + 1;
        
      ELSIF v_days_since_completion <= 3 AND v_user_streak.current_streak > 0 THEN
        -- Recovery within grace period (2-3 days gap)
        -- Continue streak if we haven't exceeded grace limit
        IF v_days_since_completion - 1 <= v_user_streak.grace_days_available THEN
          v_new_current_streak := v_user_streak.current_streak + 1;
        ELSE
          -- Exceeded grace period, start new streak
          v_new_current_streak := 1;
        END IF;
        
      ELSE
        -- Too long gap or no previous streak, start new
        v_new_current_streak := 1;
      END IF;
      
      v_new_longest_streak := GREATEST(v_user_streak.longest_streak, v_new_current_streak);
      
      -- Update streak with success
      UPDATE public.user_streaks
      SET
        current_streak = v_new_current_streak,
        longest_streak = v_new_longest_streak,
        total_days_completed = total_days_completed + 1,
        consecutive_missed_days = 0, -- Reset missed days
        grace_days_used = 0, -- Reset grace days
        grace_days_available = 2, -- Restore full grace
        last_completed_date = NEW.date,
        last_grace_reset_date = NEW.date,
        total_steps = total_steps + NEW.steps,
          total_calories_burned = total_calories_burned + NEW.calories_burned,
        updated_at = NOW()
      WHERE user_id = NEW.user_id;
      
    ELSE
      -- GOALS NOT ACHIEVED - FAILURE DAY
      
      IF v_user_streak.current_streak > 0 THEN
        -- User has an active streak to protect
        
        -- Calculate consecutive missed days
        v_days_since_completion := COALESCE(NEW.date - v_user_streak.last_completed_date, 1);
        
        IF v_days_since_completion <= 2 THEN
          -- Within grace period (1-2 days missed)
          -- Keep streak alive, use grace days
          UPDATE public.user_streaks
          SET
            consecutive_missed_days = v_days_since_completion,
            grace_days_used = v_days_since_completion,
            updated_at = NOW()
          WHERE user_id = NEW.user_id;
          
        ELSE
          -- Exceeded grace period (3+ days missed)
          -- Lose streak completely
          UPDATE public.user_streaks
          SET
            current_streak = 0,
            consecutive_missed_days = v_days_since_completion,
            grace_days_used = 0, -- Reset for next streak attempt
            grace_days_available = 2,
            streak_start_date = NULL,
            updated_at = NOW()
          WHERE user_id = NEW.user_id;
        END IF;
        
      ELSE
        -- No active streak, just track missed days
        UPDATE public.user_streaks
        SET
          consecutive_missed_days = consecutive_missed_days + 1,
          updated_at = NOW()
        WHERE user_id = NEW.user_id;
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update streaks (fires for both success and failure)
CREATE TRIGGER update_streak_on_metrics_change
  AFTER INSERT OR UPDATE ON public.user_daily_metrics
  FOR EACH ROW
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