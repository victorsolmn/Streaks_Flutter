import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';

class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({Key? key}) : super(key: key);

  @override
  State<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _caloriesController;
  late TextEditingController _stepsController;
  late TextEditingController _sleepController;
  late TextEditingController _waterController;
  late TextEditingController _targetWeightController;
  
  FitnessGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  
  @override
  void initState() {
    super.initState();
    final profile = Provider.of<UserProvider>(context, listen: false).profile;
    
    // Initialize controllers with current values or calculated defaults
    _caloriesController = TextEditingController(
      text: profile?.dailyCaloriesTarget?.toString() ?? '2000'
    );
    _stepsController = TextEditingController(
      text: profile?.dailyStepsTarget?.toString() ?? '10000'
    );
    _sleepController = TextEditingController(
      text: profile?.dailySleepTarget?.toStringAsFixed(1) ?? '8.0'
    );
    _waterController = TextEditingController(
      text: profile?.dailyWaterTarget?.toStringAsFixed(1) ?? '2.5'
    );
    _targetWeightController = TextEditingController(
      text: profile?.targetWeight.toStringAsFixed(1) ?? '70.0'
    );
    
    _selectedGoal = profile?.goal;
    _selectedActivityLevel = profile?.activityLevel;
  }
  
  @override
  void dispose() {
    _caloriesController.dispose();
    _stepsController.dispose();
    _sleepController.dispose();
    _waterController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }
  
  double _calculateBMI(UserProfile profile) {
    if (profile.height <= 0 || profile.weight <= 0) return 0;
    final heightInMeters = profile.height / 100;
    return profile.weight / (heightInMeters * heightInMeters);
  }
  
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  int _calculateRecommendedCalories(UserProfile profile) {
    // Using Mifflin-St Jeor Equation (assuming male for simplicity)
    double bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5;
    
    // Activity multiplier
    double activityMultiplier;
    switch (_selectedActivityLevel ?? profile.activityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        activityMultiplier = 1.725;
        break;
      case ActivityLevel.extremelyActive:
        activityMultiplier = 1.9;
        break;
    }
    
    double tdee = bmr * activityMultiplier;
    
    // Adjust based on goal
    switch (_selectedGoal ?? profile.goal) {
      case FitnessGoal.weightLoss:
        return (tdee - 500).round();
      case FitnessGoal.muscleGain:
        return (tdee + 300).round();
      case FitnessGoal.maintenance:
      case FitnessGoal.endurance:
        return tdee.round();
    }
  }
  
  int _calculateRecommendedSteps(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 5000;
      case ActivityLevel.lightlyActive:
        return 7500;
      case ActivityLevel.moderatelyActive:
        return 10000;
      case ActivityLevel.veryActive:
        return 12500;
      case ActivityLevel.extremelyActive:
        return 15000;
    }
  }
  
  void _recalculateTargets() {
    final profile = Provider.of<UserProvider>(context, listen: false).profile;
    if (profile == null) return;
    
    setState(() {
      _caloriesController.text = _calculateRecommendedCalories(profile).toString();
      _stepsController.text = _calculateRecommendedSteps(
        _selectedActivityLevel ?? profile.activityLevel
      ).toString();
      
      // Adjust sleep based on goal
      if (_selectedGoal == FitnessGoal.muscleGain) {
        _sleepController.text = '8.0';
      } else {
        _sleepController.text = '7.5';
      }
    });
  }
  
  Future<void> _saveGoals() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profile = userProvider.profile;
      
      if (profile != null) {
        final bmi = _calculateBMI(profile);
        
        await userProvider.updateProfile(
          targetWeight: double.tryParse(_targetWeightController.text),
          goal: _selectedGoal,
          activityLevel: _selectedActivityLevel,
          dailyCaloriesTarget: int.tryParse(_caloriesController.text),
          dailyStepsTarget: int.tryParse(_stepsController.text),
          dailySleepTarget: double.tryParse(_sleepController.text),
          dailyWaterTarget: double.tryParse(_waterController.text),
          bmiValue: bmi,
          bmiCategoryValue: _getBMICategory(bmi),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Goals updated successfully'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.profile;
    
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Goals')),
        body: Center(child: Text('No profile found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Fitness Goals'),
        actions: [
          TextButton(
            onPressed: _saveGoals,
            child: Text('Save', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Stats
              _buildSectionTitle('Current Stats'),
              SizedBox(height: 12),
              _buildInfoCard([
                _InfoRow('Current Weight', '${profile.weight.toStringAsFixed(1)} kg'),
                _InfoRow('Height', '${profile.height.toStringAsFixed(0)} cm'),
                _InfoRow('BMI', profile.bmiValue?.toStringAsFixed(1) ?? _calculateBMI(profile).toStringAsFixed(1)),
                _InfoRow('Category', profile.bmiCategoryValue ?? _getBMICategory(_calculateBMI(profile))),
              ]),
              
              SizedBox(height: 24),
              
              // Fitness Goal
              _buildSectionTitle('Fitness Goal'),
              SizedBox(height: 12),
              DropdownButtonFormField<FitnessGoal>(
                value: _selectedGoal,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: FitnessGoal.values.map((goal) {
                  return DropdownMenuItem(
                    value: goal,
                    child: Text(_formatGoal(goal)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGoal = value;
                  });
                  _recalculateTargets();
                },
              ),
              
              SizedBox(height: 24),
              
              // Activity Level
              _buildSectionTitle('Activity Level'),
              SizedBox(height: 12),
              DropdownButtonFormField<ActivityLevel>(
                value: _selectedActivityLevel,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.directions_run),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ActivityLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(_formatActivityLevel(level)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value;
                  });
                  _recalculateTargets();
                },
              ),
              
              SizedBox(height: 24),
              
              // Daily Targets
              _buildSectionTitle('Daily Targets'),
              SizedBox(height: 12),
              
              // Target Weight
              TextFormField(
                controller: _targetWeightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Weight (kg)',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Your goal weight',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter target weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Calories
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily Calories',
                  prefixIcon: Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Recommended: ${_calculateRecommendedCalories(profile)} kcal',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter daily calories';
                  }
                  final calories = int.tryParse(value);
                  if (calories == null || calories < 1000 || calories > 5000) {
                    return 'Please enter a valid calorie target (1000-5000)';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Steps
              TextFormField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily Steps',
                  prefixIcon: Icon(Icons.directions_walk),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Recommended: ${_calculateRecommendedSteps(_selectedActivityLevel ?? profile.activityLevel)} steps',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter daily steps';
                  }
                  final steps = int.tryParse(value);
                  if (steps == null || steps < 1000 || steps > 50000) {
                    return 'Please enter a valid step target (1000-50000)';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Sleep
              TextFormField(
                controller: _sleepController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Daily Sleep (hours)',
                  prefixIcon: Icon(Icons.bedtime),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Recommended: 7-9 hours',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter daily sleep hours';
                  }
                  final sleep = double.tryParse(value);
                  if (sleep == null || sleep < 4 || sleep > 12) {
                    return 'Please enter a valid sleep target (4-12 hours)';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // Water
              TextFormField(
                controller: _waterController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Daily Water (liters)',
                  prefixIcon: Icon(Icons.water_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Recommended: 2.5-3.5 liters',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter daily water intake';
                  }
                  final water = double.tryParse(value);
                  if (water == null || water < 1 || water > 6) {
                    return 'Please enter a valid water target (1-6 liters)';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 32),
              
              // Recalculate Button
              Center(
                child: OutlinedButton.icon(
                  onPressed: _recalculateTargets,
                  icon: Icon(Icons.calculate),
                  label: Text('Recalculate Recommendations'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    side: BorderSide(color: AppTheme.primaryAccent),
                  ),
                ),
              ),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: rows.map((row) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.label,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                row.value,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
  
  String _formatGoal(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
    }
  }
  
  String _formatActivityLevel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  
  _InfoRow(this.label, this.value);
}