import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/edit_goals_screen.dart';

class FitnessGoalSummaryDialog extends StatelessWidget {
  final VoidCallback onAgree;
  
  const FitnessGoalSummaryDialog({
    Key? key,
    required this.onAgree,
  }) : super(key: key);

  // Calculate BMI
  double calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double calculateTDEE(UserProfile profile) {
    // Using Mifflin-St Jeor Equation
    double bmr;
    
    // For simplicity, assuming male (can be updated to include gender)
    // Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
    bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5;
    
    // Activity multiplier
    double activityMultiplier;
    switch (profile.activityLevel) {
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
    
    return bmr * activityMultiplier;
  }

  // Calculate target calories based on goal
  int calculateTargetCalories(UserProfile profile) {
    double tdee = calculateTDEE(profile);
    
    switch (profile.goal) {
      case FitnessGoal.weightLoss:
        // 500 calorie deficit for ~0.5kg/week loss
        return (tdee - 500).round();
      case FitnessGoal.muscleGain:
        // 300 calorie surplus for lean muscle gain
        return (tdee + 300).round();
      case FitnessGoal.maintenance:
      case FitnessGoal.endurance:
        return tdee.round();
    }
  }

  // Calculate recommended steps
  int calculateTargetSteps(UserProfile profile) {
    switch (profile.activityLevel) {
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

  // Calculate weight change needed
  double calculateWeightChange(UserProfile profile) {
    return profile.targetWeight - profile.weight;
  }

  // Calculate time to reach goal (in weeks)
  int calculateTimeToGoal(UserProfile profile) {
    double weightChange = calculateWeightChange(profile).abs();
    // Healthy weight loss/gain rate: 0.5kg per week
    return (weightChange / 0.5).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.profile;
    
    if (profile == null) return SizedBox.shrink();
    
    final bmi = calculateBMI(profile.weight, profile.height);
    final bmiCategory = getBMICategory(bmi);
    final targetCalories = calculateTargetCalories(profile);
    final maintenanceCalories = calculateTDEE(profile).round();
    final targetSteps = calculateTargetSteps(profile);
    final weightChange = calculateWeightChange(profile);
    final weeksToGoal = calculateTimeToGoal(profile);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Fitness Goal Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Setup Profile (1/3)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionTitle(context, 'Personal Information'),
                    SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      [
                        _InfoRow('Age', '${profile.age} years'),
                        _InfoRow('Height', '${profile.height.toStringAsFixed(0)} cm'),
                        _InfoRow('Current Weight', '${profile.weight.toStringAsFixed(1)} kg'),
                        _InfoRow('Target Weight', '${profile.targetWeight.toStringAsFixed(1)} kg'),
                        _InfoRow(
                          'Weight ${weightChange >= 0 ? "Gain" : "Loss"} Goal', 
                          '${weightChange.abs().toStringAsFixed(1)} kg'
                        ),
                        _InfoRow('Estimated Time', '$weeksToGoal weeks'),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // BMI Analysis
                    _buildSectionTitle(context, 'BMI Analysis'),
                    SizedBox(height: 12),
                    _buildBMICard(context, bmi, bmiCategory),
                    
                    SizedBox(height: 20),
                    
                    // Activity & Goals
                    _buildSectionTitle(context, 'Activity & Goals'),
                    SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      [
                        _InfoRow('Fitness Goal', _formatGoal(profile.goal)),
                        _InfoRow('Activity Level', _formatActivityLevel(profile.activityLevel)),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Your Personalized Plan
                    _buildSectionTitle(context, 'Your Personalized Plan'),
                    SizedBox(height: 12),
                    _buildPlanCard(
                      context,
                      [
                        _PlanItem(
                          icon: Icons.local_fire_department,
                          title: 'Maintenance Calories',
                          value: '$maintenanceCalories kcal/day',
                          subtitle: 'To maintain current weight',
                          color: Colors.orange,
                        ),
                        _PlanItem(
                          icon: Icons.restaurant,
                          title: 'Target Intake',
                          value: '$targetCalories kcal/day',
                          subtitle: _getCalorieSubtitle(profile.goal, maintenanceCalories, targetCalories),
                          color: AppTheme.primaryAccent,
                        ),
                        _PlanItem(
                          icon: Icons.directions_walk,
                          title: 'Daily Steps Goal',
                          value: '$targetSteps steps',
                          subtitle: 'Based on your activity level',
                          color: Colors.blue,
                        ),
                        _PlanItem(
                          icon: Icons.bedtime,
                          title: 'Sleep Target',
                          value: '7-9 hours',
                          subtitle: 'For optimal recovery',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditGoalsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.primaryAccent),
                      ),
                      child: Text('Edit'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Save the calculated targets to the user profile
                        await userProvider.updateProfile(
                          dailyCaloriesTarget: targetCalories,
                          dailyStepsTarget: targetSteps,
                          dailySleepTarget: profile.goal == FitnessGoal.muscleGain ? 8.0 : 7.5,
                          dailyWaterTarget: 2.5, // 2.5 liters default
                          bmiValue: bmi,
                          bmiCategoryValue: bmiCategory,
                          hasSeenFitnessGoalSummary: true,
                        );
                        
                        onAgree();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Agree',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoRow> rows) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
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
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                row.value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBMICard(BuildContext context, double bmi, String category) {
    Color bmiColor;
    IconData bmiIcon;
    
    if (bmi < 18.5) {
      bmiColor = Colors.blue;
      bmiIcon = Icons.trending_down;
    } else if (bmi < 25) {
      bmiColor = Colors.green;
      bmiIcon = Icons.check_circle;
    } else if (bmi < 30) {
      bmiColor = Colors.orange;
      bmiIcon = Icons.warning;
    } else {
      bmiColor = Colors.red;
      bmiIcon = Icons.error;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bmiColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bmiColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            bmiIcon,
            color: bmiColor,
            size: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI: ${bmi.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: bmiColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, List<_PlanItem> items) {
    return Column(
      children: items.map((item) => Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )).toList(),
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

  String _getCalorieSubtitle(FitnessGoal goal, int maintenance, int target) {
    int difference = target - maintenance;
    if (difference < 0) {
      return '${difference.abs()} kcal deficit for weight loss';
    } else if (difference > 0) {
      return '+$difference kcal surplus for muscle gain';
    } else {
      return 'Maintain current weight';
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  
  _InfoRow(this.label, this.value);
}

class _PlanItem {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  
  _PlanItem({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });
}