import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Supabase configuration - using the same config from the app
const String supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.BOzOh1-7RL-JH3MNqZOh_xKWWKjl9TxgJRRyUzqEL8Y'; // This needs to be the service role key, not anon key

Future<void> runDatabaseMigration() async {
  print('🔧 Starting database migration...');

  // SQL commands to add missing columns
  final migrationSQL = '''
    -- Add missing columns to profiles table
    ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS target_weight DECIMAL,
    ADD COLUMN IF NOT EXISTS experience_level TEXT,
    ADD COLUMN IF NOT EXISTS workout_consistency TEXT,
    ADD COLUMN IF NOT EXISTS daily_calories_target INTEGER,
    ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER,
    ADD COLUMN IF NOT EXISTS daily_sleep_target DECIMAL,
    ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL;

    -- Ensure has_completed_onboarding column exists and has correct type
    ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN DEFAULT FALSE;

    -- Update existing users to have proper default values
    UPDATE profiles
    SET has_completed_onboarding = FALSE
    WHERE has_completed_onboarding IS NULL;
  ''';

  try {
    // Use Supabase SQL endpoint
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': supabaseServiceKey,
        'Authorization': 'Bearer $supabaseServiceKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: json.encode({
        'sql': migrationSQL,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('✅ Database migration completed successfully!');
      print('📊 All missing columns have been added to the profiles table');
      print('🎯 The app will now save all onboarding data correctly');
    } else {
      print('❌ Migration failed with status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      // Try alternative approach using direct SQL execution
      await runSQLDirectly(migrationSQL);
    }
  } catch (e) {
    print('❌ Error running migration: $e');
    print('💡 You may need to run the SQL commands manually in Supabase dashboard');

    print('\n📋 SQL to run manually:');
    print('=' * 60);
    print(migrationSQL);
    print('=' * 60);
  }
}

Future<void> runSQLDirectly(String sql) async {
  print('🔄 Trying alternative SQL execution method...');

  // Split SQL into individual commands
  final commands = sql.split(';').where((cmd) => cmd.trim().isNotEmpty).toList();

  for (int i = 0; i < commands.length; i++) {
    final command = commands[i].trim();
    if (command.isEmpty) continue;

    print('🔧 Executing command ${i + 1}/${commands.length}...');

    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/rpc/exec'),
        headers: {
          'apikey': supabaseServiceKey,
          'Authorization': 'Bearer $supabaseServiceKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sql': command,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Command ${i + 1} executed successfully');
      } else {
        print('⚠️ Command ${i + 1} failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error executing command ${i + 1}: $e');
    }
  }
}

void main() async {
  await runDatabaseMigration();
}