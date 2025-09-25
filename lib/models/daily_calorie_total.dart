import 'package:flutter/foundation.dart';

/// Represents aggregated calorie data for a single day (12am to 12am)
class DailyCalorieTotal {
  final String? id;
  final String userId;
  final DateTime date;

  // Daily totals
  final double totalBmrCalories;
  final double totalActiveCalories;
  final double totalExerciseCalories;
  final double totalCalories;

  // Activity summary
  final int totalSteps;
  final double totalDistanceMeters;
  final int totalFloors;
  final int activeMinutes;
  final int sedentaryMinutes;

  // Heart rate summary
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;
  final int? restingHeartRate;

  // Exercise summary
  final int exerciseMinutes;
  final List<String> exerciseTypes;

  // Session counts
  final int sessionCount;
  final int exerciseSessionCount;
  final int appOpenCount;

  // Timing
  final String? firstActivityTime;
  final String? lastActivityTime;
  final int? mostActiveHour;

  // Data quality
  final double dataCompleteness; // 0.0 to 1.0
  final bool hasFullDayData;
  final List<int> missingHours;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;

  DailyCalorieTotal({
    this.id,
    required this.userId,
    required this.date,
    this.totalBmrCalories = 0,
    this.totalActiveCalories = 0,
    this.totalExerciseCalories = 0,
    this.totalCalories = 0,
    this.totalSteps = 0,
    this.totalDistanceMeters = 0,
    this.totalFloors = 0,
    this.activeMinutes = 0,
    this.sedentaryMinutes = 0,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.restingHeartRate,
    this.exerciseMinutes = 0,
    this.exerciseTypes = const [],
    this.sessionCount = 0,
    this.exerciseSessionCount = 0,
    this.appOpenCount = 0,
    this.firstActivityTime,
    this.lastActivityTime,
    this.mostActiveHour,
    this.dataCompleteness = 0.0,
    this.hasFullDayData = false,
    this.missingHours = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastSyncAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate percentage of daily calorie goal achieved
  double getGoalPercentage(double dailyGoal) {
    if (dailyGoal <= 0) return 0;
    return (totalCalories / dailyGoal) * 100;
  }

  /// Get total distance in kilometers
  double get totalDistanceKm => totalDistanceMeters / 1000;

  /// Get total distance in miles
  double get totalDistanceMiles => totalDistanceMeters / 1609.34;

  /// Check if this was an active day
  bool get wasActiveDay => activeMinutes >= 30;

  /// Get activity level description
  String get activityLevel {
    if (totalSteps >= 10000) return 'Very Active';
    if (totalSteps >= 7500) return 'Active';
    if (totalSteps >= 5000) return 'Moderately Active';
    if (totalSteps >= 2500) return 'Lightly Active';
    return 'Sedentary';
  }

  /// Get data quality description
  String get dataQuality {
    if (dataCompleteness >= 0.9) return 'Complete';
    if (dataCompleteness >= 0.7) return 'Good';
    if (dataCompleteness >= 0.5) return 'Partial';
    return 'Limited';
  }

  /// Format exercise types for display
  String get exerciseTypesDisplay {
    if (exerciseTypes.isEmpty) return 'No exercises';
    if (exerciseTypes.length == 1) return exerciseTypes.first;
    return '${exerciseTypes.length} activities';
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'total_bmr_calories': totalBmrCalories,
      'total_active_calories': totalActiveCalories,
      'total_exercise_calories': totalExerciseCalories,
      'total_calories': totalCalories,
      'total_steps': totalSteps,
      'total_distance_meters': totalDistanceMeters,
      'total_floors': totalFloors,
      'active_minutes': activeMinutes,
      'sedentary_minutes': sedentaryMinutes,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'min_heart_rate': minHeartRate,
      'resting_heart_rate': restingHeartRate,
      'exercise_minutes': exerciseMinutes,
      'exercise_types': exerciseTypes,
      'session_count': sessionCount,
      'exercise_session_count': exerciseSessionCount,
      'app_open_count': appOpenCount,
      'first_activity_time': firstActivityTime,
      'last_activity_time': lastActivityTime,
      'most_active_hour': mostActiveHour,
      'data_completeness': dataCompleteness,
      'has_full_day_data': hasFullDayData,
      'missing_hours': missingHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  /// Create from database map
  factory DailyCalorieTotal.fromMap(Map<String, dynamic> map) {
    return DailyCalorieTotal(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      totalBmrCalories: (map['total_bmr_calories'] ?? 0).toDouble(),
      totalActiveCalories: (map['total_active_calories'] ?? 0).toDouble(),
      totalExerciseCalories: (map['total_exercise_calories'] ?? 0).toDouble(),
      totalCalories: (map['total_calories'] ?? 0).toDouble(),
      totalSteps: map['total_steps'] ?? 0,
      totalDistanceMeters: (map['total_distance_meters'] ?? 0).toDouble(),
      totalFloors: map['total_floors'] ?? 0,
      activeMinutes: map['active_minutes'] ?? 0,
      sedentaryMinutes: map['sedentary_minutes'] ?? 0,
      avgHeartRate: map['avg_heart_rate'],
      maxHeartRate: map['max_heart_rate'],
      minHeartRate: map['min_heart_rate'],
      restingHeartRate: map['resting_heart_rate'],
      exerciseMinutes: map['exercise_minutes'] ?? 0,
      exerciseTypes: map['exercise_types'] != null
          ? List<String>.from(map['exercise_types'])
          : [],
      sessionCount: map['session_count'] ?? 0,
      exerciseSessionCount: map['exercise_session_count'] ?? 0,
      appOpenCount: map['app_open_count'] ?? 0,
      firstActivityTime: map['first_activity_time'],
      lastActivityTime: map['last_activity_time'],
      mostActiveHour: map['most_active_hour'],
      dataCompleteness: (map['data_completeness'] ?? 0.0).toDouble(),
      hasFullDayData: map['has_full_day_data'] ?? false,
      missingHours: map['missing_hours'] != null
          ? List<int>.from(map['missing_hours'])
          : [],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.parse(map['last_sync_at'])
          : null,
    );
  }

  /// Create a copy with updated fields
  DailyCalorieTotal copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? totalBmrCalories,
    double? totalActiveCalories,
    double? totalExerciseCalories,
    double? totalCalories,
    int? totalSteps,
    double? totalDistanceMeters,
    int? totalFloors,
    int? activeMinutes,
    int? sedentaryMinutes,
    int? avgHeartRate,
    int? maxHeartRate,
    int? minHeartRate,
    int? restingHeartRate,
    int? exerciseMinutes,
    List<String>? exerciseTypes,
    int? sessionCount,
    int? exerciseSessionCount,
    int? appOpenCount,
    String? firstActivityTime,
    String? lastActivityTime,
    int? mostActiveHour,
    double? dataCompleteness,
    bool? hasFullDayData,
    List<int>? missingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
  }) {
    return DailyCalorieTotal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalBmrCalories: totalBmrCalories ?? this.totalBmrCalories,
      totalActiveCalories: totalActiveCalories ?? this.totalActiveCalories,
      totalExerciseCalories: totalExerciseCalories ?? this.totalExerciseCalories,
      totalCalories: totalCalories ?? this.totalCalories,
      totalSteps: totalSteps ?? this.totalSteps,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalFloors: totalFloors ?? this.totalFloors,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      exerciseTypes: exerciseTypes ?? this.exerciseTypes,
      sessionCount: sessionCount ?? this.sessionCount,
      exerciseSessionCount: exerciseSessionCount ?? this.exerciseSessionCount,
      appOpenCount: appOpenCount ?? this.appOpenCount,
      firstActivityTime: firstActivityTime ?? this.firstActivityTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      mostActiveHour: mostActiveHour ?? this.mostActiveHour,
      dataCompleteness: dataCompleteness ?? this.dataCompleteness,
      hasFullDayData: hasFullDayData ?? this.hasFullDayData,
      missingHours: missingHours ?? this.missingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return 'DailyCalorieTotal('
        'date: ${date.toIso8601String().split('T')[0]}, '
        'calories: ${totalCalories.toStringAsFixed(0)}, '
        'steps: $totalSteps, '
        'sessions: $sessionCount, '
        'quality: $dataQuality'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyCalorieTotal &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          date == other.date;

  @override
  int get hashCode => Object.hash(userId, date);
}