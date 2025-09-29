# Supabase Integration Setup Guide

## Overview
This guide will help you set up Supabase as the backend for your Streaks Flutter app, providing real authentication, cloud database, and real-time sync capabilities.

## Prerequisites
- Flutter development environment set up
- A Supabase account (free tier available)
- Basic understanding of SQL (for database setup)

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in the project details:
   - Name: `Streaks Flutter` (or your preferred name)
   - Database Password: Choose a strong password (save this!)
   - Region: Select the closest to your users
   - Pricing Plan: Free tier is sufficient for development

4. Wait for the project to be created (takes about 2 minutes)

## Step 2: Get Your API Credentials

1. Once your project is ready, go to **Settings → API**
2. You'll find two important values:
   - **Project URL**: Something like `https://xxxxxxxxxxxxx.supabase.co`
   - **Anon/Public Key**: A long string starting with `eyJ...`

3. Copy these values

## Step 3: Configure Your Flutter App

1. Open `/lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  // Replace with your actual values
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
}
```

## Step 4: Set Up Database Tables

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy and paste the following SQL script:

```sql
-- Create profiles table for user data
CREATE TABLE profiles (
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

-- Create nutrition tracking table
CREATE TABLE nutrition_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  calories INTEGER DEFAULT 0,
  protein DECIMAL DEFAULT 0,
  carbs DECIMAL DEFAULT 0,
  fat DECIMAL DEFAULT 0,
  water INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, date)
);

-- Create health metrics table
CREATE TABLE health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  steps INTEGER DEFAULT 0,
  heart_rate INTEGER,
  sleep_hours DECIMAL,
  calories_burned INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, date)
);

-- Create streaks table
CREATE TABLE streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id)
);

-- Create food items table for future food database
CREATE TABLE food_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  brand TEXT,
  barcode TEXT,
  calories_per_100g INTEGER,
  protein_per_100g DECIMAL,
  carbs_per_100g DECIMAL,
  fat_per_100g DECIMAL,
  serving_size DECIMAL,
  serving_unit TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create user food entries for detailed tracking
CREATE TABLE user_food_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nutrition_entry_id UUID REFERENCES nutrition_entries(id) ON DELETE CASCADE,
  food_item_id UUID REFERENCES food_items(id),
  food_name TEXT NOT NULL,
  quantity DECIMAL NOT NULL,
  unit TEXT,
  calories INTEGER,
  protein DECIMAL,
  carbs DECIMAL,
  fat DECIMAL,
  meal_type TEXT, -- breakfast, lunch, dinner, snack
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```

4. Click **Run** to execute the script

## Step 5: Set Up Row Level Security (RLS)

Continue in the SQL Editor with this script:

```sql
-- Enable Row Level Security on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_food_entries ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Nutrition entries policies
CREATE POLICY "Users can manage own nutrition" 
  ON nutrition_entries FOR ALL 
  USING (auth.uid() = user_id);

-- Health metrics policies
CREATE POLICY "Users can manage own health metrics" 
  ON health_metrics FOR ALL 
  USING (auth.uid() = user_id);

-- Streaks policies
CREATE POLICY "Users can manage own streaks" 
  ON streaks FOR ALL 
  USING (auth.uid() = user_id);

-- User food entries policies
CREATE POLICY "Users can manage own food entries" 
  ON user_food_entries FOR ALL 
  USING (auth.uid() = user_id);

-- Food items are public read (for food database)
CREATE POLICY "Anyone can read food items" 
  ON food_items FOR SELECT 
  USING (true);
```

## Step 6: Create Database Triggers

Add this script to automatically create user profiles and streaks:

```sql
-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, email, name)
  VALUES (
    NEW.id, 
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  
  -- Initialize streak record
  INSERT INTO public.streaks (user_id, current_streak, longest_streak)
  VALUES (NEW.id, 0, 0);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add update triggers for tables with updated_at
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nutrition_entries_updated_at 
  BEFORE UPDATE ON nutrition_entries 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_streaks_updated_at 
  BEFORE UPDATE ON streaks 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();
```

