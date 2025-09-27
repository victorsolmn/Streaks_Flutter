enum FitnessGoal {
  weightLoss,
  muscleGain,
  maintenance,
  endurance,
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

class UserProfile {
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final double? targetWeight;
  final String? fitnessGoal;
  final String? activityLevel;
  final String? experienceLevel;
  final String? photoUrl;
  final String? workoutConsistency;
  final String? deviceName;
  final bool deviceConnected;
  final bool hasCompletedOnboarding;
  final bool hasSeenFitnessGoalSummary;
  
  // Fitness targets
  final int? dailyCaloriesTarget;
  final int? dailyActiveCaloriesTarget;
  final int? dailyStepsTarget;
  final double? dailySleepTarget;
  final double? dailyWaterTarget;
  final double? bmiValue;
  final String? bmiCategoryValue;

  UserProfile({
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.targetWeight,
    this.fitnessGoal,
    this.activityLevel,
    this.experienceLevel,
    this.photoUrl,
    this.workoutConsistency,
    this.deviceName,
    this.deviceConnected = false,
    this.hasCompletedOnboarding = false,
    this.hasSeenFitnessGoalSummary = false,
    this.dailyCaloriesTarget,
    this.dailyActiveCaloriesTarget,
    this.dailyStepsTarget,
    this.dailySleepTarget,
    this.dailyWaterTarget,
    this.bmiValue,
    this.bmiCategoryValue,
  });

  double get bmi {
    if (height == null || weight == null || height! <= 0 || weight! <= 0) return 0;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      email: '',
      age: null,
      height: null,
      weight: null,
      targetWeight: null,
      fitnessGoal: 'Weight Loss',
      activityLevel: 'Moderate',
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      targetWeight: json['targetWeight']?.toDouble() ?? json['target_weight']?.toDouble(),
      fitnessGoal: json['fitnessGoal'] ?? json['goal'] ?? json['fitness_goal'],
      activityLevel: json['activityLevel'] ?? json['activity_level'] ?? 'Moderate',
      experienceLevel: json['experienceLevel'] ?? json['experience_level'],
      workoutConsistency: json['workoutConsistency'] ?? json['workout_consistency'],
      deviceName: json['deviceName'],
      deviceConnected: json['deviceConnected'] ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? json['has_completed_onboarding'] ?? false,
      hasSeenFitnessGoalSummary: json['hasSeenFitnessGoalSummary'] ?? json['has_seen_fitness_goal_summary'] ?? false,
      dailyCaloriesTarget: json['dailyCaloriesTarget'] ?? json['daily_calories_target'],
      dailyActiveCaloriesTarget: json['dailyActiveCaloriesTarget'] ?? json['daily_active_calories_target'],
      dailyStepsTarget: json['dailyStepsTarget'] ?? json['daily_steps_target'],
      dailySleepTarget: json['dailySleepTarget']?.toDouble() ?? json['daily_sleep_target']?.toDouble(),
      dailyWaterTarget: json['dailyWaterTarget']?.toDouble() ?? json['daily_water_target']?.toDouble(),
      bmiValue: json['bmiValue']?.toDouble() ?? json['bmi_value']?.toDouble(),
      bmiCategoryValue: json['bmiCategoryValue'] ?? json['bmi_category_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'target_weight': targetWeight,
      'fitnessGoal': fitnessGoal,
      'fitness_goal': fitnessGoal,
      'activityLevel': activityLevel,
      'activity_level': activityLevel,
      'experienceLevel': experienceLevel,
      'experience_level': experienceLevel,
      'workoutConsistency': workoutConsistency,
      'workout_consistency': workoutConsistency,
      'deviceName': deviceName,
      'deviceConnected': deviceConnected,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'has_completed_onboarding': hasCompletedOnboarding,
      'hasSeenFitnessGoalSummary': hasSeenFitnessGoalSummary,
      'has_seen_fitness_goal_summary': hasSeenFitnessGoalSummary,
      'dailyCaloriesTarget': dailyCaloriesTarget,
      'daily_calories_target': dailyCaloriesTarget,
      'dailyActiveCaloriesTarget': dailyActiveCaloriesTarget,
      'daily_active_calories_target': dailyActiveCaloriesTarget,
      'dailyStepsTarget': dailyStepsTarget,
      'daily_steps_target': dailyStepsTarget,
      'dailySleepTarget': dailySleepTarget,
      'daily_sleep_target': dailySleepTarget,
      'dailyWaterTarget': dailyWaterTarget,
      'daily_water_target': dailyWaterTarget,
      'bmiValue': bmiValue,
      'bmi_value': bmiValue,
      'bmiCategoryValue': bmiCategoryValue,
      'bmi_category_value': bmiCategoryValue,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    String? fitnessGoal,
    String? activityLevel,
    String? experienceLevel,
    String? photoUrl,
    String? workoutConsistency,
    String? deviceName,
    bool? deviceConnected,
    bool? hasCompletedOnboarding,
    bool? hasSeenFitnessGoalSummary,
    int? dailyCaloriesTarget,
    int? dailyActiveCaloriesTarget,
    int? dailyStepsTarget,
    double? dailySleepTarget,
    double? dailyWaterTarget,
    double? bmiValue,
    String? bmiCategoryValue,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      photoUrl: photoUrl ?? this.photoUrl,
      workoutConsistency: workoutConsistency ?? this.workoutConsistency,
      deviceName: deviceName ?? this.deviceName,
      deviceConnected: deviceConnected ?? this.deviceConnected,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasSeenFitnessGoalSummary: hasSeenFitnessGoalSummary ?? this.hasSeenFitnessGoalSummary,
      dailyCaloriesTarget: dailyCaloriesTarget ?? this.dailyCaloriesTarget,
      dailyActiveCaloriesTarget: dailyActiveCaloriesTarget ?? this.dailyActiveCaloriesTarget,
      dailyStepsTarget: dailyStepsTarget ?? this.dailyStepsTarget,
      dailySleepTarget: dailySleepTarget ?? this.dailySleepTarget,
      dailyWaterTarget: dailyWaterTarget ?? this.dailyWaterTarget,
      bmiValue: bmiValue ?? this.bmiValue,
      bmiCategoryValue: bmiCategoryValue ?? this.bmiCategoryValue,
    );
  }
}