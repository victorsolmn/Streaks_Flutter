import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class SupabaseUserProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _hasTriedLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;
  bool get hasCompletedOnboarding => _userProfile?.hasCompletedOnboarding ?? false;
  bool get hasTriedLoading => _hasTriedLoading;

  Future<void> loadUserProfile() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // Prevent multiple simultaneous calls
    if (_isLoading || _hasTriedLoading) return;

    _isLoading = true;
    _hasTriedLoading = true;
    notifyListeners();

    try {
      final profileData = await _supabaseService.getUserProfile(userId);
      
      if (profileData != null) {
        _userProfile = UserProfile(
          name: profileData['name'] ?? '',
          email: profileData['email'] ?? '',
          age: profileData['age'],
          height: profileData['height']?.toDouble(),
          weight: profileData['weight']?.toDouble(),
          targetWeight: profileData['target_weight']?.toDouble(),
          activityLevel: profileData['activity_level'],
          fitnessGoal: profileData['fitness_goal'],
          experienceLevel: profileData['experience_level'],
          workoutConsistency: profileData['workout_consistency'],
          hasCompletedOnboarding: profileData['has_completed_onboarding'] ?? false,
          hasSeenFitnessGoalSummary: profileData['has_seen_fitness_goal_summary'] ?? false,
          dailyCaloriesTarget: profileData['daily_calories_target'],
          dailyStepsTarget: profileData['daily_steps_target'], 
          dailySleepTarget: profileData['daily_sleep_target']?.toDouble(),
          dailyWaterTarget: profileData['daily_water_target']?.toDouble(),
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.updateUserProfile(
        userId: userId,
        updates: {
          'name': profile.name,
          'age': profile.age,
          'height': profile.height,
          'weight': profile.weight,
          'target_weight': profile.targetWeight,
          'activity_level': profile.activityLevel,
          'fitness_goal': profile.fitnessGoal,
          'experience_level': profile.experienceLevel,
          'workout_consistency': profile.workoutConsistency,
          'has_completed_onboarding': profile.hasCompletedOnboarding,
          'has_seen_fitness_goal_summary': profile.hasSeenFitnessGoalSummary,
          'daily_calories_target': profile.dailyCaloriesTarget,
          'daily_steps_target': profile.dailyStepsTarget,
          'daily_sleep_target': profile.dailySleepTarget,
          'daily_water_target': profile.dailyWaterTarget,
        },
      );

      _userProfile = profile;
    } catch (e) {
      _error = e.toString();
      print('Error updating profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setUserGoal(String goal) async {
    if (_userProfile == null) return;

    final updatedProfile = UserProfile(
      name: _userProfile!.name,
      email: _userProfile!.email,
      age: _userProfile!.age,
      height: _userProfile!.height,
      weight: _userProfile!.weight,
      activityLevel: _userProfile!.activityLevel,
      fitnessGoal: goal,
    );

    await updateProfile(updatedProfile);
  }

  Future<void> setActivityLevel(String level) async {
    if (_userProfile == null) return;

    final updatedProfile = UserProfile(
      name: _userProfile!.name,
      email: _userProfile!.email,
      age: _userProfile!.age,
      height: _userProfile!.height,
      weight: _userProfile!.weight,
      activityLevel: level,
      fitnessGoal: _userProfile!.fitnessGoal,
    );

    await updateProfile(updatedProfile);
  }

  Future<void> setPersonalInfo({
    required int age,
    required double height,
    required double weight,
  }) async {
    if (_userProfile == null) return;

    final updatedProfile = UserProfile(
      name: _userProfile!.name,
      email: _userProfile!.email,
      age: age,
      height: height,
      weight: weight,
      activityLevel: _userProfile!.activityLevel,
      fitnessGoal: _userProfile!.fitnessGoal,
    );

    await updateProfile(updatedProfile);
  }

  double? get bmi {
    if (_userProfile?.height == null || _userProfile?.weight == null) {
      return null;
    }
    final heightInMeters = _userProfile!.height! / 100;
    return _userProfile!.weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  int get dailyCalorieGoal {
    if (_userProfile == null || 
        _userProfile!.age == null || 
        _userProfile!.height == null || 
        _userProfile!.weight == null) {
      return 2000; // Default
    }

    // Mifflin-St Jeor Equation
    double bmr;
    bmr = (10 * _userProfile!.weight!) + 
          (6.25 * _userProfile!.height!) - 
          (5 * _userProfile!.age!) + 5; // Assuming male for now

    // Activity factor
    double activityFactor = 1.2; // Sedentary default
    switch (_userProfile!.activityLevel) {
      case 'Lightly Active':
        activityFactor = 1.375;
        break;
      case 'Moderately Active':
        activityFactor = 1.55;
        break;
      case 'Very Active':
        activityFactor = 1.725;
        break;
      case 'Extra Active':
        activityFactor = 1.9;
        break;
    }

    double tdee = bmr * activityFactor;

    // Adjust based on goal
    switch (_userProfile!.fitnessGoal) {
      case 'Lose Weight':
        tdee -= 500; // 500 calorie deficit
        break;
      case 'Gain Muscle':
        tdee += 300; // 300 calorie surplus
        break;
    }

    return tdee.round();
  }

  int get dailyProteinGoal {
    if (_userProfile?.weight == null) return 50; // Default
    
    // 1.6-2.2g per kg for active individuals
    double proteinPerKg = 1.8;
    if (_userProfile!.fitnessGoal == 'Gain Muscle') {
      proteinPerKg = 2.2;
    }
    
    return (_userProfile!.weight! * proteinPerKg).round();
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    if (_userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      hasCompletedOnboarding: true,
    );

    await updateProfile(updatedProfile);
  }

  void clearUserData() {
    _userProfile = null;
    _error = null;
    _hasTriedLoading = false; // Reset the loading flag
    notifyListeners();
  }
}