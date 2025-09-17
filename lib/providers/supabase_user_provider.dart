import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class SupabaseUserProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _hasTriedLoading = false;
  User? _currentUser;

  SupabaseUserProvider() {
    _initializeAuthListener();
  }

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;
  bool get hasCompletedOnboarding => _userProfile?.hasCompletedOnboarding ?? false;
  bool get hasTriedLoading => _hasTriedLoading;
  User? get currentUser => _currentUser;

  void _initializeAuthListener() {
    // Set initial user
    _currentUser = _supabaseService.currentUser;

    // Listen to auth state changes
    _supabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _currentUser = session?.user;

      // Reset profile loading state when auth changes
      if (event == AuthChangeEvent.signedOut) {
        _userProfile = null;
        _hasTriedLoading = false;
        _error = null;
      } else if (event == AuthChangeEvent.signedIn && _currentUser != null && !_hasTriedLoading) {
        // Auto-load profile when user signs in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadUserProfile();
        });
      }

      notifyListeners();
    });
  }

  Future<void> loadUserProfile() async {
    // Get current user directly from the service to ensure we have the latest auth state
    final currentUser = _supabaseService.currentUser;
    _currentUser = currentUser;

    final userId = currentUser?.id;
    if (userId == null) {
      print('❌ ERROR: No user ID available for loading profile');
      print('🔍 DEBUG: currentUser is null, user not authenticated');
      return;
    }

    print('✅ Loading profile for user: $userId');

    // Prevent multiple simultaneous calls
    if (_isLoading) return;

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
    // Get current user directly from the service to ensure we have the latest auth state
    final currentUser = _supabaseService.currentUser;
    print('🔍 DEBUG: Checking user authentication...');
    print('🔍 DEBUG: currentUser from service: $currentUser');
    print('🔍 DEBUG: Supabase service auth: ${_supabaseService.isAuthenticated}');

    // Update our local reference
    _currentUser = currentUser;

    final userId = currentUser?.id;
    if (userId == null) {
      print('❌ ERROR: No user ID available for profile update');
      print('❌ DEBUG: currentUser is null, user not authenticated');
      return;
    }
    print('✅ User ID found: $userId');

    _isLoading = true;
    notifyListeners();

    try {
      print('\n' + '🔍' * 30);
      print('📱 APP PROFILE UPDATE INITIATED');
      print('🔍' * 30);
      print('Profile data from app:');
      print('  - name: ${profile.name}');
      print('  - email: ${profile.email}');
      print('  - age: ${profile.age}');
      print('  - height: ${profile.height}');
      print('  - weight: ${profile.weight}');
      print('  - activityLevel: ${profile.activityLevel}');
      print('  - fitnessGoal: ${profile.fitnessGoal}');
      print('  - hasCompletedOnboarding: ${profile.hasCompletedOnboarding}');
      print('🔍' * 30 + '\n');
      // Trigger hot reload

      // Progressive field testing to work with PostgREST cache issues
      // Try only the core fields that PostgREST definitely recognizes
      final coreProfileUpdates = <String, dynamic>{
        'name': profile.name,
        'email': profile.email,
      };

      // Add basic profile fields one by one
      if (profile.age != null) coreProfileUpdates['age'] = profile.age;
      if (profile.height != null) coreProfileUpdates['height'] = profile.height;
      if (profile.weight != null) coreProfileUpdates['weight'] = profile.weight;
      if (profile.targetWeight != null) coreProfileUpdates['target_weight'] = profile.targetWeight;
      if (profile.activityLevel != null) coreProfileUpdates['activity_level'] = profile.activityLevel;
      if (profile.fitnessGoal != null) coreProfileUpdates['fitness_goal'] = profile.fitnessGoal;
      if (profile.experienceLevel != null) coreProfileUpdates['experience_level'] = profile.experienceLevel;
      if (profile.workoutConsistency != null) coreProfileUpdates['workout_consistency'] = profile.workoutConsistency;
      // Add daily targets to core updates now that schema is fixed
      if (profile.dailyCaloriesTarget != null) coreProfileUpdates['daily_calories_target'] = profile.dailyCaloriesTarget;
      if (profile.dailyStepsTarget != null) coreProfileUpdates['daily_steps_target'] = profile.dailyStepsTarget;
      if (profile.dailySleepTarget != null) coreProfileUpdates['daily_sleep_target'] = profile.dailySleepTarget;
      if (profile.dailyWaterTarget != null) coreProfileUpdates['daily_water_target'] = profile.dailyWaterTarget;
      // Critical field for app routing - must be in core fields for reliable saving
      coreProfileUpdates['has_completed_onboarding'] = profile.hasCompletedOnboarding;

      await _supabaseService.updateUserProfile(
        userId: userId,
        updates: coreProfileUpdates,
      );

      _userProfile = profile;
      print('✅ Profile updated successfully with core data');
      print('📊 Saved to database: Age: ${profile.age}, Height: ${profile.height}, Weight: ${profile.weight}');
      print('🎯 Goals: ${profile.activityLevel}, ${profile.fitnessGoal}');

      // All fields now included in the core update above, no need for second phase
    } catch (e) {
      // Handle missing columns gracefully - try with absolute minimal data
      if (e.toString().contains('PGRST204')) {
        print('⚠️ Database schema incomplete - saving with minimal data only');

        try {
          // Try with absolute bare minimum - only name (which definitely exists)
          final bareMinimalUpdates = {
            'name': profile.name,
          };

          await _supabaseService.updateUserProfile(
            userId: userId,
            updates: bareMinimalUpdates,
          );

          _userProfile = profile;
          print('✅ Profile saved with bare minimum data (only name saved to database)');
          print('⚠️ Your onboarding data stored locally only: Age: ${profile.age}, Height: ${profile.height}, Weight: ${profile.weight}');
          print('⚠️ Activity: ${profile.activityLevel}, Goal: ${profile.fitnessGoal}');
          print('📋 Database migration required to persist all profile data');
        } catch (retryError) {
          // If even name fails, just save locally
          _userProfile = profile;
          print('⚠️ Database save failed - profile stored locally only');
          print('💾 Your onboarding data: Age: ${profile.age}, Height: ${profile.height}, Weight: ${profile.weight}');
          print('💾 Activity: ${profile.activityLevel}, Goal: ${profile.fitnessGoal}');
          print('🔧 Database needs immediate migration to save any profile data');
          _error = null; // Clear error since we saved locally
        }
      } else {
        _error = e.toString();
        print('❌ Error updating profile: $e');
      }
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

  // Force reload profile from database (ignoring cache)
  Future<void> reloadUserProfile() async {
    _hasTriedLoading = false; // Reset to allow reload
    await loadUserProfile();
  }

  void clearUserData() {
    _userProfile = null;
    _error = null;
    _hasTriedLoading = false; // Reset the loading flag
    notifyListeners();
  }
}