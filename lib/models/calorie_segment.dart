import 'package:flutter/foundation.dart';

/// Represents a time segment of calorie burn data
class CalorieSegment {
  final String? id;
  final String userId;
  final DateTime sessionDate;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  // Calorie components
  final double bmrCalories;
  final double activeCalories;
  final double exerciseCalories;
  double get totalCalories => bmrCalories + activeCalories + exerciseCalories;

  // Activity data
  final int steps;
  final double distanceMeters;
  final int floorsClimbed;

  // Heart rate data
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;
  final Map<String, dynamic>? heartRateSamples;

  // Exercise data
  final String? exerciseType;
  final String? exerciseName;
  final String? exerciseIntensity;

  // Metadata
  final String segmentType; // 'realtime', 'retroactive', 'exercise', 'sleep', 'rest'
  final String dataSource; // 'samsung_health', 'google_fit', 'apple_health', 'manual', 'calculated'
  final String platform; // 'ios' or 'android'
  final String? deviceModel;
  final String? appVersion;

  // Quality indicators
  final double confidenceScore; // 0.0 to 1.0
  final bool isEstimated;
  final bool isManualEntry;

  // Sync tracking
  String syncStatus;
  DateTime? syncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalorieSegment({
    this.id,
    required this.userId,
    required this.sessionDate,
    required this.sessionStart,
    required this.sessionEnd,
    required this.bmrCalories,
    required this.activeCalories,
    this.exerciseCalories = 0,
    this.steps = 0,
    this.distanceMeters = 0,
    this.floorsClimbed = 0,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.heartRateSamples,
    this.exerciseType,
    this.exerciseName,
    this.exerciseIntensity,
    required this.segmentType,
    required this.dataSource,
    required this.platform,
    this.deviceModel,
    this.appVersion,
    this.confidenceScore = 1.0,
    this.isEstimated = false,
    this.isManualEntry = false,
    this.syncStatus = 'pending',
    this.syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Duration in minutes
  int get durationMinutes => sessionEnd.difference(sessionStart).inMinutes;

  /// Check if this is an exercise segment
  bool get isExercise => segmentType == 'exercise' || exerciseType != null;

  /// Check if this segment has high quality data
  bool get hasHighQualityData => confidenceScore >= 0.8 && !isEstimated;

  /// Calories per minute rate
  double get caloriesPerMinute {
    if (durationMinutes == 0) return 0;
    return totalCalories / durationMinutes;
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'session_date': sessionDate.toIso8601String().split('T')[0],
      'session_start': sessionStart.toIso8601String(),
      'session_end': sessionEnd.toIso8601String(),
      'bmr_calories': bmrCalories,
      'active_calories': activeCalories,
      'exercise_calories': exerciseCalories,
      'steps': steps,
      'distance_meters': distanceMeters,
      'floors_climbed': floorsClimbed,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'min_heart_rate': minHeartRate,
      'heart_rate_samples': heartRateSamples,
      'exercise_type': exerciseType,
      'exercise_name': exerciseName,
      'exercise_intensity': exerciseIntensity,
      'segment_type': segmentType,
      'data_source': dataSource,
      'platform': platform,
      'device_model': deviceModel,
      'app_version': appVersion,
      'confidence_score': confidenceScore,
      'is_estimated': isEstimated,
      'is_manual_entry': isManualEntry,
      'sync_status': syncStatus,
      'synced_at': syncedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory CalorieSegment.fromMap(Map<String, dynamic> map) {
    return CalorieSegment(
      id: map['id'],
      userId: map['user_id'],
      sessionDate: DateTime.parse(map['session_date']),
      sessionStart: DateTime.parse(map['session_start']),
      sessionEnd: DateTime.parse(map['session_end']),
      bmrCalories: (map['bmr_calories'] ?? 0).toDouble(),
      activeCalories: (map['active_calories'] ?? 0).toDouble(),
      exerciseCalories: (map['exercise_calories'] ?? 0).toDouble(),
      steps: map['steps'] ?? 0,
      distanceMeters: (map['distance_meters'] ?? 0).toDouble(),
      floorsClimbed: map['floors_climbed'] ?? 0,
      avgHeartRate: map['avg_heart_rate'],
      maxHeartRate: map['max_heart_rate'],
      minHeartRate: map['min_heart_rate'],
      heartRateSamples: map['heart_rate_samples'],
      exerciseType: map['exercise_type'],
      exerciseName: map['exercise_name'],
      exerciseIntensity: map['exercise_intensity'],
      segmentType: map['segment_type'] ?? 'rest',
      dataSource: map['data_source'] ?? 'manual',
      platform: map['platform'] ?? 'unknown',
      deviceModel: map['device_model'],
      appVersion: map['app_version'],
      confidenceScore: (map['confidence_score'] ?? 1.0).toDouble(),
      isEstimated: map['is_estimated'] ?? false,
      isManualEntry: map['is_manual_entry'] ?? false,
      syncStatus: map['sync_status'] ?? 'pending',
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Create a copy with updated fields
  CalorieSegment copyWith({
    String? id,
    String? userId,
    DateTime? sessionDate,
    DateTime? sessionStart,
    DateTime? sessionEnd,
    double? bmrCalories,
    double? activeCalories,
    double? exerciseCalories,
    int? steps,
    double? distanceMeters,
    int? floorsClimbed,
    int? avgHeartRate,
    int? maxHeartRate,
    int? minHeartRate,
    Map<String, dynamic>? heartRateSamples,
    String? exerciseType,
    String? exerciseName,
    String? exerciseIntensity,
    String? segmentType,
    String? dataSource,
    String? platform,
    String? deviceModel,
    String? appVersion,
    double? confidenceScore,
    bool? isEstimated,
    bool? isManualEntry,
    String? syncStatus,
    DateTime? syncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalorieSegment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      bmrCalories: bmrCalories ?? this.bmrCalories,
      activeCalories: activeCalories ?? this.activeCalories,
      exerciseCalories: exerciseCalories ?? this.exerciseCalories,
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      floorsClimbed: floorsClimbed ?? this.floorsClimbed,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      heartRateSamples: heartRateSamples ?? this.heartRateSamples,
      exerciseType: exerciseType ?? this.exerciseType,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseIntensity: exerciseIntensity ?? this.exerciseIntensity,
      segmentType: segmentType ?? this.segmentType,
      dataSource: dataSource ?? this.dataSource,
      platform: platform ?? this.platform,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isEstimated: isEstimated ?? this.isEstimated,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CalorieSegment('
        'date: ${sessionDate.toIso8601String().split('T')[0]}, '
        'time: ${sessionStart.hour}:${sessionStart.minute.toString().padLeft(2, '0')}-'
        '${sessionEnd.hour}:${sessionEnd.minute.toString().padLeft(2, '0')}, '
        'calories: ${totalCalories.toStringAsFixed(1)}, '
        'type: $segmentType'
        '${isExercise ? ', exercise: $exerciseType' : ''}'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalorieSegment &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          sessionStart == other.sessionStart &&
          sessionEnd == other.sessionEnd;

  @override
  int get hashCode => Object.hash(userId, sessionStart, sessionEnd);
}