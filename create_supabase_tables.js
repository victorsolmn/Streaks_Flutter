const https = require('https');

const SUPABASE_URL = 'njlafkaqjjtozdbiwjtj.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbGFma2Fxamp0b3pkYml3anRqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjEzMjEzMSwiZXhwIjoyMDcxNzA4MTMxfQ.XPQ77Il9gRpBKVf3TRukpXPqPGUYeGgd8GpnJh_gqNY';

const sql = `
-- Create all tables for Streaks app
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  age INTEGER,
  height DECIMAL,
  weight DECIMAL,
  activity_level TEXT,
  fitness_goal TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  steps INTEGER DEFAULT 0,
  heart_rate INTEGER,
  sleep_hours DECIMAL,
  calories_burned INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  workout_type TEXT,
  duration_minutes INTEGER,
  calories_burned INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ 
BEGIN
  CREATE POLICY IF NOT EXISTS "Users own profiles" ON profiles FOR ALL USING (auth.uid() = id);
  CREATE POLICY IF NOT EXISTS "Users own nutrition" ON nutrition_entries FOR ALL USING (auth.uid() = user_id);
  CREATE POLICY IF NOT EXISTS "Users own health" ON health_metrics FOR ALL USING (auth.uid() = user_id);
  CREATE POLICY IF NOT EXISTS "Users own streaks" ON streaks FOR ALL USING (auth.uid() = user_id);
  CREATE POLICY IF NOT EXISTS "Users own workouts" ON workouts FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;
`;

const data = JSON.stringify({ query: sql });

const options = {
  hostname: SUPABASE_URL,
  port: 443,
  path: '/rest/v1/rpc/exec_sql',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length,
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
    'Prefer': 'return=representation'
  }
};

const req = https.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  
  let responseData = '';
  res.on('data', (chunk) => {
    responseData += chunk;
  });
  
  res.on('end', () => {
    console.log('Response:', responseData);
    if (res.statusCode === 200 || res.statusCode === 201) {
      console.log('✅ Tables created successfully!');
    } else {
      console.log('❌ Error creating tables');
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(data);
req.end();