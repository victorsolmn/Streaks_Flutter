/// Supabase Configuration
/// 
/// IMPORTANT: Replace these values with your actual Supabase project credentials
/// Get these from: https://app.supabase.com/project/YOUR_PROJECT/settings/api
/// 
/// For production apps, consider:
/// 1. Using environment variables
/// 2. Using Flutter's --dart-define for build-time configuration
/// 3. Never commit real credentials to version control

class SupabaseConfig {
  // Your Supabase project URL
  static const String supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';

  // Your Supabase anon key (safe for client-side)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwOTk0NjIsImV4cCI6MjA3MzY3NTQ2Mn0.fUtnAzqNGzKvo-FTWqpemcf0wvdlC6gpUg_ZllXBulo';
  
  // Optional: Add additional configuration
  static const bool enableLogging = true;
  static const Duration authSessionRefreshInterval = Duration(minutes: 55);
}

/// Instructions for setting up Supabase:
/// 
/// 1. Create a Supabase account at https://supabase.com
/// 2. Create a new project
/// 3. Go to Settings > API in your Supabase dashboard
/// 4. Copy your project URL and anon key
/// 5. Replace the placeholder values above
/// 
/// Database Schema Setup:
/// Run these SQL commands in your Supabase SQL editor:
/// 
/// ```sql
/// -- Create users profile table
/// CREATE TABLE profiles (
///   id UUID REFERENCES auth.users(id) PRIMARY KEY,
///   email TEXT UNIQUE NOT NULL,
///   name TEXT,
///   age INTEGER,
///   height DECIMAL,
///   weight DECIMAL,
///   activity_level TEXT,
///   fitness_goal TEXT,
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
/// );
/// 
/// -- Create nutrition tracking table
/// CREATE TABLE nutrition_entries (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
///   date DATE NOT NULL,
///   calories INTEGER DEFAULT 0,
///   protein DECIMAL DEFAULT 0,
///   carbs DECIMAL DEFAULT 0,
///   fat DECIMAL DEFAULT 0,
///   water INTEGER DEFAULT 0,
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   UNIQUE(user_id, date)
/// );
/// 
/// -- Create health metrics table
/// CREATE TABLE health_metrics (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
///   date DATE NOT NULL,
///   steps INTEGER DEFAULT 0,
///   heart_rate INTEGER,
///   sleep_hours DECIMAL,
///   calories_burned INTEGER,
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   UNIQUE(user_id, date)
/// );
/// 
/// -- Create streaks table
/// CREATE TABLE streaks (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
///   current_streak INTEGER DEFAULT 0,
///   longest_streak INTEGER DEFAULT 0,
///   last_activity_date DATE,
///   created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
///   UNIQUE(user_id)
/// );
/// 
/// -- Enable Row Level Security
/// ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
/// ALTER TABLE nutrition_entries ENABLE ROW LEVEL SECURITY;
/// ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
/// ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
/// 
/// -- Create policies for profiles
/// CREATE POLICY "Users can view own profile" ON profiles
///   FOR SELECT USING (auth.uid() = id);
/// 
/// CREATE POLICY "Users can update own profile" ON profiles
///   FOR UPDATE USING (auth.uid() = id);
/// 
/// CREATE POLICY "Users can insert own profile" ON profiles
///   FOR INSERT WITH CHECK (auth.uid() = id);
/// 
/// -- Create policies for nutrition_entries
/// CREATE POLICY "Users can view own nutrition" ON nutrition_entries
///   FOR SELECT USING (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can insert own nutrition" ON nutrition_entries
///   FOR INSERT WITH CHECK (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can update own nutrition" ON nutrition_entries
///   FOR UPDATE USING (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can delete own nutrition" ON nutrition_entries
///   FOR DELETE USING (auth.uid() = user_id);
/// 
/// -- Create policies for health_metrics
/// CREATE POLICY "Users can view own health metrics" ON health_metrics
///   FOR SELECT USING (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can insert own health metrics" ON health_metrics
///   FOR INSERT WITH CHECK (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can update own health metrics" ON health_metrics
///   FOR UPDATE USING (auth.uid() = user_id);
/// 
/// -- Create policies for streaks
/// CREATE POLICY "Users can view own streaks" ON streaks
///   FOR SELECT USING (auth.uid() = user_id);
/// 
/// CREATE POLICY "Users can manage own streaks" ON streaks
///   FOR ALL USING (auth.uid() = user_id);
/// 
/// -- Create function to handle new user registration
/// CREATE OR REPLACE FUNCTION handle_new_user()
/// RETURNS TRIGGER AS $$
/// BEGIN
///   INSERT INTO profiles (id, email)
///   VALUES (NEW.id, NEW.email);
///   
///   INSERT INTO streaks (user_id)
///   VALUES (NEW.id);
///   
///   RETURN NEW;
/// END;
/// $$ LANGUAGE plpgsql SECURITY DEFINER;
/// 
/// -- Create trigger for new user registration
/// CREATE TRIGGER on_auth_user_created
///   AFTER INSERT ON auth.users
///   FOR EACH ROW
///   EXECUTE FUNCTION handle_new_user();
/// ```