## Step 7: Configure Authentication

1. In Supabase dashboard, go to **Authentication → Providers**
2. Ensure **Email** is enabled (it should be by default)
3. Optional: Configure email templates in **Authentication → Email Templates**
4. Optional: Set up OAuth providers (Google, Apple, etc.) if desired

## Step 8: Update Your Flutter App Code

### Switch to Supabase Providers

In your app, you need to switch from the mock providers to Supabase providers. 

**Option 1: Gradual Migration (Recommended)**
Keep both providers and switch based on a flag:

```dart
// In main.dart
final bool useSupabase = true; // Toggle this

// In your providers
useSupabase 
  ? ChangeNotifierProvider(create: (_) => SupabaseAuthProvider())
  : ChangeNotifierProvider(create: (_) => AuthProvider(prefs))
```

**Option 2: Full Migration**
Replace all provider imports:

```dart
// Replace these imports
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/nutrition_provider.dart';

// With these
import 'providers/supabase_auth_provider.dart';
import 'providers/supabase_user_provider.dart';
import 'providers/supabase_nutrition_provider.dart';
```

## Step 9: Test Your Integration

1. Run your Flutter app:
```bash
flutter run
```

2. Test the following:
   - Sign up with a new account
   - Sign in with existing account
   - Update profile information
   - Add nutrition data
   - Check if data persists after app restart
   - Sign out and sign back in

## Step 10: Monitor Your Database

1. Go to **Table Editor** in Supabase dashboard
2. You should see data appearing in your tables as you use the app
3. Check **Authentication → Users** to see registered users

## Troubleshooting

### Common Issues and Solutions

1. **"Invalid API key" error**
   - Double-check your `supabaseUrl` and `supabaseAnonKey` in the config file
   - Make sure there are no extra spaces or quotes

2. **Authentication not working**
   - Check if email provider is enabled in Supabase
   - Verify RLS policies are correctly set up
   - Check the Supabase logs in the dashboard

3. **Data not saving**
   - Verify RLS policies allow the operation
   - Check if user is properly authenticated
   - Look at browser console for detailed errors

4. **App crashes on startup**
   - Make sure you've run `flutter pub get` after adding dependencies
   - Check if Supabase is initialized before use
   - Verify internet connectivity

## Security Best Practices

1. **Never commit real API keys to version control**
   - Add `supabase_config.dart` to `.gitignore` if it contains real keys
   - Use environment variables for production

2. **Use Row Level Security (RLS)**
   - Always enable RLS on tables with user data
   - Test policies thoroughly

3. **Validate data on the backend**
   - Use database constraints
   - Create backend functions for complex operations

4. **Regular backups**
   - Supabase provides daily backups on paid plans
   - Export your schema regularly

## Next Steps

1. **Add more features:**
   - Social authentication (Google, Apple)
   - Password reset functionality
   - Email verification
   - Push notifications

2. **Optimize performance:**
   - Implement offline support with local caching
   - Use Supabase Realtime for live updates
   - Add pagination for large data sets

3. **Production preparation:**
   - Set up environment-specific configurations
   - Implement error tracking (Sentry, etc.)
   - Add analytics
   - Configure CI/CD pipeline

## Useful Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
- [Flutter & Supabase Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [SQL Editor Guide](https://supabase.com/docs/guides/database)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)

## Support

If you encounter issues:
1. Check the [Supabase Status Page](https://status.supabase.com/)
2. Search [Supabase GitHub Issues](https://github.com/supabase/supabase/issues)
3. Ask in [Supabase Discord](https://discord.supabase.com/)
4. Review logs in your Supabase dashboard under **Logs**

---

**Note:** Remember to keep your Supabase project active. Free tier projects may be paused after 1 week of inactivity.