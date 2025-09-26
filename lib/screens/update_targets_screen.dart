import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to update database with active calorie targets
class UpdateTargetsScreen extends StatefulWidget {
  const UpdateTargetsScreen({Key? key}) : super(key: key);

  @override
  State<UpdateTargetsScreen> createState() => _UpdateTargetsScreenState();
}

class _UpdateTargetsScreenState extends State<UpdateTargetsScreen> {
  final _supabase = Supabase.instance.client;
  String _status = 'Starting update...';
  bool _isUpdating = true;

  @override
  void initState() {
    super.initState();
    _updateDatabase();
  }

  Future<void> _updateDatabase() async {
    try {
      setState(() {
        _status = 'Adding daily_active_calories_target column...';
      });

      // Try to add the column (will fail silently if it exists)
      try {
        await _supabase.rpc('exec_sql', params: {
          'sql': '''
            ALTER TABLE profiles
            ADD COLUMN IF NOT EXISTS daily_active_calories_target INTEGER DEFAULT 2000;
          '''
        });
      } catch (e) {
        print('Column may already exist: $e');
      }

      setState(() {
        _status = 'Fetching profiles to update...';
      });

      // Get all profiles with fitness data
      final profiles = await _supabase
          .from('profiles')
          .select('id, age, height, weight, activity_level, fitness_goal, daily_calories_target, gender')
          .not('age', 'is', null)
          .not('height', 'is', null)
          .not('weight', 'is', null);

      setState(() {
        _status = 'Updating ${profiles.length} profiles...';
      });

      int updated = 0;
      for (var profile in profiles) {
        final id = profile['id'];
        final age = profile['age'] as int?;
        final height = (profile['height'] as num?)?.toDouble();
        final weight = (profile['weight'] as num?)?.toDouble();
        final activityLevel = profile['activity_level'] as String?;
        final fitnessGoal = profile['fitness_goal'] as String?;
        final gender = profile['gender'] as String?;

        if (age != null && height != null && weight != null) {
          // Calculate BMR (using gender if available)
          double bmr;
          if (gender == 'Female') {
            // Women: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
          } else {
            // Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
          }

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

          // Calculate TDEE and active calories
          final tdee = bmr * multiplier;
          var activeCalories = (tdee - bmr).round();

          // Apply goal adjustments
          if (fitnessGoal != null) {
            switch (fitnessGoal) {
              case 'Lose Weight':
                activeCalories -= 200; // Reduce active calorie target
                break;
              case 'Gain Muscle':
                activeCalories += 150; // Increase active calorie target
                break;
            }
          }

          // Ensure reasonable bounds
          activeCalories = activeCalories.clamp(500, 4000);
          final totalCalories = (bmr + activeCalories).round().clamp(1200, 5000);

          // Update the profile
          await _supabase.from('profiles').update({
            'daily_active_calories_target': activeCalories,
            'daily_calories_target': totalCalories,
          }).eq('id', id);

          updated++;
          setState(() {
            _status = 'Updated $updated/${profiles.length} profiles...';
          });
        }
      }

      // Set specific targets for current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _status = 'Setting your specific targets...';
        });

        await _supabase.from('profiles').update({
          'daily_active_calories_target': 2761,  // As requested
          'daily_calories_target': 4369,         // BMR (~1608) + Active (2761)
          'daily_steps_target': 10000,
          'daily_sleep_target': 8.0,
          'daily_water_target': 3.0,
        }).eq('id', currentUser.id);

        setState(() {
          _status = 'Success! Your targets updated:\n'
              'Active Calories: 2761\n'
              'Total Calories: 4369\n'
              'Steps: 10000\n'
              'Sleep: 8 hours\n'
              'Water: 3 liters';
          _isUpdating = false;
        });
      } else {
        setState(() {
          _status = 'Success! Updated $updated profiles.';
          _isUpdating = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Database Targets'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUpdating)
                CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (!_isUpdating)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}