-- ============================================
-- CALORIE TRACKING SYSTEM - Complete Implementation
-- Created: September 25, 2025
-- Description: Comprehensive calorie tracking with session-based calculation
-- ============================================

-- STEP 1: Create calorie_sessions table for granular tracking
-- ============================================
CREATE TABLE IF NOT EXISTS public.calorie_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Temporal data
  session_date DATE NOT NULL,
  session_start TIMESTAMPTZ NOT NULL,
  session_end TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (session_end - session_start))::INTEGER / 60
  ) STORED,

  -- Calorie breakdown
  bmr_calories DECIMAL(10,2) NOT NULL DEFAULT 0,
  active_calories DECIMAL(10,2) NOT NULL DEFAULT 0,
  exercise_calories DECIMAL(10,2) DEFAULT 0,
  total_calories DECIMAL(10,2) GENERATED ALWAYS AS (
    bmr_calories + active_calories + exercise_calories
  ) STORED,

  -- Activity data
  steps INTEGER DEFAULT 0,
  distance_meters DECIMAL(10,2) DEFAULT 0,
  floors_climbed INTEGER DEFAULT 0,

  -- Heart rate data
  avg_heart_rate INTEGER,
  max_heart_rate INTEGER,
  min_heart_rate INTEGER,
  heart_rate_samples JSONB,

  -- Exercise data
  exercise_type TEXT,
  exercise_name TEXT,
  exercise_intensity TEXT CHECK (exercise_intensity IN ('light', 'moderate', 'vigorous', NULL)),

  -- Metadata
  segment_type TEXT NOT NULL CHECK (segment_type IN ('realtime', 'retroactive', 'exercise', 'sleep', 'rest')),
  data_source TEXT NOT NULL CHECK (data_source IN ('samsung_health', 'google_fit', 'apple_health', 'manual', 'calculated')),
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  device_model TEXT,
  app_version TEXT,

  -- Quality indicators
  confidence_score DECIMAL(3,2) DEFAULT 1.0 CHECK (confidence_score >= 0 AND confidence_score <= 1),
  is_estimated BOOLEAN DEFAULT FALSE,
  is_manual_entry BOOLEAN DEFAULT FALSE,

  -- Sync tracking
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),

  -- Prevent duplicates
  CONSTRAINT unique_user_session UNIQUE(user_id, session_start, session_end)
);

-- STEP 2: Create daily_calorie_totals table for aggregated data
-- ============================================
CREATE TABLE IF NOT EXISTS public.daily_calorie_totals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Daily totals
  total_bmr_calories DECIMAL(10,2) DEFAULT 0,
  total_active_calories DECIMAL(10,2) DEFAULT 0,
  total_exercise_calories DECIMAL(10,2) DEFAULT 0,
  total_calories DECIMAL(10,2) DEFAULT 0,

  -- Activity summary
  total_steps INTEGER DEFAULT 0,
  total_distance_meters DECIMAL(10,2) DEFAULT 0,
  total_floors INTEGER DEFAULT 0,
  active_minutes INTEGER DEFAULT 0,
  sedentary_minutes INTEGER DEFAULT 0,

  -- Heart rate summary
  avg_heart_rate INTEGER,
  max_heart_rate INTEGER,
  min_heart_rate INTEGER,
  resting_heart_rate INTEGER,

  -- Exercise summary
  exercise_minutes INTEGER DEFAULT 0,
  exercise_types JSONB DEFAULT '[]'::JSONB,

  -- Session counts
  session_count INTEGER DEFAULT 0,
  exercise_session_count INTEGER DEFAULT 0,
  app_open_count INTEGER DEFAULT 0,

  -- Timing
  first_activity_time TIME,
  last_activity_time TIME,
  most_active_hour INTEGER CHECK (most_active_hour >= 0 AND most_active_hour <= 23),

  -- Data quality
  data_completeness DECIMAL(3,2) DEFAULT 0.0 CHECK (data_completeness >= 0 AND data_completeness <= 1),
  has_full_day_data BOOLEAN DEFAULT FALSE,
  missing_hours INTEGER[] DEFAULT ARRAY[]::INTEGER[],

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_sync_at TIMESTAMPTZ,

  CONSTRAINT unique_user_daily UNIQUE(user_id, date)
);

-- STEP 3: Create indexes for performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_calorie_sessions_user_date
  ON calorie_sessions(user_id, session_date DESC);

CREATE INDEX IF NOT EXISTS idx_calorie_sessions_start
  ON calorie_sessions(session_start DESC);

CREATE INDEX IF NOT EXISTS idx_calorie_sessions_exercise
  ON calorie_sessions(user_id, exercise_type)
  WHERE exercise_type IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_calorie_sessions_sync
  ON calorie_sessions(sync_status, synced_at)
  WHERE sync_status = 'pending';

