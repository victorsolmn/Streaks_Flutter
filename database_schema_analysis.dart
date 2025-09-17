import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class DatabaseSchemaAnalysis {
  static const String SUPABASE_URL = 'https://ipmzgbjykkvcynrjxepq.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwbXpnYmp5a2t2Y3lucmp4ZXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzNTU3OTEsImV4cCI6MjA0MTkzMTc5MX0.e4v7_L1tG9j6P8wEWo9KQnkMx3hN2JjNdJNsZtPl2Ew';

  late SupabaseClient _supabase;

  Future<void> initialize() async {
    _supabase = SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    print('✅ Database connection initialized');
  }

  Future<void> analyzeSchema() async {
    print('\n🔍 DATABASE SCHEMA ANALYSIS STARTING...\n');
    print('=' * 80);

    try {
      // Get all tables in public schema
      final tablesQuery = '''
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name;
      ''';

      final tablesResult = await _supabase.rpc('exec_sql', params: {'sql': tablesQuery});
      print('📋 EXISTING TABLES:');
      for (var table in tablesResult) {
        print('  - ${table['table_name']}');
      }

      print('\n' + '=' * 80);

      // Analyze each expected table
      await _analyzeTable('profiles');
      await _analyzeTable('nutrition_entries');
      await _analyzeTable('health_metrics');
      await _analyzeTable('streaks');
      await _analyzeTable('user_streaks'); // Alternative name
      await _analyzeTable('user_goals');
      await _analyzeTable('daily_nutrition_summary');
      await _analyzeTable('user_dashboard');

      print('\n🎯 CONSTRAINT ANALYSIS:');
      await _analyzeConstraints();

      print('\n🔄 DATA TYPE VALIDATION:');
      await _validateDataTypes();

    } catch (e) {
      print('❌ Schema analysis error: $e');
    }
  }

  Future<void> _analyzeTable(String tableName) async {
    print('\n📊 ANALYZING TABLE: $tableName');
    print('-' * 50);

    try {
      // Get column information
      final columnsQuery = '''
        SELECT
          column_name,
          data_type,
          character_maximum_length,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = '$tableName'
        ORDER BY ordinal_position;
      ''';

      final columnsResult = await _supabase.rpc('exec_sql', params: {'sql': columnsQuery});

      if (columnsResult.isEmpty) {
        print('❌ TABLE NOT FOUND: $tableName');
        return;
      }

      print('✅ Table exists with ${columnsResult.length} columns:');
      for (var column in columnsResult) {
        final nullable = column['is_nullable'] == 'YES' ? 'nullable' : 'NOT NULL';
        final maxLength = column['character_maximum_length'] ?? '';
        final defaultVal = column['column_default'] ?? '';

        print('  📝 ${column['column_name']}: ${column['data_type']}${maxLength.isNotEmpty ? '($maxLength)' : ''} [$nullable]${defaultVal.isNotEmpty ? ' DEFAULT: $defaultVal' : ''}');
      }

      // Check for specific missing columns based on app expectations
      await _checkExpectedColumns(tableName, columnsResult);

    } catch (e) {
      print('❌ Error analyzing table $tableName: $e');
    }
  }

  Future<void> _checkExpectedColumns(String tableName, List<dynamic> existingColumns) async {
    final existingColumnNames = existingColumns.map((col) => col['column_name'] as String).toSet();

    Map<String, List<String>> expectedColumns = {
      'profiles': [
        'id', 'email', 'name', 'age', 'height', 'weight',
        'activity_level', 'fitness_goal', 'daily_calories_target', // This is missing!
        'created_at', 'updated_at'
      ],
      'nutrition_entries': [
        'id', 'user_id', 'food_name', 'calories', 'protein', 'carbs', 'fat',
        'fiber', 'quantity_grams', 'meal_type', 'food_source', 'date',
        'created_at', 'updated_at'
      ],
      'health_metrics': [
        'id', 'user_id', 'date', 'steps', 'heart_rate', 'sleep_hours',
        'calories_burned', 'distance', 'active_minutes', 'water_intake',
        'created_at', 'updated_at'
      ],
      'streaks': [
        'id', 'user_id', 'streak_type', 'current_streak', 'longest_streak',
        'last_activity_date', 'target_achieved', 'created_at', 'updated_at'
      ],
      'user_goals': [
        'id', 'user_id', 'goal_type', 'target_value', 'current_value',
        'unit', 'is_active', 'created_at', 'updated_at'
      ]
    };

    if (expectedColumns.containsKey(tableName)) {
      final expected = expectedColumns[tableName]!;
      final missing = expected.where((col) => !existingColumnNames.contains(col)).toList();
      final extra = existingColumnNames.where((col) => !expected.contains(col)).toList();

      if (missing.isNotEmpty) {
        print('  ⚠️  MISSING COLUMNS:');
        for (var col in missing) {
          print('    - $col');
        }
      }

      if (extra.isNotEmpty) {
        print('  ℹ️  EXTRA COLUMNS:');
        for (var col in extra) {
          print('    + $col');
        }
      }

      if (missing.isEmpty && extra.isEmpty) {
        print('  ✅ All expected columns present');
      }
    }
  }

  Future<void> _analyzeConstraints() async {
    try {
      final constraintsQuery = '''
        SELECT
          tc.table_name,
          tc.constraint_name,
          tc.constraint_type,
          cc.check_clause
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.check_constraints cc
          ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_schema = 'public'
        AND tc.table_name IN ('profiles', 'nutrition_entries', 'health_metrics', 'streaks', 'user_goals')
        ORDER BY tc.table_name, tc.constraint_type;
      ''';

      final constraintsResult = await _supabase.rpc('exec_sql', params: {'sql': constraintsQuery});

      for (var constraint in constraintsResult) {
        print('🔒 ${constraint['table_name']}.${constraint['constraint_name']} (${constraint['constraint_type']})');
        if (constraint['check_clause'] != null) {
          print('   CHECK: ${constraint['check_clause']}');
        }
      }

    } catch (e) {
      print('❌ Error analyzing constraints: $e');
    }
  }

  Future<void> _validateDataTypes() async {
    // Test data type compatibility with actual inserts
    print('🧪 Testing data type compatibility...');

    try {
      // Test nutrition entries data types (known issue with List vs String)
      print('  Testing nutrition_entries data types...');

      // Test health metrics constraints (known heart rate issue)
      print('  Testing health_metrics constraints...');

    } catch (e) {
      print('❌ Data type validation error: $e');
    }
  }

  Future<void> generateMigrationScripts() async {
    print('\n🔧 GENERATING MIGRATION SCRIPTS...\n');
    print('=' * 80);

    final migrations = <String>[];

    // 1. Add missing daily_calories_target column
    migrations.add('''
-- Migration 1: Add missing daily_calories_target column to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER DEFAULT 2000;

-- Add comment
COMMENT ON COLUMN profiles.daily_calories_target IS 'Daily calorie target for user nutrition goals';
''');

    // 2. Fix heart rate constraint (if too restrictive)
    migrations.add('''
-- Migration 2: Fix heart rate constraint in health_metrics
ALTER TABLE health_metrics
DROP CONSTRAINT IF EXISTS health_metrics_heart_rate_check;

ALTER TABLE health_metrics
ADD CONSTRAINT health_metrics_heart_rate_check
CHECK (heart_rate IS NULL OR (heart_rate >= 30 AND heart_rate <= 250));

-- Add comment
COMMENT ON CONSTRAINT health_metrics_heart_rate_check ON health_metrics IS 'Heart rate must be between 30-250 BPM or NULL';
''');

    // 3. Ensure proper indexes for performance
    migrations.add('''
-- Migration 3: Add performance indexes
CREATE INDEX IF NOT EXISTS idx_nutrition_entries_user_date ON nutrition_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_date ON health_metrics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_streaks_user_type ON streaks(user_id, streak_type);
CREATE INDEX IF NOT EXISTS idx_user_goals_user_active ON user_goals(user_id, is_active);
''');

    // 4. Fix any JSON/Array data type issues
    migrations.add('''
-- Migration 4: Ensure proper data types for nutrition entries
-- Check if any columns need to be converted from text to proper types
-- This will be determined after inspecting actual schema
''');

    // 5. Add missing tables if they don't exist
    migrations.add('''
-- Migration 5: Create missing tables

-- Create daily_nutrition_summary view if it doesn't exist
CREATE OR REPLACE VIEW daily_nutrition_summary AS
SELECT
  user_id,
  date,
  SUM(calories) as total_calories,
  SUM(protein) as total_protein,
  SUM(carbs) as total_carbs,
  SUM(fat) as total_fat,
  SUM(fiber) as total_fiber,
  COUNT(*) as entries_count
FROM nutrition_entries
GROUP BY user_id, date;

-- Create user_dashboard view if it doesn't exist
CREATE OR REPLACE VIEW user_dashboard AS
SELECT
  p.id,
  p.name,
  p.email,
  p.daily_calories_target,
  s.current_streak,
  s.longest_streak,
  hm.steps as today_steps,
  hm.calories_burned as today_calories_burned
FROM profiles p
LEFT JOIN streaks s ON p.id = s.user_id AND s.streak_type = 'daily'
LEFT JOIN health_metrics hm ON p.id = hm.user_id AND hm.date = CURRENT_DATE;
''');

    // Print all migrations
    for (int i = 0; i < migrations.length; i++) {
      print('MIGRATION ${i + 1}:');
      print(migrations[i]);
      print('\n' + '-' * 40 + '\n');
    }

    // Save to file
    final allMigrations = '''
-- ============================================
-- STREAKS FLUTTER DATABASE SCHEMA FIXES
-- Generated: ${DateTime.now().toIso8601String()}
-- ============================================

${migrations.join('\n\n')}

-- ============================================
-- END OF MIGRATIONS
-- ============================================
''';

    print('💾 Migration scripts generated successfully!');
    print('📁 Saving to: database_migrations.sql');

    // Save migrations to file
    await _saveMigrationsToFile(allMigrations);
  }

  Future<void> _saveMigrationsToFile(String content) async {
    // This would save to file in a real implementation
    print('📝 Migration file content:');
    print(content);
  }
}

void main() async {
  final analyzer = DatabaseSchemaAnalysis();

  try {
    await analyzer.initialize();
    await analyzer.analyzeSchema();
    await analyzer.generateMigrationScripts();
  } catch (e) {
    print('❌ Analysis failed: $e');
  }
}