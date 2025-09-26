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

  // Calculate target calories based on goal (total calories)
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

  // Calculate active calories (separate from BMR)
  int calculateActiveCalories(UserProfile profile) {
    // Calculate BMR
    double bmr = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age) + 5;
    double tdee = calculateTDEE(profile);

    // Active calories = TDEE - BMR
    var activeCalories = (tdee - bmr).round();

    // Apply goal adjustments to active calories
    switch (profile.goal) {
      case FitnessGoal.weightLoss:
        activeCalories -= 200; // Reduce active target
        break;
      case FitnessGoal.muscleGain:
        activeCalories += 150; // Increase active target
        break;
      default:
        break;
    }

    return activeCalories.clamp(500, 4000);
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
    final activeCalories = calculateActiveCalories(profile);
    final maintenanceCalories = calculateTDEE(profile).round();
    final targetSteps = calculateTargetSteps(profile);
    final weightChange = calculateWeightChange(profile);
    final weeksToGoal = calculateTimeToGoal(profile);
    
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced Header with close button
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Fitness Goal Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Setup Profile (1/3)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      fixedSize: Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),
            
            // Enhanced Content with better spacing
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact Personal Info & BMI in two columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Personal Info
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactSectionTitle(context, 'Personal Info'),
                              SizedBox(height: 8),
                              _buildCompactInfoCard(
                                context,
                                [
                                  _CompactInfoRow('Age', '${profile.age}y', Icons.cake),
                                  _CompactInfoRow('Height', '${profile.height.toStringAsFixed(0)}cm', Icons.height),
                                  _CompactInfoRow('Current', '${profile.weight.toStringAsFixed(1)}kg', Icons.monitor_weight),
                                  _CompactInfoRow('Target', '${profile.targetWeight.toStringAsFixed(1)}kg', Icons.flag),
                                  _CompactInfoRow('${weightChange >= 0 ? "Gain" : "Loss"}', '${weightChange.abs().toStringAsFixed(1)}kg', Icons.trending_up),
                                  _CompactInfoRow('Timeline', '$weeksToGoal weeks', Icons.schedule),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // Right column - BMI
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactSectionTitle(context, 'BMI Analysis'),
                              SizedBox(height: 8),
                              _buildEnhancedBMICard(context, bmi, bmiCategory),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Activity & Goals in compact format
                    _buildCompactSectionTitle(context, 'Fitness Profile'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGoalChip(context, _formatGoal(profile.goal), Icons.track_changes),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildGoalChip(context, _formatActivityLevel(profile.activityLevel), Icons.directions_run),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Enhanced Personalized Plan with grid layout
                    _buildCompactSectionTitle(context, 'Your Personalized Plan'),
                    SizedBox(height: 8),
                    _buildEnhancedPlanGrid(
                      context,
                      [
                        _PlanItem(
                          icon: Icons.local_fire_department,
                          title: 'Active Cal',
                          value: '${(activeCalories / 1000).toStringAsFixed(1)}k',
                          subtitle: 'burn/day',
                          color: Colors.orange,
                        ),
                        _PlanItem(
                          icon: Icons.restaurant,
                          title: 'Total Intake',
                          value: '${(targetCalories / 1000).toStringAsFixed(1)}k',
                          subtitle: _getShortCalorieSubtitle(profile.goal, maintenanceCalories, targetCalories),
                          color: AppTheme.primaryAccent,
                        ),
                        _PlanItem(
                          icon: Icons.directions_walk,
                          title: 'Daily Steps',
                          value: '${(targetSteps / 1000).toStringAsFixed(1)}k',
                          subtitle: 'steps/day',
                          color: AppTheme.accentCyan,
                        ),
                        _PlanItem(
                          icon: Icons.bedtime,
                          title: 'Sleep Target',
                          value: '7-9h',
                          subtitle: 'recovery',
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Enhanced Action Buttons
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryAccent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Edit Goals',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: AppTheme.buttonShadow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Save the calculated targets to the user profile
                          await userProvider.updateProfile(
                            dailyCaloriesTarget: targetCalories,
                            dailyActiveCaloriesTarget: activeCalories,
                            dailyStepsTarget: targetSteps,
                            dailySleepTarget: profile.goal == FitnessGoal.muscleGain ? 8.0 : 7.5,
                            dailyWaterTarget: 3.0, // 3 liters default
                            bmiValue: bmi,
                            bmiCategoryValue: bmiCategory,
                            hasSeenFitnessGoalSummary: true,
                          );
                          
                          onAgree();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start My Journey',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 18,
                            ),
                          ],
                        ),
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

  Widget _buildCompactSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCompactInfoCard(BuildContext context, List<_CompactInfoRow> rows) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Container(
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: index < rows.length - 1 ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ) : null,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    row.icon,
                    size: 14,
                    color: AppTheme.primaryAccent,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedBMICard(BuildContext context, double bmi, String category) {
    Color bmiColor;
    IconData bmiIcon;
    
    if (bmi < 18.5) {
      bmiColor = Colors.blue;
      bmiIcon = Icons.trending_down;
    } else if (bmi < 25) {
      bmiColor = AppTheme.successGreen;
      bmiIcon = Icons.check_circle;
    } else if (bmi < 30) {
      bmiColor = AppTheme.warningYellow;
      bmiIcon = Icons.warning;
    } else {
      bmiColor = AppTheme.errorRed;
      bmiIcon = Icons.error;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bmiColor.withOpacity(0.15),
            bmiColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bmiColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              bmiIcon,
              color: bmiColor,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${bmi.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: bmiColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 2),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              color: bmiColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip(BuildContext context, String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryAccent,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlanGrid(BuildContext context, List<_PlanItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.35,
      children: items.map((item) => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: item.color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 16,
              ),
            ),
            SizedBox(height: 6),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              item.value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (item.subtitle != null) ...[
              SizedBox(height: 1),
              Text(
                item.subtitle!,
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  String _getShortCalorieSubtitle(FitnessGoal goal, int maintenance, int target) {
    int difference = target - maintenance;
    if (difference < 0) {
      return '${difference.abs()}kcal deficit';
    } else if (difference > 0) {
      return '+${difference}kcal surplus';
    } else {
      return 'maintenance';
    }
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

class _CompactInfoRow {
  final String label;
  final String value;
  final IconData icon;
  
  _CompactInfoRow(this.label, this.value, this.icon);
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