CREATE INDEX IF NOT EXISTS idx_daily_totals_user_date
  ON daily_calorie_totals(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_totals_sync
  ON daily_calorie_totals(user_id, last_sync_at DESC);

-- STEP 4: Create aggregation function
-- ============================================
CREATE OR REPLACE FUNCTION calculate_daily_calorie_totals(
  p_user_id UUID,
  p_date DATE
) RETURNS VOID AS $$
DECLARE
  v_total_calories DECIMAL(10,2);
  v_session_count INTEGER;
  v_data_completeness DECIMAL(3,2);
  v_has_full_day BOOLEAN;
BEGIN
  -- Calculate aggregates from calorie_sessions
  WITH daily_stats AS (
    SELECT
      COALESCE(SUM(bmr_calories), 0) as total_bmr,
      COALESCE(SUM(active_calories), 0) as total_active,
      COALESCE(SUM(exercise_calories), 0) as total_exercise,
      COALESCE(SUM(total_calories), 0) as total_cal,
      COALESCE(SUM(steps), 0) as total_steps,
      COALESCE(SUM(distance_meters), 0) as total_distance,
      COALESCE(SUM(floors_climbed), 0) as total_floors,
      COALESCE(AVG(avg_heart_rate)::INTEGER, 0) as avg_hr,
      COALESCE(MAX(max_heart_rate), 0) as max_hr,
      COALESCE(MIN(NULLIF(min_heart_rate, 0)), 0) as min_hr,
      COUNT(*) as session_count,
      COUNT(CASE WHEN exercise_type IS NOT NULL THEN 1 END) as exercise_count,
      MIN(session_start::TIME) as first_activity,
      MAX(session_end::TIME) as last_activity,
      COALESCE(SUM(CASE WHEN exercise_type IS NOT NULL THEN duration_minutes END), 0) as exercise_mins
    FROM calorie_sessions
    WHERE user_id = p_user_id AND session_date = p_date
  ),
  coverage_stats AS (
    SELECT
      COUNT(DISTINCT EXTRACT(HOUR FROM session_start)) as hours_covered
    FROM calorie_sessions
    WHERE user_id = p_user_id AND session_date = p_date
  )
  INSERT INTO daily_calorie_totals (
    user_id, date,
    total_bmr_calories, total_active_calories, total_exercise_calories, total_calories,
    total_steps, total_distance_meters, total_floors,
    avg_heart_rate, max_heart_rate, min_heart_rate,
    session_count, exercise_session_count,
    first_activity_time, last_activity_time,
    exercise_minutes,
    data_completeness, has_full_day_data,
    updated_at
  )
  SELECT
    p_user_id, p_date,
    ds.total_bmr, ds.total_active, ds.total_exercise, ds.total_cal,
    ds.total_steps, ds.total_distance, ds.total_floors,
    ds.avg_hr, ds.max_hr, ds.min_hr,
    ds.session_count, ds.exercise_count,
    ds.first_activity, ds.last_activity,
    ds.exercise_mins,
    LEAST(cs.hours_covered::DECIMAL / 24, 1.0),
    CASE
      WHEN cs.hours_covered >= 20
       AND ds.first_activity <= '02:00:00'::TIME
       AND ds.last_activity >= '22:00:00'::TIME
      THEN TRUE
      ELSE FALSE
    END,
    NOW()
  FROM daily_stats ds, coverage_stats cs
  ON CONFLICT (user_id, date) DO UPDATE SET
    total_bmr_calories = EXCLUDED.total_bmr_calories,
    total_active_calories = EXCLUDED.total_active_calories,
    total_exercise_calories = EXCLUDED.total_exercise_calories,
    total_calories = EXCLUDED.total_calories,
    total_steps = EXCLUDED.total_steps,
    total_distance_meters = EXCLUDED.total_distance_meters,
    total_floors = EXCLUDED.total_floors,
    avg_heart_rate = EXCLUDED.avg_heart_rate,
    max_heart_rate = EXCLUDED.max_heart_rate,
    min_heart_rate = EXCLUDED.min_heart_rate,
    session_count = EXCLUDED.session_count,
    exercise_session_count = EXCLUDED.exercise_session_count,
    first_activity_time = EXCLUDED.first_activity_time,
    last_activity_time = EXCLUDED.last_activity_time,
    exercise_minutes = EXCLUDED.exercise_minutes,
    data_completeness = EXCLUDED.data_completeness,
    has_full_day_data = EXCLUDED.has_full_day_data,
    updated_at = NOW();

  -- Update health_metrics table for backward compatibility
  SELECT total_calories INTO v_total_calories
  FROM daily_calorie_totals
  WHERE user_id = p_user_id AND date = p_date;

  UPDATE health_metrics
  SET
    calories_burned = v_total_calories,
    updated_at = NOW()
  WHERE user_id = p_user_id AND date = p_date;

  -- If no health_metrics entry exists, create one
  INSERT INTO health_metrics (user_id, date, calories_burned)
  VALUES (p_user_id, p_date, v_total_calories)
  ON CONFLICT (user_id, date) DO NOTHING;

END;
$$ LANGUAGE plpgsql;

-- STEP 5: Create trigger for automatic aggregation
-- ============================================
CREATE OR REPLACE FUNCTION trigger_calculate_daily_totals()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate if the session is marked as synced
  IF NEW.sync_status = 'synced' THEN
    PERFORM calculate_daily_calorie_totals(NEW.user_id, NEW.session_date);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_calculate_daily_totals
AFTER INSERT OR UPDATE ON calorie_sessions
FOR EACH ROW
EXECUTE FUNCTION trigger_calculate_daily_totals();

-- STEP 6: Create RLS policies
-- ============================================
ALTER TABLE calorie_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_calorie_totals ENABLE ROW LEVEL SECURITY;

-- Policies for calorie_sessions
CREATE POLICY "Users can view own calorie sessions"
  ON calorie_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own calorie sessions"
  ON calorie_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own calorie sessions"
  ON calorie_sessions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for daily_calorie_totals
CREATE POLICY "Users can view own daily totals"
  ON daily_calorie_totals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily totals"
  ON daily_calorie_totals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily totals"
  ON daily_calorie_totals FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- STEP 7: Create helper functions
-- ============================================

-- Function to get last sync time for a user
CREATE OR REPLACE FUNCTION get_last_calorie_sync(p_user_id UUID)
RETURNS TIMESTAMPTZ AS $$
BEGIN
  RETURN (
    SELECT MAX(session_end)
    FROM calorie_sessions
    WHERE user_id = p_user_id
      AND session_date = CURRENT_DATE
      AND sync_status = 'synced'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to check if daily data is complete
CREATE OR REPLACE FUNCTION check_daily_data_completeness(
  p_user_id UUID,
  p_date DATE
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'has_data', EXISTS(
      SELECT 1 FROM calorie_sessions
      WHERE user_id = p_user_id AND session_date = p_date
    ),
    'session_count', COUNT(*),
    'hours_covered', COUNT(DISTINCT EXTRACT(HOUR FROM session_start)),
    'total_calories', COALESCE(SUM(total_calories), 0),
    'completeness',
      CASE
        WHEN COUNT(DISTINCT EXTRACT(HOUR FROM session_start)) >= 20 THEN 'complete'
        WHEN COUNT(DISTINCT EXTRACT(HOUR FROM session_start)) >= 12 THEN 'partial'
        ELSE 'minimal'
      END
  ) INTO v_result
  FROM calorie_sessions
  WHERE user_id = p_user_id AND session_date = p_date;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- STEP 8: Create view for easy querying
-- ============================================
CREATE OR REPLACE VIEW user_calorie_dashboard AS
SELECT
  dct.user_id,
  dct.date,
  dct.total_calories,
  dct.total_bmr_calories,
  dct.total_active_calories,
  dct.total_exercise_calories,
  dct.total_steps,
  dct.total_distance_meters,
  dct.exercise_minutes,
  dct.session_count,
  dct.data_completeness,
  dct.has_full_day_data,
  p.name as user_name,
  p.weight,
  p.height,
  p.age,
  p.daily_calories_target
FROM daily_calorie_totals dct
JOIN profiles p ON dct.user_id = p.id
WHERE dct.date >= CURRENT_DATE - INTERVAL '30 days';

-- STEP 9: Migrate existing data (if any)
-- ============================================
DO $$
BEGIN
  -- Check if health_metrics has data to migrate
  IF EXISTS (
    SELECT 1 FROM health_metrics
    WHERE calories_burned IS NOT NULL
      AND calories_burned > 0
    LIMIT 1
  ) THEN
    -- Create basic daily entries from existing data
    INSERT INTO daily_calorie_totals (
      user_id, date, total_calories,
      data_completeness, has_full_day_data,
      created_at, updated_at
    )
    SELECT
      user_id,
      date,
      calories_burned,
      0.5, -- Assume partial data
      FALSE, -- Not full day data
      NOW(),
      NOW()
    FROM health_metrics
    WHERE calories_burned IS NOT NULL
      AND calories_burned > 0
    ON CONFLICT (user_id, date) DO NOTHING;

    RAISE NOTICE 'Migrated existing calorie data to new tables';
  END IF;
END $$;

-- STEP 10: Grant permissions
-- ============================================
GRANT ALL ON calorie_sessions TO authenticated;
GRANT ALL ON daily_calorie_totals TO authenticated;
GRANT SELECT ON user_calorie_dashboard TO authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Calorie tracking system successfully installed!';
  RAISE NOTICE '   - calorie_sessions table created';
  RAISE NOTICE '   - daily_calorie_totals table created';
  RAISE NOTICE '   - Aggregation functions created';
  RAISE NOTICE '   - RLS policies enabled';
  RAISE NOTICE '   - Indexes created for performance';
  RAISE NOTICE '   - Ready for use!';
END $$;