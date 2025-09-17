import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/supabase_user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../main/main_screen.dart';
import '../auth/welcome_screen.dart';

class EnhancedOnboardingScreen extends StatefulWidget {
  const EnhancedOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedOnboardingScreen> createState() => _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  // Selected values
  FitnessGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  String? _selectedExperienceLevel;
  String? _selectedWorkoutConsistency;

  // Calculated targets
  Map<String, dynamic> _calculatedTargets = {};

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate name and email from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        _nameController.text = currentUser.userMetadata?['name'] ??
                               currentUser.email?.split('@')[0] ?? '';
      }
    });
  }

  Map<String, dynamic> _calculateDailyTargets() {
    if (_ageController.text.isEmpty || _heightController.text.isEmpty ||
        _weightController.text.isEmpty || _selectedActivityLevel == null ||
        _selectedGoal == null) {
      return {};
    }

    final age = int.parse(_ageController.text);
    final height = double.parse(_heightController.text);
    final weight = double.parse(_weightController.text);
    final targetWeight = _targetWeightController.text.isNotEmpty
        ? double.parse(_targetWeightController.text)
        : weight;

    // Calculate BMR using Mifflin-St Jeor Equation (assuming male for simplicity)
    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;

    // Activity multipliers
    double activityMultiplier;
    switch (_selectedActivityLevel!) {
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

    // Adjust calories based on goal
    int targetCalories;
    switch (_selectedGoal!) {
      case FitnessGoal.weightLoss:
        targetCalories = (tdee - 500).round(); // 500 cal deficit
        break;
      case FitnessGoal.muscleGain:
        targetCalories = (tdee + 300).round(); // 300 cal surplus
        break;
      case FitnessGoal.maintenance:
        targetCalories = tdee.round();
        break;
      case FitnessGoal.endurance:
        targetCalories = (tdee + 100).round(); // Slight surplus for performance
        break;
    }

    // Calculate other targets based on activity level and goals
    int stepsTarget;
    switch (_selectedActivityLevel!) {
      case ActivityLevel.sedentary:
        stepsTarget = 6000;
        break;
      case ActivityLevel.lightlyActive:
        stepsTarget = 8000;
        break;
      case ActivityLevel.moderatelyActive:
        stepsTarget = 10000;
        break;
      case ActivityLevel.veryActive:
        stepsTarget = 12000;
        break;
      case ActivityLevel.extremelyActive:
        stepsTarget = 15000;
        break;
    }

    // Sleep target based on age and activity
    double sleepTarget = age < 25 ? 8.5 : age < 50 ? 8.0 : 7.5;
    if (_selectedActivityLevel == ActivityLevel.veryActive ||
        _selectedActivityLevel == ActivityLevel.extremelyActive) {
      sleepTarget += 0.5; // More recovery needed
    }

    return {
      'calories': targetCalories,
      'steps': stepsTarget,
      'sleep': sleepTarget,
      'water': 3.0, // 3 liters default
      'protein': (weight * 1.6).round(), // 1.6g per kg body weight
    };
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGoal == null || _selectedActivityLevel == null ||
          _selectedExperienceLevel == null || _selectedWorkoutConsistency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isProcessing = true);

      final supabaseUserProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
      final supabaseAuth = Provider.of<SupabaseAuthProvider>(context, listen: false);

      final currentUser = supabaseAuth.currentUser;
      final email = currentUser?.email ?? 'user@example.com';

      // Calculate targets
      _calculatedTargets = _calculateDailyTargets();

      // Create comprehensive user profile
      final userProfile = UserProfile(
        name: _nameController.text.trim(),
        email: email,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        targetWeight: _targetWeightController.text.isNotEmpty
            ? double.parse(_targetWeightController.text)
            : double.parse(_weightController.text),
        fitnessGoal: _selectedGoal == FitnessGoal.weightLoss ? 'Lose Weight' :
                    _selectedGoal == FitnessGoal.muscleGain ? 'Gain Muscle' :
                    _selectedGoal == FitnessGoal.maintenance ? 'Maintain Weight' :
                    'Improve Endurance',
        activityLevel: _selectedActivityLevel == ActivityLevel.sedentary ? 'Sedentary' :
                      _selectedActivityLevel == ActivityLevel.lightlyActive ? 'Lightly Active' :
                      _selectedActivityLevel == ActivityLevel.moderatelyActive ? 'Moderately Active' :
                      _selectedActivityLevel == ActivityLevel.veryActive ? 'Very Active' :
                      'Extra Active',
        experienceLevel: _selectedExperienceLevel!,
        workoutConsistency: _selectedWorkoutConsistency!,
        hasCompletedOnboarding: true,
        // Set calculated daily targets
        dailyCaloriesTarget: _calculatedTargets['calories'],
        dailyStepsTarget: _calculatedTargets['steps'],
        dailySleepTarget: _calculatedTargets['sleep'],
        dailyWaterTarget: _calculatedTargets['water'],
      );

      try {
        await supabaseUserProvider.updateProfile(userProfile);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Setup Profile (${_currentStep + 1}/4)'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final supabaseAuth = Provider.of<SupabaseAuthProvider>(context, listen: false);
            await supabaseAuth.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final supabaseUserProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
              final supabaseAuth = Provider.of<SupabaseAuthProvider>(context, listen: false);

              final currentUser = supabaseAuth.currentUser;
              final name = currentUser?.userMetadata?['name'] ??
                           currentUser?.email?.split('@')[0] ?? 'User';
              final email = currentUser?.email ?? 'user@example.com';

              // Create basic profile with smart defaults
              final defaultProfile = UserProfile(
                name: name,
                email: email,
                age: 25,
                height: 170.0,
                weight: 70.0,
                targetWeight: 68.0,
                fitnessGoal: 'Maintain Weight',
                activityLevel: 'Moderately Active',
                experienceLevel: 'Beginner',
                workoutConsistency: '0-1 year',
                hasCompletedOnboarding: true,
                dailyCaloriesTarget: 2000,
                dailyStepsTarget: 10000,
                dailySleepTarget: 8.0,
                dailyWaterTarget: 3.0,
              );

              await supabaseUserProvider.updateProfile(defaultProfile);

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Consumer<SupabaseUserProvider>(
        builder: (context, user, child) {
          return SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 4,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                  ),
                ),

                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildCurrentStep(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation buttons
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],

                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: (user.isLoading || _isProcessing) ? null : _handleNext,
                          child: user.isLoading || _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_currentStep == 3 ? 'Complete' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildFitnessGoalsStep();
      case 2:
        return _buildActivityExperienceStep();
      case 3:
        return _buildSummaryStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Tell us about yourself to personalize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 48),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  suffixText: 'years',
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return 'Enter valid age (13-100)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height',
                  suffixText: 'cm',
                  prefixIcon: Icon(Icons.height),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Enter valid height';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Weight',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 30 || weight > 300) {
                    return 'Enter valid weight';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _targetWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Weight',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 30 || weight > 300) {
                      return 'Enter valid weight';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFitnessGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Goals',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'What\'s your primary fitness objective?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 48),

        Column(
          children: [
            _GoalOption(
              goal: FitnessGoal.weightLoss,
              title: 'Lose Weight',
              subtitle: 'Burn calories and reduce body fat',
              icon: Icons.trending_down,
              isSelected: _selectedGoal == FitnessGoal.weightLoss,
              onTap: () => setState(() => _selectedGoal = FitnessGoal.weightLoss),
            ),
            const SizedBox(height: 16),

            _GoalOption(
              goal: FitnessGoal.muscleGain,
              title: 'Build Muscle',
              subtitle: 'Gain strength and muscle mass',
              icon: Icons.fitness_center,
              isSelected: _selectedGoal == FitnessGoal.muscleGain,
              onTap: () => setState(() => _selectedGoal = FitnessGoal.muscleGain),
            ),
            const SizedBox(height: 16),

            _GoalOption(
              goal: FitnessGoal.maintenance,
              title: 'Stay Healthy',
              subtitle: 'Maintain current fitness level',
              icon: Icons.favorite,
              isSelected: _selectedGoal == FitnessGoal.maintenance,
              onTap: () => setState(() => _selectedGoal = FitnessGoal.maintenance),
            ),
            const SizedBox(height: 16),

            _GoalOption(
              goal: FitnessGoal.endurance,
              title: 'Build Endurance',
              subtitle: 'Improve stamina and cardiovascular health',
              icon: Icons.directions_run,
              isSelected: _selectedGoal == FitnessGoal.endurance,
              onTap: () => setState(() => _selectedGoal = FitnessGoal.endurance),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity & Experience',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Help us understand your current fitness level',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 32),

        // Activity Level Section
        Text(
          'How active are you currently?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Column(
          children: [
            _ActivityOption(
              level: ActivityLevel.sedentary,
              title: 'Sedentary',
              subtitle: 'Little to no exercise',
              isSelected: _selectedActivityLevel == ActivityLevel.sedentary,
              onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.sedentary),
            ),
            const SizedBox(height: 12),

            _ActivityOption(
              level: ActivityLevel.lightlyActive,
              title: 'Lightly Active',
              subtitle: 'Light exercise 1-3 days/week',
              isSelected: _selectedActivityLevel == ActivityLevel.lightlyActive,
              onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.lightlyActive),
            ),
            const SizedBox(height: 12),

            _ActivityOption(
              level: ActivityLevel.moderatelyActive,
              title: 'Moderately Active',
              subtitle: 'Moderate exercise 3-5 days/week',
              isSelected: _selectedActivityLevel == ActivityLevel.moderatelyActive,
              onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.moderatelyActive),
            ),
            const SizedBox(height: 12),

            _ActivityOption(
              level: ActivityLevel.veryActive,
              title: 'Very Active',
              subtitle: 'Hard exercise 6-7 days/week',
              isSelected: _selectedActivityLevel == ActivityLevel.veryActive,
              onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.veryActive),
            ),
            const SizedBox(height: 12),

            _ActivityOption(
              level: ActivityLevel.extremelyActive,
              title: 'Extremely Active',
              subtitle: 'Very hard exercise, physical job',
              isSelected: _selectedActivityLevel == ActivityLevel.extremelyActive,
              onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.extremelyActive),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Experience Level
        Text(
          'Experience Level',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        _buildDropdown(
          value: _selectedExperienceLevel,
          hint: 'Select your experience level',
          items: [
            _buildDropdownItem('Beginner', 'New to fitness and exercise', Icons.school),
            _buildDropdownItem('Intermediate', 'Some fitness experience', Icons.trending_up),
            _buildDropdownItem('Expert', 'Advanced fitness knowledge', Icons.star),
          ],
          onChanged: (value) => setState(() => _selectedExperienceLevel = value),
        ),

        const SizedBox(height: 24),

        // Workout Consistency
        Text(
          'Workout Consistency',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        _buildDropdown(
          value: _selectedWorkoutConsistency,
          hint: 'How long have you been working out consistently?',
          items: [
            _buildDropdownItem('0-1 year', 'Just started or inconsistent', Icons.access_time),
            _buildDropdownItem('1-3 years', 'Building consistency', Icons.schedule),
            _buildDropdownItem('> 3 years', 'Established routine', Icons.timer),
          ],
          onChanged: (value) => setState(() => _selectedWorkoutConsistency = value),
        ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    // Calculate targets for display
    _calculatedTargets = _calculateDailyTargets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary & Daily Targets',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Based on your information, here are your personalized daily targets',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 32),

        // Profile Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryAccent.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(height: 16),

              _buildSummaryRow('Name', _nameController.text),
              _buildSummaryRow('Age', '${_ageController.text} years'),
              _buildSummaryRow('Height/Weight', '${_heightController.text} cm / ${_weightController.text} kg'),
              if (_targetWeightController.text.isNotEmpty)
                _buildSummaryRow('Target Weight', '${_targetWeightController.text} kg'),
              _buildSummaryRow('Fitness Goal', _getGoalText(_selectedGoal)),
              _buildSummaryRow('Activity Level', _getActivityLevelText(_selectedActivityLevel)),
              _buildSummaryRow('Experience', _selectedExperienceLevel ?? ''),
              _buildSummaryRow('Consistency', _selectedWorkoutConsistency ?? ''),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Daily Targets
        if (_calculatedTargets.isNotEmpty) ...[
          Text(
            'Your Daily Targets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTargetCard(
                icon: Icons.local_fire_department,
                label: 'Calories',
                value: '${_calculatedTargets['calories']} kcal',
                color: Colors.orange,
              ),
              _buildTargetCard(
                icon: Icons.directions_walk,
                label: 'Steps',
                value: '${_calculatedTargets['steps']} steps',
                color: Colors.blue,
              ),
              _buildTargetCard(
                icon: Icons.bedtime,
                label: 'Sleep',
                value: '${_calculatedTargets['sleep']?.toStringAsFixed(1)}h',
                color: Colors.purple,
              ),
              _buildTargetCard(
                icon: Icons.water_drop,
                label: 'Water',
                value: '${_calculatedTargets['water']}L',
                color: Colors.cyan,
              ),
              _buildTargetCard(
                icon: Icons.restaurant,
                label: 'Protein',
                value: '${_calculatedTargets['protein']}g',
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These targets are calculated based on your personal information and can be adjusted later in your profile settings.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Theme.of(context).hintColor)),
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String subtitle, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalText(FitnessGoal? goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Lose Weight';
      case FitnessGoal.muscleGain:
        return 'Build Muscle';
      case FitnessGoal.maintenance:
        return 'Stay Healthy';
      case FitnessGoal.endurance:
        return 'Build Endurance';
      default:
        return '';
    }
  }

  String _getActivityLevelText(ActivityLevel? level) {
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
      default:
        return '';
    }
  }

  void _handleNext() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });

    // Validate current step
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_selectedGoal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a fitness goal'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedActivityLevel == null || _selectedExperienceLevel == null || _selectedWorkoutConsistency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all fields'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    } else if (_currentStep == 3) {
      _completeOnboarding();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }
}

// Goal Option Widget
class _GoalOption extends StatelessWidget {
  final FitnessGoal goal;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.goal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryAccent.withOpacity(0.8),
                          AppTheme.primaryHover.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppTheme.primaryAccent : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Activity Option Widget
class _ActivityOption extends StatelessWidget {
  final ActivityLevel level;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityOption({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppTheme.primaryAccent : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}