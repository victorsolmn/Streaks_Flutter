class UserProfile {
  final String name;
  final int age;
  final double height;
  final double weight;
  final String goal;
  final String activityLevel;
  final String? deviceName;
  final bool deviceConnected;

  UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.goal,
    required this.activityLevel,
    this.deviceName,
    this.deviceConnected = false,
  });

  double get bmi {
    if (height <= 0 || weight <= 0) return 0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
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
      age: 0,
      height: 0,
      weight: 0,
      goal: 'Weight Loss',
      activityLevel: 'Moderate',
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      goal: json['goal'] ?? 'Weight Loss',
      activityLevel: json['activityLevel'] ?? 'Moderate',
      deviceName: json['deviceName'],
      deviceConnected: json['deviceConnected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'goal': goal,
      'activityLevel': activityLevel,
      'deviceName': deviceName,
      'deviceConnected': deviceConnected,
    };
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
    String? goal,
    String? activityLevel,
    String? deviceName,
    bool? deviceConnected,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      deviceName: deviceName ?? this.deviceName,
      deviceConnected: deviceConnected ?? this.deviceConnected,
    );
  }
}