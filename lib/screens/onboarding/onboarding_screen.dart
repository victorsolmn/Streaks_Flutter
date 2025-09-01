import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../providers/supabase_user_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../main/main_screen.dart';
import '../auth/welcome_screen.dart';
import 'smartwatch_connection_screen.dart';

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
  final _targetWeightController = TextEditingController();

  FitnessGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final supabaseAuth = Provider.of<SupabaseAuthProvider>(context, listen: false);
      
      // Get name and email from Supabase auth or use defaults
      final currentUser = supabaseAuth.currentUser;
      final name = currentUser?.userMetadata?['name'] ?? 
                   currentUser?.email?.split('@')[0] ?? 'User';
      final email = currentUser?.email ?? 'user@example.com';

      // Create profile in local storage
      await userProvider.createProfile(
        name: name,
        email: email,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        targetWeight: double.parse(_targetWeightController.text),
        goal: _selectedGoal!,
        activityLevel: _selectedActivityLevel!,
      );

      if (mounted) {
        // Navigate to smartwatch connection screen instead of main screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SmartwatchConnectionScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Setup Profile (${_currentStep + 1}/3)'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final supabaseAuth = Provider.of<SupabaseAuthProvider>(context, listen: false);
              
              // Get current user info for creating a basic profile
              final currentUser = supabaseAuth.currentUser;
              final name = currentUser?.userMetadata?['name'] ?? 
                           currentUser?.email?.split('@')[0] ?? 'User';
              final email = currentUser?.email ?? 'user@example.com';

              // Create a basic profile with default values when skipping
              await userProvider.createProfile(
                name: name,
                email: email,
                age: 25, // Default age
                height: 170.0, // Default height in cm
                weight: 70.0, // Default weight in kg
                targetWeight: 65.0, // Default target weight
                goal: FitnessGoal.maintenance, // Default goal
                activityLevel: ActivityLevel.moderatelyActive, // Default activity level
              );

              // Navigate to smartwatch connection screen
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SmartwatchConnectionScreen()),
                );
              }
            },
            child: Text('Skip'),
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
                    value: (_currentStep + 1) / 3,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        _buildCurrentStep(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Navigation buttons - fixed at bottom
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            child: Text('Back'),
                          ),
                        ),
                        SizedBox(width: 16),
                      ],
                      
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: user.isLoading ? null : _handleNext,
                          child: user.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                )
                              : Text(_currentStep == 2 ? 'Complete' : 'Next'),
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
        SizedBox(height: 16),
        Text(
          'This helps us personalize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 48),
        
        Column(
          children: [
            _GoalOption(
                goal: FitnessGoal.weightLoss,
                title: 'Lose Weight',
                subtitle: 'Burn calories and get fit',
                icon: Icons.trending_down,
                isSelected: _selectedGoal == FitnessGoal.weightLoss,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.weightLoss),
              ),
              SizedBox(height: 16),
              
              _GoalOption(
                goal: FitnessGoal.muscleGain,
                title: 'Build Muscle',
                subtitle: 'Gain strength and mass',
                icon: Icons.fitness_center,
                isSelected: _selectedGoal == FitnessGoal.muscleGain,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.muscleGain),
              ),
              SizedBox(height: 16),
              
              _GoalOption(
                goal: FitnessGoal.maintenance,
                title: 'Stay Healthy',
                subtitle: 'Maintain current fitness',
                icon: Icons.favorite,
                isSelected: _selectedGoal == FitnessGoal.maintenance,
                onTap: () => setState(() => _selectedGoal = FitnessGoal.maintenance),
              ),
              SizedBox(height: 16),
              
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
        SizedBox(height: 16),
        Text(
          'This helps calculate your daily calorie needs',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        SizedBox(height: 48),
        
        Column(
          children: [
            _ActivityOption(
                level: ActivityLevel.sedentary,
                title: 'Sedentary',
                subtitle: 'Little to no exercise',
                isSelected: _selectedActivityLevel == ActivityLevel.sedentary,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.sedentary),
              ),
              SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.lightlyActive,
                title: 'Lightly Active',
                subtitle: 'Light exercise 1-3 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.lightlyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.lightlyActive),
              ),
              SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.moderatelyActive,
                title: 'Moderately Active',
                subtitle: 'Moderate exercise 3-5 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.moderatelyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.moderatelyActive),
              ),
              SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.veryActive,
                title: 'Very Active',
                subtitle: 'Hard exercise 6-7 days/week',
                isSelected: _selectedActivityLevel == ActivityLevel.veryActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.veryActive),
              ),
              SizedBox(height: 16),
              
              _ActivityOption(
                level: ActivityLevel.extremelyActive,
                title: 'Extremely Active',
                subtitle: 'Very hard exercise, physical job',
                isSelected: _selectedActivityLevel == ActivityLevel.extremelyActive,
                onTap: () => setState(() => _selectedActivityLevel = ActivityLevel.extremelyActive),
              ),
            ],
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
          SizedBox(height: 16),
          Text(
            'This helps us calculate your nutritional needs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 48),
          
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
          SizedBox(height: 24),
          
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
          SizedBox(height: 24),
          
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Current Weight',
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
          SizedBox(height: 24),
          
          TextFormField(
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target Weight',
              suffixText: 'kg',
              helperText: 'Your goal weight',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your target weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 300) {
                return 'Please enter a valid weight (30-300 kg)';
              }
              return null;
            },
          ),
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
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
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppTheme.primaryAccent : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 4),
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
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
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
          color: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Theme.of(context).dividerColor,
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
                      color: isSelected ? AppTheme.primaryAccent : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4),
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
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
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