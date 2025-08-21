import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/metric_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer2<UserProvider, NutritionProvider>(
        builder: (context, userProvider, nutritionProvider, child) {
          final profile = userProvider.profile;
          final streakData = userProvider.streakData;
          
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
                  _buildProfileHeader(profile, streakData),
                  const SizedBox(height: 24),
                  
                  // Stats overview
                  _buildStatsOverview(userProvider, nutritionProvider),
                  const SizedBox(height: 24),
                  
                  // Health metrics
                  if (profile != null) ...[
                    _buildHealthMetrics(profile),
                    const SizedBox(height: 24),
                  ],
                  
                  // Settings and actions
                  _buildSettingsSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile? profile, StreakData? streakData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentOrange,
            Color(0xFFFF8F00),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Profile avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.textPrimary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.textPrimary,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            profile?.name ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            profile?.email ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileStat(
                label: 'Streak',
                value: '${streakData?.currentStreak ?? 0}',
                unit: 'days',
              ),
              _ProfileStat(
                label: 'Best',
                value: '${streakData?.longestStreak ?? 0}',
                unit: 'days',
              ),
              _ProfileStat(
                label: 'Goal',
                value: _getGoalShortName(profile?.goal),
                unit: '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(UserProvider userProvider, NutritionProvider nutritionProvider) {
    final weeklyActivity = userProvider.getWeeklyActivityCount();
    final monthlyActivity = userProvider.getMonthlyActivityCount();
    final todayNutrition = nutritionProvider.todayNutrition;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'This Week',
                value: '$weeklyActivity',
                subtitle: 'active days',
                icon: Icons.calendar_view_week,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: StatCard(
                label: 'This Month',
                value: '$monthlyActivity',
                subtitle: 'active days',
                icon: Icons.calendar_month,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Today Calories',
                value: '${todayNutrition.totalCalories}',
                subtitle: '${nutritionProvider.calorieGoal} goal',
                icon: Icons.local_fire_department,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: StatCard(
                label: 'Total Entries',
                value: '${nutritionProvider.entries.length}',
                subtitle: 'meals logged',
                icon: Icons.restaurant,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthMetrics(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _showEditProfileDialog(profile),
              child: Text(
                'Edit',
                style: TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Weight',
                value: '${profile.weight.round()}',
                unit: 'kg',
                icon: Icons.monitor_weight,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: MetricCard(
                title: 'Height',
                value: '${profile.height.round()}',
                unit: 'cm',
                icon: Icons.height,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value: profile.bmi.toStringAsFixed(1),
                subtitle: profile.bmiCategory,
                icon: Icons.calculate,
                color: _getBMIColor(profile.bmi),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: MetricCard(
                title: 'Age',
                value: '${profile.age}',
                unit: 'years',
                icon: Icons.cake,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        _SettingsItem(
          icon: Icons.track_changes,
          title: 'Nutrition Goals',
          subtitle: 'Adjust your daily targets',
          onTap: () => _showNutritionGoalsDialog(),
        ),
        
        _SettingsItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage your reminders',
          onTap: () => _showNotificationsDialog(),
        ),
        
        _SettingsItem(
          icon: Icons.backup,
          title: 'Data Export',
          subtitle: 'Export your fitness data',
          onTap: () => _showDataExportDialog(),
        ),
        
        _SettingsItem(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () => _showHelpDialog(),
        ),
        
        _SettingsItem(
          icon: Icons.info,
          title: 'About',
          subtitle: 'App version and information',
          onTap: () => _showAboutDialog(),
        ),
        
        const SizedBox(height: 32),
        
        // Logout button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showLogoutDialog(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorRed),
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  String _getGoalShortName(FitnessGoal? goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Lose';
      case FitnessGoal.muscleGain:
        return 'Gain';
      case FitnessGoal.maintenance:
        return 'Maintain';
      case FitnessGoal.endurance:
        return 'Endure';
      default:
        return 'None';
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppTheme.successGreen;
    if (bmi < 30) return Colors.orange;
    return AppTheme.errorRed;
  }

  void _showEditProfileDialog(UserProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age.toString());
    final heightController = TextEditingController(text: profile.height.toString());
    final weightController = TextEditingController(text: profile.weight.toString());
    FitnessGoal selectedGoal = profile.goal;
    ActivityLevel selectedActivity = profile.activityLevel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.secondaryBackground,
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<FitnessGoal>(
                  value: selectedGoal,
                  decoration: const InputDecoration(labelText: 'Fitness Goal'),
                  items: FitnessGoal.values.map((goal) {
                    return DropdownMenuItem(
                      value: goal,
                      child: Text(_getGoalName(goal)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedGoal = value!),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<ActivityLevel>(
                  value: selectedActivity,
                  decoration: const InputDecoration(labelText: 'Activity Level'),
                  items: ActivityLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(_getActivityLevelName(level)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedActivity = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.updateProfile(
                  name: nameController.text,
                  age: int.tryParse(ageController.text),
                  height: double.tryParse(heightController.text),
                  weight: double.tryParse(weightController.text),
                  goal: selectedGoal,
                  activityLevel: selectedActivity,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionGoalsDialog() {
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    final calorieController = TextEditingController(text: nutritionProvider.calorieGoal.toString());
    final proteinController = TextEditingController(text: nutritionProvider.proteinGoal.toString());
    final carbController = TextEditingController(text: nutritionProvider.carbGoal.toString());
    final fatController = TextEditingController(text: nutritionProvider.fatGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Nutrition Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calorieController,
              decoration: const InputDecoration(labelText: 'Daily Calories'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: proteinController,
              decoration: const InputDecoration(labelText: 'Protein (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: carbController,
              decoration: const InputDecoration(labelText: 'Carbs (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: fatController,
              decoration: const InputDecoration(labelText: 'Fat (g)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await nutritionProvider.updateGoals(
                calorieGoal: int.tryParse(calorieController.text),
                proteinGoal: double.tryParse(proteinController.text),
                carbGoal: double.tryParse(carbController.text),
                fatGoal: double.tryParse(fatController.text),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('App Settings'),
        content: const Text('More settings will be available in future updates!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Notifications'),
        content: const Text('Notification settings will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Data Export'),
        content: const Text('Data export functionality will be added in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Help & Support'),
        content: const Text('For support, please contact us at support@streaker.app\n\nWe\'re here to help you achieve your fitness goals!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('About Streaker'),
        content: const Text('Streaker v1.0.0\n\nYour personal fitness companion for tracking nutrition, building streaks, and achieving your health goals.\n\nBuilt with Flutter 💙'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _getGoalName(FitnessGoal goal) {
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

  String _getActivityLevelName(ActivityLevel level) {
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

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty) ...[
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary.withOpacity(0.8),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentOrange,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textSecondary,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        tileColor: AppTheme.secondaryBackground,
      ),
    );
  }
}