import 'dart:convert';
import 'package:http/http.dart' as http;

// Script to identify and remove test entries from Supabase
void main() async {
  print('🧹 CLEANING UP TEST WEIGHT ENTRIES');
  print('=' * 60);

  const supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao';

  final headers = {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  const testUserId = '5acc8e5f-03b2-48cf-bd29-f7a2f1fc06e9';

  print('\n📋 STEP 1: IDENTIFYING TEST ENTRIES');
  print('-' * 40);

  try {
    // Get all weight entries
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/weight_entries?user_id=eq.$testUserId&select=*&order=timestamp.desc'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final entries = jsonDecode(response.body);
      print('Found ${entries.length} total weight entries\n');

      List<String> testEntryIds = [];
      List<Map> realEntries = [];

      for (var entry in entries) {
        final weight = entry['weight'];
        final note = entry['note'] ?? '';
        final timestamp = entry['timestamp'];
        final id = entry['id'];

        // Identify test entries based on:
        // 1. Note contains "test" or "verification"
        // 2. Weights that are exactly 75.5 or 85.2 (our test values)
        // 3. Created in the last hour during testing

        bool isTestEntry = false;

        if (note.toLowerCase().contains('test') ||
            note.toLowerCase().contains('verification')) {
          isTestEntry = true;
        }

        // Check for specific test weights with recent timestamps
        final entryTime = DateTime.parse(timestamp);
        final hoursSinceCreated = DateTime.now().difference(entryTime).inHours;

        if ((weight == 75.5 || weight == 85.2) && hoursSinceCreated < 2) {
          isTestEntry = true;
        }

        if (isTestEntry) {
          print('❌ TEST ENTRY FOUND:');
          print('   ID: $id');
          print('   Weight: $weight kg');
          print('   Note: $note');
          print('   Time: $timestamp');
          testEntryIds.add(id);
        } else {
          print('✅ REAL ENTRY (keeping):');
          print('   Weight: $weight kg');
          print('   Time: $timestamp');
          realEntries.add(entry);
        }
        print('');
      }

      print('\n📋 STEP 2: REMOVING TEST ENTRIES');
      print('-' * 40);

      if (testEntryIds.isEmpty) {
        print('No test entries found to remove.');
      } else {
        print('Removing ${testEntryIds.length} test entries...\n');

        for (String entryId in testEntryIds) {
          try {
            final deleteResp = await http.delete(
              Uri.parse('$supabaseUrl/rest/v1/weight_entries?id=eq.$entryId'),
              headers: headers,
            );

            if (deleteResp.statusCode == 204) {
              print('✅ Deleted test entry: $entryId');
            } else {
              print('❌ Failed to delete: $entryId');
            }
          } catch (e) {
            print('❌ Error deleting $entryId: $e');
          }
        }
      }

      print('\n📋 STEP 3: UPDATING PROFILE WEIGHT');
      print('-' * 40);

      // After cleanup, ensure profile has correct weight (latest real entry)
      if (realEntries.isNotEmpty) {
        // Get the latest real entry
        realEntries.sort((a, b) =>
          DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

        final latestRealWeight = realEntries.first['weight'];
        print('Setting profile weight to latest real entry: $latestRealWeight kg');

        final updateResp = await http.patch(
          Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$testUserId'),
          headers: headers,
          body: jsonEncode({
            'weight': latestRealWeight,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );

        if (updateResp.statusCode == 200 || updateResp.statusCode == 204) {
          print('✅ Profile weight updated to $latestRealWeight kg');
        } else {
          print('❌ Failed to update profile weight');
        }
      } else {
        print('No real entries found. Setting default weight...');

        // Set to a reasonable default or target weight
        final profileResp = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$testUserId&select=target_weight'),
          headers: headers,
        );

        if (profileResp.statusCode == 200) {
          final profile = jsonDecode(profileResp.body)[0];
          final targetWeight = profile['target_weight'] ?? 70.0;

          await http.patch(
            Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$testUserId'),
            headers: headers,
            body: jsonEncode({
              'weight': targetWeight,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );

          print('✅ Profile weight set to target weight: $targetWeight kg');
        }
      }

      print('\n📋 FINAL STATUS');
      print('-' * 40);

      // Get final state
      final finalEntriesResp = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/weight_entries?user_id=eq.$testUserId&select=weight,timestamp&order=timestamp.desc'),
        headers: headers,
      );

      if (finalEntriesResp.statusCode == 200) {
        final finalEntries = jsonDecode(finalEntriesResp.body);
        print('Remaining weight entries: ${finalEntries.length}');

        for (var entry in finalEntries) {
          print('  - ${entry['weight']} kg at ${entry['timestamp']}');
        }
      }

      final finalProfileResp = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$testUserId&select=weight'),
        headers: headers,
      );

      if (finalProfileResp.statusCode == 200) {
        final profile = jsonDecode(finalProfileResp.body)[0];
        print('\nFinal profile weight: ${profile['weight']} kg');
      }

    } else {
      print('❌ Failed to get weight entries: ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('\n' + '=' * 60);
  print('✅ CLEANUP COMPLETE');
  print('Test entries have been removed, keeping only real user data.');
}