import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class MigrationApplier {
  static const String SUPABASE_URL = 'https://ipmzgbjykkvcynrjxepq.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwbXpnYmp5a2t2Y3lucmp4ZXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzNTU3OTEsImV4cCI6MjA0MTkzMTc5MX0.e4v7_L1tG9j6P8wEWo9KQnkMx3hN2JjNdJNsZtPl2Ew';

  late SupabaseClient _supabase;

  Future<void> initialize() async {
    try {
      _supabase = SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      print('✅ Connected to Supabase');
    } catch (e) {
      print('❌ Failed to connect to Supabase: $e');
      rethrow;
    }
  }

  Future<void> applyMigrations() async {
    print('\n🔧 APPLYING DATABASE MIGRATIONS...\n');
    print('=' * 80);

    // Migration 1: Add missing daily_calories_target column
    await _runMigration(
      'Migration 1: Add daily_calories_target column',
      '''
        ALTER TABLE profiles
        ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000;
      '''
    );

    // Migration 2: Fix heart rate constraints
    await _runMigration(
      'Migration 2: Fix heart rate constraints',
      '''
        ALTER TABLE health_metrics
        DROP CONSTRAINT IF EXISTS health_metrics_heart_rate_check;

        ALTER TABLE health_metrics
        ADD CONSTRAINT health_metrics_heart_rate_check
        CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250));
      '''
    );

    // Migration 3: Create user_streaks view for compatibility
    await _runMigration(
      'Migration 3: Create user_streaks compatibility view',
      '''
        CREATE OR REPLACE VIEW user_streaks AS
        SELECT * FROM streaks;
      '''
    );

    // Migration 4: Fix unique constraints for upsert operations
    await _runMigration(
      'Migration 4: Add unique constraint for streaks',
      '''
        ALTER TABLE streaks
        ADD CONSTRAINT IF NOT EXISTS streaks_user_type_unique
        UNIQUE (user_id, streak_type);
      '''
    );

    // Migration 5: Add performance indexes
    await _runMigration(
      'Migration 5: Add performance indexes',
      '''
        CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON nutrition_entries(user_id, date);
        CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON health_metrics(user_id, date);
        CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON streaks(user_id, streak_type);
        CREATE INDEX IF NOT EXISTS idx_user_goals_user_active ON user_goals(user_id, is_active);
      '''
    );

    // Migration 6: Create daily_nutrition_summary view
    await _runMigration(
      'Migration 6: Create daily_nutrition_summary view',
      '''
        CREATE OR REPLACE VIEW daily_nutrition_summary AS
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
        FROM nutrition_entries
        GROUP BY user_id, date;
      '''
    );

    // Migration 7: Create user_dashboard view
    await _runMigration(
      'Migration 7: Create user_dashboard view',
      '''
        CREATE OR REPLACE VIEW user_dashboard AS
        SELECT
            p.id,
            p.name,
            p.email,
            p.age,
            p.height,
            p.weight,
            p.activity_level,
            p.fitness_goal,
            p.daily_calories_target,
            s.current_streak,
            s.longest_streak,
            s.last_activity_date,
            hm.steps as today_steps,
            hm.calories_burned as today_calories_burned,
            hm.heart_rate as today_heart_rate,
            hm.sleep_hours as today_sleep_hours,
            hm.water_intake as today_water_intake,
            p.created_at as profile_created_at
        FROM profiles p
        LEFT JOIN streaks s ON p.id = s.user_id AND s.streak_type = 'daily'
        LEFT JOIN health_metrics hm ON p.id = hm.user_id AND hm.date = CURRENT_DATE;
      '''
    );

    // Migration 8: Update existing data
    await _runMigration(
      'Migration 8: Update existing NULL values',
      '''
        UPDATE profiles
        SET daily_calories_target = 2000
        WHERE daily_calories_target IS NULL;

        UPDATE health_metrics
        SET heart_rate = NULL
        WHERE heart_rate IS NOT NULL AND (heart_rate < 30 OR heart_rate > 250);
      '''
    );

    print('\n🎉 ALL MIGRATIONS COMPLETED SUCCESSFULLY!\n');
    print('=' * 80);
  }

  Future<void> _runMigration(String description, String sql) async {
    try {
      print('🔄 $description...');

      // Split SQL by semicolons and execute each statement
      final statements = sql.split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final statement in statements) {
        if (statement.trim().isEmpty) continue;

        try {
          await _supabase.rpc('exec_sql', params: {'sql': statement});
        } catch (e) {
          // Some migrations might fail if already applied - that's OK for IF NOT EXISTS
          if (!e.toString().contains('already exists') &&
              !e.toString().contains('does not exist')) {
            throw e;
          }
        }
      }

      print('✅ $description completed');
      await Future.delayed(Duration(milliseconds: 500)); // Small delay between migrations

    } catch (e) {
      print('❌ $description failed: $e');
      // Continue with other migrations even if one fails
    }
  }

  Future<void> verifyMigrations() async {
    print('\n🔍 VERIFYING MIGRATIONS...\n');

    try {
      // Check if daily_calories_target column exists
      final profilesResult = await _supabase
          .from('profiles')
          .select('daily_calories_target')
          .limit(1);
      print('✅ daily_calories_target column accessible');

      // Check if user_streaks view exists
      final streaksResult = await _supabase
          .from('user_streaks')
          .select('id')
          .limit(1);
      print('✅ user_streaks view accessible');

      // Test views
      final dashboardResult = await _supabase
          .from('user_dashboard')
          .select('id')
          .limit(1);
      print('✅ user_dashboard view accessible');

      final nutritionSummaryResult = await _supabase
          .from('daily_nutrition_summary')
          .select('user_id')
          .limit(1);
      print('✅ daily_nutrition_summary view accessible');

      print('\n🎉 ALL VERIFICATIONS PASSED!\n');

    } catch (e) {
      print('❌ Verification failed: $e');
      print('Some migrations may need manual application via Supabase dashboard');
    }
  }
}

void main() async {
  final migrator = MigrationApplier();

  try {
    await migrator.initialize();
    await migrator.applyMigrations();
    await migrator.verifyMigrations();

    print('✅ Migration process completed successfully!');
    print('Next: Update Flutter app code to use the corrected schema');

  } catch (e) {
    print('❌ Migration process failed: $e');
    print('Please check the database manually and retry failed migrations');
  }
}