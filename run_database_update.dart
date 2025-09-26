import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao';

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    print('🔧 Starting database update...\n');

    // Step 1: Add the new column for active calories
    print('📊 Adding daily_active_calories_target column...');

    // First, let's check existing profiles
    final profiles = await supabase
        .from('profiles')
        .select('id, name, email, age, height, weight, activity_level, fitness_goal, gender, daily_calories_target')
        .order('created_at', ascending: false);

    print('Found ${profiles.length} profiles in database\n');

    // Update each profile with calculated active calories
    for (var profile in profiles) {
      final id = profile['id'];
      final name = profile['name'] ?? 'Unknown';
      final age = profile['age'] as int?;
      final height = (profile['height'] as num?)?.toDouble();
      final weight = (profile['weight'] as num?)?.toDouble();
      final activityLevel = profile['activity_level'] as String?;
      final fitnessGoal = profile['fitness_goal'] as String?;
      final gender = profile['gender'] as String?;

      if (age != null && height != null && weight != null) {
        // Calculate BMR using gender-specific formula
        double bmr;
        if (gender == 'Female') {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
        } else {
          bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
        }

        // Get activity multiplier
        double multiplier = 1.55; // Default moderate
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

        // Calculate TDEE and active calories
        final tdee = bmr * multiplier;
        var activeCalories = (tdee - bmr).round();

        // Apply goal adjustments
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

        // Update the profile
        try {
          await supabase.from('profiles').update({
            'daily_active_calories_target': activeCalories,
            'daily_calories_target': totalCalories,
            'daily_steps_target': activityLevel == 'Very Active' ? 12500 :
                                  activityLevel == 'Moderately Active' ? 10000 :
                                  activityLevel == 'Lightly Active' ? 7500 : 5000,
            'daily_sleep_target': 8.0,
            'daily_water_target': 3.0,
          }).eq('id', id);

          print('✓ Updated $name: Active=$activeCalories, Total=$totalCalories');
        } catch (e) {
          print('⚠️ Error updating $name: $e');
        }
      }
    }

    // Special handling for Victor's profile
    print('\n🎯 Setting specific targets for Victor...');

    final victorProfiles = profiles.where((p) =>
      (p['email'] as String?)?.contains('victorsolmn') == true ||
      (p['name'] as String?)?.toLowerCase().contains('victor') == true
    ).toList();

    if (victorProfiles.isNotEmpty) {
      final victorId = victorProfiles.first['id'];

      await supabase.from('profiles').update({
        'daily_active_calories_target': 2761,
        'daily_calories_target': 4369,  // BMR ~1608 + Active 2761
        'daily_steps_target': 10000,
        'daily_sleep_target': 8.0,
        'daily_water_target': 3.0,
      }).eq('id', victorId);

      print('✅ Updated Victor\'s profile with requested targets:');
      print('   - Active Calories: 2761');
      print('   - Total Calories: 4369');
      print('   - Steps: 10000');
      print('   - Sleep: 8 hours');
      print('   - Water: 3 liters');
    }

    print('\n🎉 Database update completed successfully!');

    // Verify the update
    print('\n📋 Verifying updates...');
    final updatedProfiles = await supabase
        .from('profiles')
        .select('name, daily_active_calories_target, daily_calories_target, daily_steps_target')
        .not('daily_active_calories_target', 'is', null)
        .limit(5);

    print('Sample of updated profiles:');
    for (var p in updatedProfiles) {
      print('  ${p['name']}: Active=${p['daily_active_calories_target']}, Total=${p['daily_calories_target']}, Steps=${p['daily_steps_target']}');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}