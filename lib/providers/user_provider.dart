import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final String id;
  final String name;
  final String email;
  final int age;
  final double height; // in cm
  final double weight; // in kg
  final FitnessGoal goal;
  final ActivityLevel activityLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.height,
    required this.weight,
    required this.goal,
    required this.activityLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'height': height,
      'weight': weight,
      'goal': goal.index,
      'activityLevel': activityLevel.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      age: json['age'],
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      goal: FitnessGoal.values[json['goal']],
      activityLevel: ActivityLevel.values[json['activityLevel']],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? height,
    double? weight,
    FitnessGoal? goal,
    ActivityLevel? activityLevel,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final List<DateTime> activityDates;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.activityDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'activityDates': activityDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      lastActivityDate: DateTime.parse(json['lastActivityDate']),
      activityDates: (json['activityDates'] as List)
          .map((date) => DateTime.parse(date))
          .toList(),
    );
  }
}

class UserProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  UserProfile? _profile;
  StreakData? _streakData;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._prefs) {
    _loadUserData();
  }

  UserProfile? get profile => _profile;
  StreakData? get streakData => _streakData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompletedOnboarding => _prefs.getBool('onboarding_completed') ?? false;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    try {
      final String? profileJson = _prefs.getString('user_profile');
      if (profileJson != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileJson));
      }

      final String? streakJson = _prefs.getString('streak_data');
      if (streakJson != null) {
        _streakData = StreakData.fromJson(jsonDecode(streakJson));
      } else {
        _streakData = StreakData(
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
          activityDates: [],
        );
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user data');
    }
  }

  Future<void> _saveUserProfile() async {
    if (_profile != null) {
      try {
        final String profileJson = jsonEncode(_profile!.toJson());
        await _prefs.setString('user_profile', profileJson);
      } catch (e) {
        _setError('Failed to save user profile');
      }
    }
  }

  Future<void> _saveStreakData() async {
    if (_streakData != null) {
      try {
        final String streakJson = jsonEncode(_streakData!.toJson());
        await _prefs.setString('streak_data', streakJson);
      } catch (e) {
        _setError('Failed to save streak data');
      }
    }
  }

  Future<void> createProfile({
    required String name,
    required String email,
    required int age,
    required double height,
    required double weight,
    required FitnessGoal goal,
    required ActivityLevel activityLevel,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final userId = _prefs.getString('user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      _profile = UserProfile(
        id: userId,
        name: name,
        email: email,
        age: age,
        height: height,
        weight: weight,
        goal: goal,
        activityLevel: activityLevel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveUserProfile();
      await _prefs.setBool('onboarding_completed', true);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create profile');
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    int? age,
    double? height,
    double? weight,
    FitnessGoal? goal,
    ActivityLevel? activityLevel,
  }) async {
    if (_profile == null) return;

    _setLoading(true);
    _setError(null);

    try {
      _profile = _profile!.copyWith(
        name: name,
        email: email,
        age: age,
        height: height,
        weight: weight,
        goal: goal,
        activityLevel: activityLevel,
      );

      await _saveUserProfile();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile');
      _setLoading(false);
    }
  }

  Future<void> logActivity() async {
    if (_streakData == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastActivity = DateTime(
      _streakData!.lastActivityDate.year,
      _streakData!.lastActivityDate.month,
      _streakData!.lastActivityDate.day,
    );

    // Don't log if already logged today
    if (_streakData!.activityDates.any((date) {
      final activityDay = DateTime(date.year, date.month, date.day);
      return activityDay.isAtSameMomentAs(today);
    })) {
      return;
    }

    List<DateTime> newActivityDates = List.from(_streakData!.activityDates);
    newActivityDates.add(now);

    int newCurrentStreak;
    if (lastActivity.isAtSameMomentAs(yesterday)) {
      // Continue streak
      newCurrentStreak = _streakData!.currentStreak + 1;
    } else if (lastActivity.isAtSameMomentAs(today)) {
      // Already logged today
      newCurrentStreak = _streakData!.currentStreak;
    } else {
      // Streak broken, start new
      newCurrentStreak = 1;
    }

    final newLongestStreak = newCurrentStreak > _streakData!.longestStreak
        ? newCurrentStreak
        : _streakData!.longestStreak;

    _streakData = StreakData(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
      activityDates: newActivityDates,
    );

    await _saveStreakData();
    notifyListeners();
  }

  int getWeeklyActivityCount() {
    if (_streakData == null) return 0;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return _streakData!.activityDates.where((date) {
      return date.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).length;
  }

  int getMonthlyActivityCount() {
    if (_streakData == null) return 0;
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return _streakData!.activityDates.where((date) {
      return date.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).length;
  }

  String getGoalDescription() {
    if (_profile == null) return 'Set your fitness goal';
    
    switch (_profile!.goal) {
      case FitnessGoal.weightLoss:
        return 'Lose weight and get fit';
      case FitnessGoal.muscleGain:
        return 'Build muscle and strength';
      case FitnessGoal.maintenance:
        return 'Maintain current fitness';
      case FitnessGoal.endurance:
        return 'Improve endurance and stamina';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}