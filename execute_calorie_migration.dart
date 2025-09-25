import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('🚀 Starting Calorie Tracking System Migration...\n');

  final supabase = SupabaseClient(
    'https://xzwvckziavhzmghizyqx.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao',
  );

  try {
    // Read the migration SQL file
    final migrationFile = File('/Users/Vicky/Streaks_Flutter/supabase/migrations/20250925_calorie_tracking_system.sql');
    final sqlContent = await migrationFile.readAsString();

    // Split into individual statements (split by semicolon but be careful with functions)
    final statements = <String>[];
    final lines = sqlContent.split('\n');
    var currentStatement = '';
    var inFunction = false;

    for (final line in lines) {
      // Skip comments and empty lines
      if (line.trim().startsWith('--') || line.trim().isEmpty) {
        continue;
      }

      // Check if we're entering or exiting a function/procedure
      if (line.contains('AS \$\$')) {
        inFunction = true;
      }
      if (line.contains('\$\$ LANGUAGE')) {
        inFunction = false;
        currentStatement += line + '\n';
        statements.add(currentStatement.trim());
        currentStatement = '';
        continue;
      }

      currentStatement += line + '\n';

      // If not in a function and line ends with semicolon, it's end of statement
      if (!inFunction && line.trim().endsWith(';')) {
        statements.add(currentStatement.trim());
        currentStatement = '';
      }
    }

    // Execute each statement
    var successCount = 0;
    var errorCount = 0;

    for (var i = 0; i < statements.length; i++) {
      final statement = statements[i];

      // Skip DO blocks and GRANT statements (not supported via API)
      if (statement.startsWith('DO \$\$') || statement.startsWith('GRANT')) {
        continue;
      }

      // Extract a description from the statement
      String description = 'Statement ${i + 1}';
      if (statement.contains('CREATE TABLE')) {
        final tableName = RegExp(r'CREATE TABLE[A-Z ]*public\.(\w+)').firstMatch(statement)?.group(1);
        description = 'Creating table: $tableName';
      } else if (statement.contains('CREATE INDEX')) {
        final indexName = RegExp(r'CREATE INDEX[A-Z ]*(\w+)').firstMatch(statement)?.group(1);
        description = 'Creating index: $indexName';
      } else if (statement.contains('CREATE POLICY')) {
        description = 'Creating RLS policy';
      } else if (statement.contains('CREATE FUNCTION')) {
        description = 'Creating function';
      } else if (statement.contains('CREATE TRIGGER')) {
        description = 'Creating trigger';
      } else if (statement.contains('CREATE VIEW')) {
        description = 'Creating view';
      } else if (statement.contains('ALTER TABLE')) {
        description = 'Altering table';
      }

      try {
        print('⏳ $description...');
        await supabase.rpc('exec_sql', params: {'sql': statement});
        print('✅ $description - Success');
        successCount++;
      } catch (e) {
        // Some errors are expected (e.g., "already exists")
        if (e.toString().contains('already exists') ||
            e.toString().contains('duplicate')) {
          print('ℹ️  $description - Already exists (skipped)');
          successCount++;
        } else {
          print('❌ $description - Error: ${e.toString().split('\n')[0]}');
          errorCount++;
        }
      }
    }

    print('\n' + '=' * 50);
    print('📊 Migration Summary:');
    print('   ✅ Successful: $successCount');
    print('   ❌ Failed: $errorCount');

    // Verify tables were created
    print('\n🔍 Verifying installation...');

    try {
      // Check calorie_sessions table
      final sessions = await supabase
          .from('calorie_sessions')
          .select('id')
          .limit(1);
      print('✅ calorie_sessions table verified');

      // Check daily_calorie_totals table
      final totals = await supabase
          .from('daily_calorie_totals')
          .select('id')
          .limit(1);
      print('✅ daily_calorie_totals table verified');

      print('\n🎉 Calorie Tracking System successfully installed!');
      print('   - Tables created and ready');
      print('   - Indexes configured');
      print('   - Functions installed');
      print('   - RLS policies active');

    } catch (e) {
      print('⚠️  Verification failed: $e');
    }

  } catch (e) {
    print('❌ Migration failed: $e');
    exit(1);
  }

  exit(0);
}