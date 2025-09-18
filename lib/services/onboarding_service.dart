import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/supabase_enums.dart';

/// Onboarding Service - Handles all Supabase interactions for onboarding
///
/// This service ensures that onboarding data is properly validated
/// and saved to Supabase according to the database schema constraints
class OnboardingService {
  final SupabaseClient _client;

  OnboardingService() : _client = Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get or create user profile
  Future<ProfileModel?> getOrCreateProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: No authenticated user');
        return null;
      }

      // Try to get existing profile
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        print('✅ OnboardingService: Profile found for user ${user.id}');
        return ProfileModel.fromJson(response);
      }

      // Create new profile with minimal data
      print('📝 OnboardingService: Creating new profile for user ${user.id}');
      final newProfile = ProfileModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? 'New User',
        email: user.email ?? '',
        hasCompletedOnboarding: false,
      );

      await _client.from('profiles').insert(newProfile.toJson());

      // Fetch the created profile
      final createdProfile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ProfileModel.fromJson(createdProfile);
    } catch (e) {
      print('❌ OnboardingService: Error getting/creating profile: $e');
      return null;
    }
  }

  /// Save onboarding data step by step
  Future<bool> saveOnboardingStep1({
    required String name,
    required int age,
    required double height,
    required double weight,
    double? targetWeight,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: Cannot save Step 1 - no authenticated user');
        return false;
      }

      // Validate constraints
      if (!_validateAge(age) || !_validateHeight(height) ||
          !_validateWeight(weight) || (targetWeight != null && !_validateWeight(targetWeight))) {
        print('❌ OnboardingService: Step 1 validation failed');
        return false;
      }

      // Calculate BMI
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      final bmiCategory = _getBMICategory(bmi);

      print('📊 OnboardingService: Saving Step 1 data for user ${user.id}');

      final updateData = {
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
        'target_weight': targetWeight ?? weight,
        'bmi_value': bmi,
        'bmi_category_value': bmiCategory,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      print('✅ OnboardingService: Step 1 saved successfully');
      return true;
    } catch (e) {
      print('❌ OnboardingService: Error saving Step 1: $e');
      return false;
    }
  }

  /// Save fitness goal (Step 2)
  Future<bool> saveOnboardingStep2({
    required String fitnessGoal,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: Cannot save Step 2 - no authenticated user');
        return false;
      }

      // Validate fitness goal
      if (!SupabaseEnums.fitnessGoals.contains(fitnessGoal)) {
        print('❌ OnboardingService: Invalid fitness goal: $fitnessGoal');
        return false;
      }

      print('🎯 OnboardingService: Saving Step 2 data for user ${user.id}');

      await _client
          .from('profiles')
          .update({
            'fitness_goal': fitnessGoal,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      print('✅ OnboardingService: Step 2 saved successfully');
      return true;
    } catch (e) {
      print('❌ OnboardingService: Error saving Step 2: $e');
      return false;
    }
  }

  /// Save activity and experience (Step 3)
  Future<bool> saveOnboardingStep3({
    required String activityLevel,
    required String experienceLevel,
    required String workoutConsistency,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: Cannot save Step 3 - no authenticated user');
        return false;
      }

      // Validate inputs
      if (!SupabaseEnums.activityLevels.contains(activityLevel)) {
        print('❌ OnboardingService: Invalid activity level: $activityLevel');
        return false;
      }
      if (!SupabaseEnums.experienceLevels.contains(experienceLevel)) {
        print('❌ OnboardingService: Invalid experience level: $experienceLevel');
        return false;
      }

      print('💪 OnboardingService: Saving Step 3 data for user ${user.id}');

      await _client
          .from('profiles')
          .update({
            'activity_level': activityLevel,
            'experience_level': experienceLevel,
            'workout_consistency': workoutConsistency,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      print('✅ OnboardingService: Step 3 saved successfully');
      return true;
    } catch (e) {
      print('❌ OnboardingService: Error saving Step 3: $e');
      return false;
    }
  }

  /// Complete onboarding and calculate targets
  Future<bool> completeOnboarding() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: Cannot complete onboarding - no authenticated user');
        return false;
      }

      // Get current profile data
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = ProfileModel.fromJson(profileResponse);

      // Ensure we have all required data
      if (!profile.hasMinimumOnboardingData()) {
        print('❌ OnboardingService: Incomplete onboarding data');
        return false;
      }

      // Calculate daily targets
      final targets = _calculateDailyTargets(profile);

      print('🎉 OnboardingService: Completing onboarding for user ${user.id}');

      await _client
          .from('profiles')
          .update({
            'daily_calories_target': targets['calories'],
            'daily_steps_target': targets['steps'],
            'daily_sleep_target': targets['sleep'],
            'daily_water_target': targets['water'],
            'has_completed_onboarding': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      print('✅ OnboardingService: Onboarding completed successfully!');
      print('📊 Saved targets: $targets');
      return true;
    } catch (e) {
      print('❌ OnboardingService: Error completing onboarding: $e');
      return false;
    }
  }

  /// Save complete onboarding data at once
  Future<bool> saveCompleteOnboardingData({
    required String name,
    required int age,
    required double height,
    required double weight,
    double? targetWeight,
    required String fitnessGoal,
    required String activityLevel,
    required String experienceLevel,
    required String workoutConsistency,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ OnboardingService: Cannot save onboarding - no authenticated user');
        return false;
      }

      print('📝 OnboardingService: Saving complete onboarding data for user ${user.id}');

      // Validate all inputs
      if (!_validateAllInputs(
        age: age,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        fitnessGoal: fitnessGoal,
        activityLevel: activityLevel,
        experienceLevel: experienceLevel,
      )) {
        return false;
      }

      // Calculate BMI
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      final bmiCategory = _getBMICategory(bmi);

      // Calculate daily targets
      final bmr = _calculateBMR(age, height, weight);
      final tdee = (bmr * SupabaseEnums.getActivityMultiplier(activityLevel)).round();
      final calorieTarget = tdee + SupabaseEnums.getCalorieAdjustment(fitnessGoal);

      final profileData = {
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
        'target_weight': targetWeight ?? weight,
        'fitness_goal': fitnessGoal,
        'activity_level': activityLevel,
        'experience_level': experienceLevel,
        'workout_consistency': workoutConsistency,
        'bmi_value': bmi,
        'bmi_category_value': bmiCategory,
        'daily_calories_target': calorieTarget.clamp(
          SupabaseEnums.dailyCaloriesMin,
          SupabaseEnums.dailyCaloriesMax,
        ),
        'daily_steps_target': _getStepsTarget(activityLevel),
        'daily_sleep_target': 8.0,
        'daily_water_target': 3.0,
        'has_completed_onboarding': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('profiles')
          .update(profileData)
          .eq('id', user.id);

      print('✅ OnboardingService: Onboarding data saved successfully!');
      print('📊 Profile data: ${profileData.toString()}');
      return true;
    } catch (e) {
      print('❌ OnboardingService: Error saving onboarding data: $e');
      print('Error details: $e');
      return false;
    }
  }

  // Validation methods
  bool _validateAge(int age) => age >= SupabaseEnums.ageMin && age <= SupabaseEnums.ageMax;
  bool _validateHeight(double height) => height >= SupabaseEnums.heightMin && height <= SupabaseEnums.heightMax;
  bool _validateWeight(double weight) => weight >= SupabaseEnums.weightMin && weight <= SupabaseEnums.weightMax;

  bool _validateAllInputs({
    required int age,
    required double height,
    required double weight,
    double? targetWeight,
    required String fitnessGoal,
    required String activityLevel,
    required String experienceLevel,
  }) {
    if (!_validateAge(age)) {
      print('❌ Invalid age: $age (must be ${SupabaseEnums.ageMin}-${SupabaseEnums.ageMax})');
      return false;
    }
    if (!_validateHeight(height)) {
      print('❌ Invalid height: $height (must be ${SupabaseEnums.heightMin}-${SupabaseEnums.heightMax} cm)');
      return false;
    }
    if (!_validateWeight(weight)) {
      print('❌ Invalid weight: $weight (must be ${SupabaseEnums.weightMin}-${SupabaseEnums.weightMax} kg)');
      return false;
    }
    if (targetWeight != null && !_validateWeight(targetWeight)) {
      print('❌ Invalid target weight: $targetWeight');
      return false;
    }
    if (!SupabaseEnums.fitnessGoals.contains(fitnessGoal)) {
      print('❌ Invalid fitness goal: $fitnessGoal');
      return false;
    }
    if (!SupabaseEnums.activityLevels.contains(activityLevel)) {
      print('❌ Invalid activity level: $activityLevel');
      return false;
    }
    if (!SupabaseEnums.experienceLevels.contains(experienceLevel)) {
      print('❌ Invalid experience level: $experienceLevel');
      return false;
    }
    return true;
  }

  // Helper methods
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  double _calculateBMR(int age, double height, double weight) {
    // Using Mifflin-St Jeor Equation
    // Men: BMR = 10W + 6.25H - 5A + 5
    // Women: BMR = 10W + 6.25H - 5A - 161
    // Using male formula as default (can be enhanced with gender field)
    return (10 * weight) + (6.25 * height) - (5 * age) + 5;
  }

  int _getStepsTarget(String activityLevel) {
    switch (activityLevel) {
      case 'Sedentary':
        return 5000;
      case 'Lightly Active':
        return 7500;
      case 'Moderately Active':
        return 10000;
      case 'Very Active':
        return 12500;
      case 'Extra Active':
        return 15000;
      default:
        return 10000;
    }
  }

  Map<String, int> _calculateDailyTargets(ProfileModel profile) {
    final bmr = _calculateBMR(
      profile.age!,
      profile.height!,
      profile.weight!,
    );

    final tdee = (bmr * SupabaseEnums.getActivityMultiplier(profile.activityLevel!)).round();
    final calorieTarget = tdee + SupabaseEnums.getCalorieAdjustment(profile.fitnessGoal!);

    return {
      'calories': calorieTarget.clamp(SupabaseEnums.dailyCaloriesMin, SupabaseEnums.dailyCaloriesMax),
      'steps': _getStepsTarget(profile.activityLevel!),
      'sleep': 8, // 8 hours default
      'water': 3, // 3 liters default
    };
  }
}