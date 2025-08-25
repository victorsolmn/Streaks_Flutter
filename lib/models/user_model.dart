class UserProfile {
  final String name;
  final String email;
  final int? age;
  final double? height;
  final double? weight;
  final String? fitnessGoal;
  final String? activityLevel;
  final String? deviceName;
  final bool deviceConnected;
  final bool hasCompletedOnboarding;

  UserProfile({
    required this.name,
    required this.email,
    this.age,
    this.height,
    this.weight,
    this.fitnessGoal,
    this.activityLevel,
    this.deviceName,
    this.deviceConnected = false,
    this.hasCompletedOnboarding = false,
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
      fitnessGoal: json['fitnessGoal'] ?? json['goal'] ?? json['fitness_goal'],
      activityLevel: json['activityLevel'] ?? json['activity_level'] ?? 'Moderate',
      deviceName: json['deviceName'],
      deviceConnected: json['deviceConnected'] ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? json['has_completed_onboarding'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'height': height,
      'weight': weight,
      'fitnessGoal': fitnessGoal,
      'fitness_goal': fitnessGoal,
      'activityLevel': activityLevel,
      'activity_level': activityLevel,
      'deviceName': deviceName,
      'deviceConnected': deviceConnected,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'has_completed_onboarding': hasCompletedOnboarding,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? height,
    double? weight,
    String? fitnessGoal,
    String? activityLevel,
    String? deviceName,
    bool? deviceConnected,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      deviceName: deviceName ?? this.deviceName,
      deviceConnected: deviceConnected ?? this.deviceConnected,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}