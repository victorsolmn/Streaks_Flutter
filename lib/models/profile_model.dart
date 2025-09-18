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
  final double? height; // 50-300 cm
  final double? weight; // 20-500 kg
  final String? activityLevel;
  final String? fitnessGoal;
  final String? experienceLevel;
  final double? targetWeight; // 20-500 kg
  final String? workoutConsistency;
  final int? dailyCaloriesTarget; // 500-10000
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
    this.height,
    this.weight,
    this.activityLevel,
    this.fitnessGoal,
    this.experienceLevel,
    this.targetWeight,
    this.workoutConsistency,
    this.dailyCaloriesTarget,
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
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      activityLevel: json['activity_level'] as String?,
      fitnessGoal: json['fitness_goal'] as String?,
      experienceLevel: json['experience_level'] as String?,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      workoutConsistency: json['workout_consistency'] as String?,
      dailyCaloriesTarget: json['daily_calories_target'] as int?,
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
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (workoutConsistency != null) 'workout_consistency': workoutConsistency,
      if (dailyCaloriesTarget != null) 'daily_calories_target': dailyCaloriesTarget,
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
    double? height,
    double? weight,
    String? activityLevel,
    String? fitnessGoal,
    String? experienceLevel,
    double? targetWeight,
    String? workoutConsistency,
    int? dailyCaloriesTarget,
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
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      targetWeight: targetWeight ?? this.targetWeight,
      workoutConsistency: workoutConsistency ?? this.workoutConsistency,
      dailyCaloriesTarget: dailyCaloriesTarget ?? this.dailyCaloriesTarget,
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
}