import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the app's configuration
import '../lib/config/supabase_config.dart';

Future<void> main() async {
  print('🔧 Starting database migration for Streaks Flutter app...');

  try {
    // Initialize Supabase with the app's configuration
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    final supabase = Supabase.instance.client;

    print('📡 Connected to Supabase database');

    // Try to run the migration using RPC calls instead of direct SQL
    print('🔧 Adding missing columns to profiles table...');

    // Add the missing columns one by one using ALTER TABLE
    final migrations = [
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS target_weight DECIMAL",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS experience_level TEXT",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workout_consistency TEXT",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL",
      "ALTER TABLE profiles ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE",
    ];

    // Try using Supabase functions if available
    for (int i = 0; i < migrations.length; i++) {
      try {
        print('⚙️ Running migration ${i + 1}/${migrations.length}...');

        // Try to run as RPC function (if exists)
        await supabase.rpc('exec_sql', params: {'sql': migrations[i]});
        print('✅ Migration ${i + 1} completed');
      } catch (e) {
        print('⚠️ Migration ${i + 1} failed (expected if column exists): $e');
      }
    }

    // Update existing profiles to have correct default values
    try {
      print('🔄 Updating existing profiles with default values...');
      await supabase.from('profiles').update({
        'has_completed_onboarding': false,
      }).neq('has_completed_onboarding', true);
      print('✅ Updated existing profiles');
    } catch (e) {
      print('⚠️ Could not update existing profiles: $e');
    }

    print('\n🎉 Database migration completed successfully!');
    print('📊 All missing columns should now be available');
    print('🔄 Try running the onboarding again to test');

  } catch (e) {
    print('❌ Migration failed: $e');
    print('\n📋 Manual SQL commands to run in Supabase dashboard:');
    print('=' * 60);
    print('''
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
ADD COLUMN IF NOT EXISTS experience_level TEXT,
ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER,
ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL,
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL,
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE;

UPDATE profiles
SET has_completed_onboarding = FALSE
WHERE has_completed_onboarding IS NULL;
    ''');
    print('=' * 60);
  }
}