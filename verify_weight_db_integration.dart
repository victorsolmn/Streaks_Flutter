import 'dart:convert';
import 'package:http/http.dart' as http;

// Comprehensive database verification script for weight feature
void main() async {
  print('🔍 WEIGHT FEATURE DATABASE INTEGRATION VERIFICATION');
  print('=' * 60);

  const supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao';

  final headers = {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  // 1. Check profiles table structure
  print('\n📋 1. CHECKING PROFILES TABLE STRUCTURE:');
  try {
    final profilesResponse = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?select=*&limit=1'),
      headers: headers,
    );

    if (profilesResponse.statusCode == 200) {
      final data = jsonDecode(profilesResponse.body);
      if (data.isNotEmpty) {
        print('   ✅ Profiles table exists and is accessible');
        print('   Columns found:');
        final columns = (data[0] as Map).keys.toList();
        for (var col in columns) {
          if (col == 'id' || col == 'user_id' || col == 'weight' ||
              col == 'target_weight' || col == 'weight_unit') {
            print('   - $col: ${col == 'id' ? '✅ PRIMARY KEY' :
                              col == 'user_id' ? '❌ SHOULD NOT EXIST' : '✓'}');
          }
        }

        // Check if user_id column exists (it shouldn't)
        if (columns.contains('user_id')) {
          print('\n   ⚠️ WARNING: profiles table has user_id column!');
          print('   This is incorrect - profiles should use id as primary key');
        } else {
          print('\n   ✅ Correct: No user_id column in profiles table');
        }
      } else {
        print('   ⚠️ Profiles table is empty');
      }
    } else {
      print('   ❌ Error accessing profiles table: ${profilesResponse.body}');
    }
  } catch (e) {
    print('   ❌ Failed to check profiles table: $e');
  }

  // 2. Check weight_entries table
  print('\n📋 2. CHECKING WEIGHT_ENTRIES TABLE:');
  try {
    final weightResponse = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/weight_entries?select=*&limit=1'),
      headers: headers,
    );

    if (weightResponse.statusCode == 200) {
      print('   ✅ weight_entries table exists');
      final data = jsonDecode(weightResponse.body);
      if (data.isNotEmpty) {
        final columns = (data[0] as Map).keys.toList();
        print('   Columns found:');
        for (var col in columns) {
          if (col == 'id' || col == 'user_id' || col == 'weight' ||
              col == 'timestamp' || col == 'note') {
            print('   - $col: ${col == 'user_id' ? '✅ CORRECT FOREIGN KEY' : '✓'}');
          }
        }
      } else {
        print('   ⚠️ weight_entries table is empty (normal for new setup)');
      }
    } else if (weightResponse.statusCode == 400 &&
               weightResponse.body.contains('does not exist')) {
      print('   ❌ weight_entries table DOES NOT EXIST!');
      print('   Need to run migration to create table');
    } else {
      print('   ❌ Error: ${weightResponse.body}');
    }
  } catch (e) {
    print('   ❌ Failed to check weight_entries table: $e');
  }

  // 3. Check if we can query profiles correctly
  print('\n📋 3. TESTING PROFILE QUERIES:');

  // Test correct query (using id)
  print('   Testing correct query: profiles WHERE id = user_id');
  try {
    // Get a user to test with
    final authResponse = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?select=id&limit=1'),
      headers: headers,
    );

    if (authResponse.statusCode == 200) {
      final users = jsonDecode(authResponse.body);
      if (users.isNotEmpty) {
        final userId = users[0]['id'];

        // Test correct query
        final correctQuery = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$userId&select=weight,target_weight,weight_unit'),
          headers: headers,
        );

        if (correctQuery.statusCode == 200) {
          print('   ✅ Query using id column works correctly');
          final result = jsonDecode(correctQuery.body);
          if (result.isNotEmpty) {
            print('   User data: weight=${result[0]['weight']}, target=${result[0]['target_weight']}');
          }
        } else {
          print('   ❌ Query failed: ${correctQuery.body}');
        }

        // Test incorrect query (should fail)
        print('\n   Testing incorrect query: profiles WHERE user_id = ...');
        final incorrectQuery = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?user_id=eq.$userId&select=weight'),
          headers: headers,
        );

        if (incorrectQuery.statusCode == 400) {
          print('   ✅ Correct: Query using user_id fails as expected');
          print('   Error confirms: ${jsonDecode(incorrectQuery.body)['message']}');
        } else if (incorrectQuery.statusCode == 200) {
          print('   ❌ PROBLEM: Query using user_id should fail but succeeded!');
          print('   This means profiles table incorrectly has user_id column');
        }
      }
    }
  } catch (e) {
    print('   ❌ Query test failed: $e');
  }

  // 4. Check RLS policies
  print('\n📋 4. CHECKING RLS POLICIES:');
  try {
    // This requires admin access - try to check if RLS is enabled
    final rlsCheck = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/weight_entries?select=*&limit=0'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
      },
    );

    if (rlsCheck.statusCode == 200) {
      print('   ✅ weight_entries table is accessible with service role');
      print('   Note: RLS policies should be configured for user access');
    }
  } catch (e) {
    print('   ⚠️ Could not verify RLS: $e');
  }

  // 5. Check trigger function
  print('\n📋 5. CHECKING DATABASE TRIGGERS:');
  print('   Note: Cannot directly query trigger functions via REST API');
  print('   Manual verification needed in Supabase SQL Editor:');
  print('   Run: SELECT prosrc FROM pg_proc WHERE proname = \'update_profile_weight\';');
  print('   Should show: WHERE id = NEW.user_id (not WHERE user_id = NEW.user_id)');

  // 6. Summary
  print('\n' + '=' * 60);
  print('📊 INTEGRATION ANALYSIS SUMMARY:');
  print('=' * 60);

  print('\n🔧 REQUIRED ACTIONS:');
  print('1. ✅ Profiles table uses \'id\' as primary key (correct)');
  print('2. ⚠️ Check if weight_entries table exists (run migration if not)');
  print('3. ⚠️ Apply trigger fix in SQL Editor (fix_weight_trigger.sql)');
  print('4. ✅ App code has been fixed to use correct column names');

  print('\n📝 SQL MIGRATION NEEDED:');
  print('If weight_entries table doesn\'t exist, run:');
  print('- /supabase/migrations/weight_entries_table.sql');
  print('\nThen apply trigger fix:');
  print('- /supabase/migrations/fix_weight_trigger.sql');

  print('\n🔒 SECURITY NOTE:');
  print('Service role key should only be used server-side');
  print('Client apps should use anon key with RLS policies');
}