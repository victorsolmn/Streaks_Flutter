import 'dart:convert';
import 'dart:io';

void main() async {
  const supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
  const apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao';

  print('🔧 Starting database update...\n');

  try {
    // 1. First, fetch all profiles
    print('📊 Fetching profiles...');
    var client = HttpClient();
    var request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/profiles?select=*'));
    request.headers.set('apikey', apiKey);
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=representation');

    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    var profiles = jsonDecode(responseBody) as List;

    print('Found ${profiles.length} profiles\n');

    // 2. Update each profile
    for (var profile in profiles) {
      final id = profile['id'];
      final name = profile['name'] ?? 'Unknown';
      final email = profile['email'] ?? '';
      final age = profile['age'] as int?;
      final height = (profile['height'] as num?)?.toDouble();
      final weight = (profile['weight'] as num?)?.toDouble();
      final activityLevel = profile['activity_level'] as String?;
      final fitnessGoal = profile['fitness_goal'] as String?;
      final gender = profile['gender'] as String?;

      // Check if it's Victor's profile
      bool isVictor = email.contains('victorsolmn') ||
                      name.toLowerCase().contains('victor');

      Map<String, dynamic> updateData;

      if (isVictor) {
        // Set Victor's specific targets
        updateData = {
          'daily_active_calories_target': 2761,
          'daily_calories_target': 4369,
          'daily_steps_target': 10000,
          'daily_sleep_target': 8.0,
          'daily_water_target': 3.0,
        };
        print('🎯 Setting Victor\'s specific targets...');
      } else if (age != null && height != null && weight != null) {
        // Calculate targets for other profiles
        double bmr;
        if (gender == 'Female') {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
        } else {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
        }

        double multiplier = 1.55;
        switch (activityLevel) {
          case 'Sedentary':
            multiplier = 1.2;
            break;
          case 'Lightly Active':
            multiplier = 1.375;
            break;
          case 'Moderately Active':
            multiplier = 1.55;
            break;
          case 'Very Active':
            multiplier = 1.725;
            break;
          case 'Extra Active':
            multiplier = 1.9;
            break;
        }

        final tdee = bmr * multiplier;
        var activeCalories = (tdee - bmr).round();

        switch (fitnessGoal) {
          case 'Lose Weight':
            activeCalories -= 200;
            break;
          case 'Gain Muscle':
            activeCalories += 150;
            break;
        }

        activeCalories = activeCalories.clamp(500, 4000);
        final totalCalories = (bmr + activeCalories).round().clamp(1200, 5000);

        updateData = {
          'daily_active_calories_target': activeCalories,
          'daily_calories_target': totalCalories,
          'daily_steps_target': activityLevel == 'Very Active' ? 12500 :
                                activityLevel == 'Moderately Active' ? 10000 :
                                activityLevel == 'Lightly Active' ? 7500 : 5000,
          'daily_sleep_target': 8.0,
          'daily_water_target': 3.0,
        };
      } else {
        // Default values for incomplete profiles
        updateData = {
          'daily_active_calories_target': 2000,
          'daily_calories_target': 3500,
          'daily_steps_target': 10000,
          'daily_sleep_target': 8.0,
          'daily_water_target': 3.0,
        };
      }

      // Send update request
      var updateRequest = await client.patchUrl(
        Uri.parse('$supabaseUrl/rest/v1/profiles?id=eq.$id')
      );
      updateRequest.headers.set('apikey', apiKey);
      updateRequest.headers.set('Authorization', 'Bearer $apiKey');
      updateRequest.headers.set('Content-Type', 'application/json');
      updateRequest.headers.set('Prefer', 'return=representation');
      updateRequest.write(jsonEncode(updateData));

      var updateResponse = await updateRequest.close();
      var updateResponseBody = await updateResponse.transform(utf8.decoder).join();

      if (updateResponse.statusCode == 200 || updateResponse.statusCode == 204) {
        if (isVictor) {
          print('✅ Victor\'s profile updated with:');
          print('   Active Calories: 2761');
          print('   Total Calories: 4369');
          print('   Steps: 10000');
          print('   Sleep: 8 hours');
          print('   Water: 3 liters');
        } else {
          print('✓ Updated $name');
        }
      } else {
        print('⚠️ Failed to update $name: ${updateResponse.statusCode}');
        print('   Response: $updateResponseBody');
      }
    }

    print('\n🎉 Database update completed!');
    client.close();

  } catch (e) {
    print('❌ Error: $e');
  }
}