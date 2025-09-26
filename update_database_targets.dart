import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to update database schema and add active calorie targets
void main() async {
  const supabaseUrl = 'https://xzwvckziavhzmghizyqx.supabase.co';
  const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d3Zja3ppYXZoem1naGl6eXF4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODA5OTQ2MiwiZXhwIjoyMDczNjc1NDYyfQ.jXjRDeSc1e3RLQVIxZwNRgYwF-nXmHf4icvnjllW-ao';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseServiceKey, // Using service key for admin operations
  );

  final supabase = Supabase.instance.client;

  try {
    print('🔧 Updating database schema for active calorie targets...\n');

    // 1. Add new column for active calories target
    print('📊 Adding daily_active_calories_target column...');
    try {
      await supabase.rpc('exec_sql', params: {
        'sql': '''
          ALTER TABLE profiles
          ADD COLUMN IF NOT EXISTS daily_active_calories_target INTEGER DEFAULT 2000;
        '''
      });
      print('✅ Column added successfully');
    } catch (e) {
      // Try direct approach if RPC doesn't work
      print('⚠️ RPC approach failed, column may already exist: $e');
    }

    // 2. Update existing profiles with calculated active calorie targets
    print('\n📈 Updating existing profiles with active calorie targets...');

    // Fetch all profiles with fitness data
    final profiles = await supabase
        .from('profiles')
        .select('id, age, height, weight, activity_level, fitness_goal, daily_calories_target')
        .not('age', 'is', null)
        .not('height', 'is', null)
        .not('weight', 'is', null);

    print('Found ${profiles.length} profiles to update');

    for (var profile in profiles) {
      final id = profile['id'];
      final age = profile['age'] as int?;
      final height = profile['height'] as num?;
      final weight = profile['weight'] as num?;
      final activityLevel = profile['activity_level'] as String?;
      final fitnessGoal = profile['fitness_goal'] as String?;

      if (age != null && height != null && weight != null) {
        // Calculate BMR (Mifflin-St Jeor)
        final bmr = (10 * weight.toDouble()) +
                   (6.25 * height.toDouble()) -
                   (5 * age) + 5; // Male formula

        // Get activity multiplier
        double multiplier = 1.55; // Default moderate
        if (activityLevel != null) {
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
        }

        // Calculate TDEE
        final tdee = bmr * multiplier;

        // Calculate active calories (TDEE - BMR)
        var activeCalories = (tdee - bmr).round();

        // Apply goal adjustments to active calories
        if (fitnessGoal != null) {
          switch (fitnessGoal) {
            case 'Lose Weight':
              activeCalories -= 300; // Reduce active calorie target
              break;
            case 'Gain Muscle':
              activeCalories += 200; // Increase active calorie target
              break;
          }
        }

        // Ensure reasonable bounds (500-4000 active calories)
        activeCalories = activeCalories.clamp(500, 4000);

        // Update total calories target to be BMR + active
        final totalCalories = (bmr + activeCalories).round().clamp(1200, 5000);

        // Update the profile
        await supabase.from('profiles').update({
          'daily_active_calories_target': activeCalories,
          'daily_calories_target': totalCalories,
        }).eq('id', id);

        print('  ✓ Updated profile $id: Active=$activeCalories, Total=$totalCalories');
      }
    }

    // 3. Set specific targets for the current user (Victor)
    print('\n🎯 Setting specific targets for current user...');
    final victorProfile = await supabase
        .from('profiles')
        .select()
        .or('email.eq.victorsolmn@gmail.com,name.ilike.%Victor%')
        .maybeSingle();

    if (victorProfile != null) {
      await supabase.from('profiles').update({
        'daily_active_calories_target': 2761,  // As requested
        'daily_calories_target': 4369,         // BMR (~1608) + Active (2761)
        'daily_steps_target': 10000,
        'daily_sleep_target': 8.0,
        'daily_water_target': 3.0,
      }).eq('id', victorProfile['id']);

      print('✅ Updated Victor\'s profile with requested targets');
      print('   - Active Calories: 2761');
      print('   - Total Calories: 4369');
      print('   - Steps: 10000');
      print('   - Sleep: 8 hours');
      print('   - Water: 3 liters');
    }

    print('\n🎉 Database update completed successfully!');
  } catch (e) {
    print('❌ Error updating database: $e');
  }
}