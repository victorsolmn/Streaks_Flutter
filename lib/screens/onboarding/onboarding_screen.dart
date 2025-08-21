import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../main/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  FitnessGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final name = userProvider.profile?.name ?? 'User';
      final email = userProvider.profile?.email ?? 'user@example.com';

      await userProvider.createProfile(
        name: name,
        email: email,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        goal: _selectedGoal!,
        activityLevel: _selectedActivityLevel!,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Profile (${_currentStep + 1}/3)'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, user, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                ),
                
                const SizedBox(height: 32),
                
                Expanded(
                  child: _buildCurrentStep(),
                ),
                
                // Navigation buttons
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
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
                        onPressed: user.isLoading ? null : _handleNext,
                        child: user.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.textPrimary,
                                ),
                              )
                            : Text(_currentStep == 2 ? 'Complete' : 'Next'),
                      ),
                    ),
                  ],
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
        return _buildGoalSelection();
      case 1:
        return _buildActivityLevel();
      case 2:
        return _buildPersonalInfo();
      default:
        return Container();
    }
  }

  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your fitness goal?',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'This helps us personalize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 48),
        
        Expanded(
          child: Column(
            children: [
              _GoalOption(
                goal: FitnessGoal.weightLoss,
                title: 'Lose Weight',
                subtitle: 'Burn calories and get fit',
                icon: Icons.trending_down,
                isSelected: _selectedGoal == FitnessGoal.weightLoss,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.weightLoss),
              ),
              const SizedBox(height: 16),
              
              _GoalOption(
                goal: FitnessGoal.muscleGain,
                title: 'Build Muscle',
                subtitle: 'Gain strength and mass',
                icon: Icons.fitness_center,
                isSelected: _selectedGoal == FitnessGoal.muscleGain,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.muscleGain),
              ),
              const SizedBox(height: 16),
              
              _GoalOption(
                goal: FitnessGoal.maintenance,
                title: 'Stay Healthy',
                subtitle: 'Maintain current fitness',
                icon: Icons.favorite,
                isSelected: _selectedGoal == FitnessGoal.maintenance,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.maintenance),
              ),
              const SizedBox(height: 16),
              
              _GoalOption(
                goal: FitnessGoal.endurance,
                title: 'Build Endurance',
                subtitle: 'Improve stamina and cardio',
                icon: Icons.directions_run,
                isSelected: _selectedGoal == FitnessGoal.endurance,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.endurance),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How active are you?',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'This helps calculate your daily calorie needs',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 48),
        
        Expanded(
          child: Column(
            children: [
              _ActivityOption(
                level: ActivityLevel.sedentary,
                title: 'Sedentary',
                subtitle: 'Little to no exercise',
                isSelected: _selectedActivityLevel == ActivityLevel.sedentary,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.sedentary),
              ),
              const SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.lightlyActive,
                title: 'Lightly Active',
                subtitle: 'Light exercise 1-3 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.lightlyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.lightlyActive),
              ),
              const SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.moderatelyActive,
                title: 'Moderately Active',
                subtitle: 'Moderate exercise 3-5 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.moderatelyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.moderatelyActive),
              ),
              const SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.veryActive,
                title: 'Very Active',
                subtitle: 'Hard exercise 6-7 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.veryActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.veryActive),
              ),
              const SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.extremelyActive,
                title: 'Extremely Active',
                subtitle: 'Very hard exercise, physical job',
                isSelected: _selectedActivityLevel == ActivityLevel.extremelyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.extremelyActive),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'This helps us calculate your nutritional needs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              suffixText: 'years',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 13 || age > 100) {
                return 'Please enter a valid age (13-100)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'cm',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your height';
              }
              final height = double.tryParse(value);
              if (height == null || height < 100 || height > 250) {
                return 'Please enter a valid height (100-250 cm)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 300) {
                return 'Please enter a valid weight (30-300 kg)';
              }
              return null;
            },
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0 && _selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a fitness goal'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_currentStep == 1 && _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your activity level'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_currentStep == 2) {
      _completeOnboarding();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }
}

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
          color: isSelected ? AppTheme.accentOrange.withOpacity(0.1) : AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : AppTheme.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentOrange : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
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
                      color: isSelected ? AppTheme.accentOrange : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.accentOrange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentOrange.withOpacity(0.1) : AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : AppTheme.borderColor,
            width: 2,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppTheme.accentOrange : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.accentOrange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}