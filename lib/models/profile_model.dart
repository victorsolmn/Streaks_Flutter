/// Profile Model - Exactly matches Supabase schema
///
/// This model is a 1:1 mapping with the public.profiles table

class ProfileModel {
  // Required fields (NOT NULL in database)
  final String id; // UUID from auth.users
  final String name; // Has default 'New User' in DB
  final String email;
  final bool hasCompletedOnboarding; // Default false
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional fields (NULL allowed in database)
  final int? age; // 13-120
  final String? gender; // Male, Female, Other, Prefer not to say
  final double? height; // 50-300 cm
  final double? weight; // 20-500 kg
  final String? activityLevel;
  final String? photoUrl; // Profile photo URL from Supabase storage
  final String? fitnessGoal;
  final String? experienceLevel;
  final double? targetWeight; // 20-500 kg
  final String? workoutConsistency;
  final int? dailyCaloriesTarget; // 500-10000 (total calories = BMR + active)
  final int? dailyActiveCaloriesTarget; // 500-4000 (active calories only)
  final int? dailyStepsTarget; // 0-100000
  final double? dailySleepTarget; // 0-24 hours
  final double? dailyWaterTarget; // 0-20 liters
  final bool? hasSeenFitnessGoalSummary; // Default false
  final String? deviceName;
  final bool? deviceConnected; // Default false
  final double? bmiValue;
  final String? bmiCategoryValue;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.hasCompletedOnboarding = false,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.photoUrl,
    this.fitnessGoal,
    this.experienceLevel,
    this.targetWeight,
    this.workoutConsistency,
    this.dailyCaloriesTarget,
    this.dailyActiveCaloriesTarget,
    this.dailyStepsTarget,
    this.dailySleepTarget,
    this.dailyWaterTarget,
    this.hasSeenFitnessGoalSummary,
    this.deviceName,
    this.deviceConnected,
    this.bmiValue,
    this.bmiCategoryValue,
  });

  /// Create from Supabase JSON response
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] ?? 'New User',
      email: json['email'] as String,
      hasCompletedOnboarding: json['has_completed_onboarding'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      activityLevel: json['activity_level'] as String?,
      photoUrl: json['photo_url'] as String?,
      fitnessGoal: json['fitness_goal'] as String?,
      experienceLevel: json['experience_level'] as String?,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      workoutConsistency: json['workout_consistency'] as String?,
      dailyCaloriesTarget: json['daily_calories_target'] as int?,
      dailyActiveCaloriesTarget: json['daily_active_calories_target'] as int?,
      dailyStepsTarget: json['daily_steps_target'] as int?,
      dailySleepTarget: json['daily_sleep_target'] != null
          ? (json['daily_sleep_target'] as num).toDouble()
          : null,
      dailyWaterTarget: json['daily_water_target'] != null
          ? (json['daily_water_target'] as num).toDouble()
          : null,
      hasSeenFitnessGoalSummary: json['has_seen_fitness_goal_summary'] as bool?,
      deviceName: json['device_name'] as String?,
      deviceConnected: json['device_connected'] as bool?,
      bmiValue: json['bmi_value'] != null
          ? (json['bmi_value'] as num).toDouble()
          : null,
      bmiCategoryValue: json['bmi_category_value'] as String?,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'has_completed_onboarding': hasCompletedOnboarding,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (workoutConsistency != null) 'workout_consistency': workoutConsistency,
      if (dailyCaloriesTarget != null) 'daily_calories_target': dailyCaloriesTarget,
      if (dailyActiveCaloriesTarget != null) 'daily_active_calories_target': dailyActiveCaloriesTarget,
      if (dailyStepsTarget != null) 'daily_steps_target': dailyStepsTarget,
      if (dailySleepTarget != null) 'daily_sleep_target': dailySleepTarget,
      if (dailyWaterTarget != null) 'daily_water_target': dailyWaterTarget,
      if (hasSeenFitnessGoalSummary != null) 'has_seen_fitness_goal_summary': hasSeenFitnessGoalSummary,
      if (deviceName != null) 'device_name': deviceName,
      if (deviceConnected != null) 'device_connected': deviceConnected,
      if (bmiValue != null) 'bmi_value': bmiValue,
      if (bmiCategoryValue != null) 'bmi_category_value': bmiCategoryValue,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? hasCompletedOnboarding,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? photoUrl,
    String? fitnessGoal,
    String? experienceLevel,
    double? targetWeight,
    String? workoutConsistency,
    int? dailyCaloriesTarget,
    int? dailyActiveCaloriesTarget,
    int? dailyStepsTarget,
    double? dailySleepTarget,
    double? dailyWaterTarget,
    bool? hasSeenFitnessGoalSummary,
    String? deviceName,
    bool? deviceConnected,
    double? bmiValue,
    String? bmiCategoryValue,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      targetWeight: targetWeight ?? this.targetWeight,
      workoutConsistency: workoutConsistency ?? this.workoutConsistency,
      dailyCaloriesTarget: dailyCaloriesTarget ?? this.dailyCaloriesTarget,
      dailyActiveCaloriesTarget: dailyActiveCaloriesTarget ?? this.dailyActiveCaloriesTarget,
      dailyStepsTarget: dailyStepsTarget ?? this.dailyStepsTarget,
      dailySleepTarget: dailySleepTarget ?? this.dailySleepTarget,
      dailyWaterTarget: dailyWaterTarget ?? this.dailyWaterTarget,
      hasSeenFitnessGoalSummary: hasSeenFitnessGoalSummary ?? this.hasSeenFitnessGoalSummary,
      deviceName: deviceName ?? this.deviceName,
      deviceConnected: deviceConnected ?? this.deviceConnected,
      bmiValue: bmiValue ?? this.bmiValue,
      bmiCategoryValue: bmiCategoryValue ?? this.bmiCategoryValue,
    );
  }

  /// Calculate BMI from height and weight
  double? calculateBMI() {
    if (height != null && weight != null && height! > 0) {
      // BMI = weight(kg) / (height(m))^2
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  /// Get BMI category based on BMI value
  String? getBMICategory() {
    final bmi = bmiValue ?? calculateBMI();
    if (bmi == null) return null;

    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Check if profile has minimum required onboarding data
  bool hasMinimumOnboardingData() {
    return age != null &&
           height != null &&
           weight != null &&
           activityLevel != null &&
           fitnessGoal != null;
  }

  /// Check if profile has complete onboarding data
  bool hasCompleteOnboardingData() {
    return hasMinimumOnboardingData() &&
           experienceLevel != null &&
           workoutConsistency != null &&
           dailyCaloriesTarget != null &&
           dailyStepsTarget != null;
  }

  /// Check if profile has required data for BMR calculation
  /// BMR calculation requires: age, gender, height, weight
  bool hasBMRCalculationData() {
    return age != null &&
           age! > 0 &&
           age! <= 120 &&
           gender != null &&
           gender!.isNotEmpty &&
           height != null &&
           height! > 0 &&
           height! <= 300 &&
           weight != null &&
           weight! > 0 &&
           weight! <= 500;
  }

  /// Get validated gender for BMR calculation
  /// Returns null if gender is invalid or missing
  String? getValidatedGender() {
    if (gender == null || gender!.trim().isEmpty) {
      return null;
    }

    final normalizedGender = gender!.toLowerCase().trim();

    // Check for valid gender values
    if (normalizedGender.contains('male') && !normalizedGender.contains('female')) {
      return 'male';
    } else if (normalizedGender.contains('female')) {
      return 'female';
    } else if (normalizedGender == 'other' || normalizedGender.contains('other')) {
      return 'other'; // Treat as female for BMR calculation (conservative approach)
    }

    return null; // Invalid gender
  }

  /// Get BMR calculation readiness status
  Map<String, dynamic> getBMRCalculationStatus() {
    final hasData = hasBMRCalculationData();
    final validGender = getValidatedGender();

    return {
      'isReady': hasData,
      'hasAge': age != null && age! > 0 && age! <= 120,
      'hasGender': validGender != null,
      'hasHeight': height != null && height! > 0 && height! <= 300,
      'hasWeight': weight != null && weight! > 0 && weight! <= 500,
      'validatedGender': validGender,
      'missingFields': _getMissingBMRFields(),
    };
  }

  /// Get list of missing fields for BMR calculation
  List<String> _getMissingBMRFields() {
    final missing = <String>[];

    if (age == null || age! <= 0 || age! > 120) {
      missing.add('age');
    }
    if (getValidatedGender() == null) {
      missing.add('gender');
    }
    if (height == null || height! <= 0 || height! > 300) {
      missing.add('height');
    }
    if (weight == null || weight! <= 0 || weight! > 500) {
      missing.add('weight');
    }

    return missing;
  }
}