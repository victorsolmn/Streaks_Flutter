-- Streaks Flutter App - Supabase Database Setup
-- Run this entire script in your Supabase SQL Editor

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  age INTEGER,
  height DECIMAL,
  weight DECIMAL,
  activity_level TEXT,
  fitness_goal TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 2. Create nutrition_entries table
CREATE TABLE IF NOT EXISTS nutrition_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  calories INTEGER DEFAULT 0,
  protein DECIMAL DEFAULT 0,
  carbs DECIMAL DEFAULT 0,
  fat DECIMAL DEFAULT 0,
  fiber DECIMAL DEFAULT 0,
  water INTEGER DEFAULT 0,
  food_items JSONB, -- Store individual food items as JSON
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, date)
);

-- 3. Create health_metrics table
CREATE TABLE IF NOT EXISTS health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  steps INTEGER DEFAULT 0,
  heart_rate INTEGER,
  sleep_hours DECIMAL,
  calories_burned INTEGER,
  distance DECIMAL,
  active_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, date)
);

-- 4. Create streaks table
CREATE TABLE IF NOT EXISTS streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  streak_type TEXT DEFAULT 'workout', -- workout, nutrition, meditation, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, streak_type)
);

-- 5. Create workouts table
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  workout_type TEXT,
  duration_minutes INTEGER,
  calories_burned INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 6. Create weight_logs table for tracking weight changes
CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  weight DECIMAL NOT NULL,
  unit TEXT DEFAULT 'kg',
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 7. Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 9. Create RLS Policies for nutrition_entries
CREATE POLICY "Users can view own nutrition" ON nutrition_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition" ON nutrition_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition" ON nutrition_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition" ON nutrition_entries
  FOR DELETE USING (auth.uid() = user_id);

-- 10. Create RLS Policies for health_metrics
CREATE POLICY "Users can view own health metrics" ON health_metrics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health metrics" ON health_metrics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health metrics" ON health_metrics
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health metrics" ON health_metrics
  FOR DELETE USING (auth.uid() = user_id);

-- 11. Create RLS Policies for streaks
CREATE POLICY "Users can view own streaks" ON streaks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own streaks" ON streaks
  FOR ALL USING (auth.uid() = user_id);

-- 12. Create RLS Policies for workouts
CREATE POLICY "Users can manage own workouts" ON workouts
  FOR ALL USING (auth.uid() = user_id);

-- 13. Create RLS Policies for weight_logs
CREATE POLICY "Users can manage own weight logs" ON weight_logs
  FOR ALL USING (auth.uid() = user_id);

-- 14. Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 15. Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nutrition_entries_updated_at BEFORE UPDATE ON nutrition_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_streaks_updated_at BEFORE UPDATE ON streaks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 16. Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create profile for new user
  INSERT INTO profiles (id, email, name)
  VALUES (
    NEW.id, 
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  
  -- Initialize streak record
  INSERT INTO streaks (user_id, streak_type)
  VALUES (NEW.id, 'workout');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 18. Create view for user statistics (optional but useful)
CREATE OR REPLACE VIEW user_stats AS
SELECT 
  p.id as user_id,
  p.name,
  p.email,
  COALESCE(s.current_streak, 0) as current_streak,
  COALESCE(s.longest_streak, 0) as longest_streak,
  COALESCE(n.total_calories, 0) as today_calories,
  COALESCE(h.today_steps, 0) as today_steps
FROM profiles p
LEFT JOIN streaks s ON p.id = s.user_id AND s.streak_type = 'workout'
LEFT JOIN LATERAL (
  SELECT SUM(calories) as total_calories 
  FROM nutrition_entries 
  WHERE user_id = p.id AND date = CURRENT_DATE
) n ON true
LEFT JOIN LATERAL (
  SELECT steps as today_steps 
  FROM health_metrics 
  WHERE user_id = p.id AND date = CURRENT_DATE
  LIMIT 1
) h ON true;

-- 19. Grant permissions on the view
GRANT SELECT ON user_stats TO authenticated;

-- 20. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON nutrition_entries(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON health_metrics(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_user_date ON workouts(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_time ON weight_logs(user_id, logged_at DESC);

-- Success! Your database is ready.
-- You can verify the tables in the Table Editor tab