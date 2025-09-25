import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calorie_segment.dart';
import '../models/daily_calorie_total.dart';
import 'unified_health_service.dart';

/// Service responsible for tracking and calculating calories throughout the day
/// Handles both real-time and retroactive calorie calculations
class CalorieTrackingService {
  static final CalorieTrackingService _instance = CalorieTrackingService._internal();
  factory CalorieTrackingService() => _instance;
  CalorieTrackingService._internal();

  final _supabase = Supabase.instance.client;
  final _healthService = UnifiedHealthService();
  SharedPreferences? _prefs;
  Timer? _syncTimer;

  // Track sync state
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  final List<CalorieSegment> _offlineQueue = [];

  // User profile for BMR calculation
  Map<String, dynamic>? _userProfile;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Load user profile
    await _loadUserProfile();

    // Load last sync time
    final lastSyncStr = _prefs?.getString('last_calorie_sync');
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.parse(lastSyncStr);
    }

    // Start periodic sync every 30 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 30), (_) => syncCalories());

    // Initial sync
    await syncCalories();
  }

  /// Load user profile for BMR calculation
  Future<void> _loadUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
        .from('profiles')
        .select('age, weight, height, gender, activity_level')
        .eq('id', userId)
        .single();

      _userProfile = response;
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  /// Main sync method - called periodically and on app open
  Future<void> syncCalories({bool forceFullSync = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Determine sync range
      DateTime syncStart;
      if (forceFullSync || _isFirstSyncToday()) {
        // Full day reconstruction
        syncStart = midnight;
        debugPrint('🔄 Performing full day calorie reconstruction');
      } else {
        // Incremental sync since last check
        syncStart = _lastSyncTime ?? midnight;
        debugPrint('🔄 Performing incremental calorie sync since $syncStart');
      }

      // Fetch health data for the period
      final healthData = await _fetchHealthData(syncStart, now);

      // Process into segments
      final segments = await _processHealthDataIntoSegments(
        healthData,
        syncStart,
        now,
        userId,
      );

      // Save segments to database
      await _saveSegments(segments, userId);

      // Update last sync time
      _lastSyncTime = now;
      await _prefs?.setString('last_calorie_sync', now.toIso8601String());

      // Process offline queue if any
      await _processOfflineQueue();

      debugPrint('✅ Calorie sync completed: ${segments.length} segments processed');

    } catch (e) {
      debugPrint('❌ Calorie sync failed: $e');
      // Queue for offline processing
      await _handleSyncError(e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if this is the first sync today
  bool _isFirstSyncToday() {
    if (_lastSyncTime == null) return true;

    final now = DateTime.now();
    return _lastSyncTime!.day != now.day ||
           _lastSyncTime!.month != now.month ||
           _lastSyncTime!.year != now.year;
  }

  /// Fetch health data from platform-specific sources
  Future<Map<String, dynamic>> _fetchHealthData(DateTime start, DateTime end) async {
    final healthData = await _healthService.fetchHealthData();

    // Get detailed activity data if available
    if (Platform.isAndroid) {
      // Call native method for detailed Samsung Health/Google Fit data
      try {
        const platform = MethodChannel('com.streaker.health/native');
        final result = await platform.invokeMethod('getDetailedCalorieData', {
          'startTime': start.millisecondsSinceEpoch,
          'endTime': end.millisecondsSinceEpoch,
        });

        return Map<String, dynamic>.from(result);
      } catch (e) {
        debugPrint('Native health data fetch failed: $e');
        return healthData;
      }
    } else {
      // iOS: Use health service data
      return healthData;
    }
  }

  /// Process health data into calorie segments
  Future<List<CalorieSegment>> _processHealthDataIntoSegments(
    Map<String, dynamic> healthData,
    DateTime start,
    DateTime end,
    String userId,
  ) async {
    final segments = <CalorieSegment>[];

    // Check for exercise sessions
    if (healthData['exerciseSessions'] != null) {
      // Process exercise sessions first
      for (final session in healthData['exerciseSessions']) {
        segments.add(CalorieSegment(
          userId: userId,
          sessionDate: DateTime.parse(session['date']),
          sessionStart: DateTime.fromMillisecondsSinceEpoch(session['start']),
          sessionEnd: DateTime.fromMillisecondsSinceEpoch(session['end']),
          bmrCalories: _calculateBMRForPeriod(
            DateTime.fromMillisecondsSinceEpoch(session['start']),
            DateTime.fromMillisecondsSinceEpoch(session['end']),
          ),
          activeCalories: (session['calories'] ?? 0).toDouble(),
          exerciseCalories: (session['exerciseCalories'] ?? 0).toDouble(),
          steps: session['steps'] ?? 0,
          distanceMeters: (session['distance'] ?? 0).toDouble(),
          avgHeartRate: session['avgHeartRate'],
          maxHeartRate: session['maxHeartRate'],
          exerciseType: session['type'],
          exerciseName: session['name'],
          exerciseIntensity: _determineIntensity(session['avgHeartRate']),
          segmentType: 'exercise',
          dataSource: _getDataSource(),
          platform: Platform.isIOS ? 'ios' : 'android',
          confidenceScore: 1.0,
          isEstimated: false,
        ));
      }
    }

    // Fill gaps with hourly segments
    segments.addAll(await _createHourlySegments(
      healthData,
      start,
      end,
      userId,
      segments, // Pass existing exercise segments to avoid overlap
    ));

    return segments;
  }

  /// Create hourly segments for non-exercise periods
  Future<List<CalorieSegment>> _createHourlySegments(
    Map<String, dynamic> healthData,
    DateTime start,
    DateTime end,
    String userId,
    List<CalorieSegment> existingSegments,
  ) async {
    final segments = <CalorieSegment>[];
    DateTime currentHour = start;

    while (currentHour.isBefore(end)) {
      final nextHour = currentHour.add(Duration(hours: 1));
      final segmentEnd = nextHour.isAfter(end) ? end : nextHour;

      // Check if this period overlaps with any exercise session
      final hasExercise = existingSegments.any((seg) =>
        seg.sessionStart.isBefore(segmentEnd) &&
        seg.sessionEnd.isAfter(currentHour)
      );

      if (!hasExercise) {
        // Create non-exercise segment
        final hourlySteps = _getMetricForPeriod(
          healthData['stepsData'],
          currentHour,
          segmentEnd,
        );

        final hourlyDistance = _getMetricForPeriod(
          healthData['distanceData'],
          currentHour,
          segmentEnd,
        );

        final avgHeartRate = _getAverageHeartRate(
          healthData['heartRateData'],
          currentHour,
          segmentEnd,
        );

        // Calculate active calories based on steps and heart rate
        final activeCalories = _calculateActiveCalories(
          steps: hourlySteps,
          heartRate: avgHeartRate,
          duration: segmentEnd.difference(currentHour).inMinutes,
        );

        segments.add(CalorieSegment(
          userId: userId,
          sessionDate: DateTime(currentHour.year, currentHour.month, currentHour.day),
          sessionStart: currentHour,
          sessionEnd: segmentEnd,
          bmrCalories: _calculateBMRForPeriod(currentHour, segmentEnd),
          activeCalories: activeCalories,
          exerciseCalories: 0,
          steps: hourlySteps,
          distanceMeters: hourlyDistance.toDouble(),
          avgHeartRate: avgHeartRate > 0 ? avgHeartRate : null,
          segmentType: _determineSegmentType(currentHour),
          dataSource: _getDataSource(),
          platform: Platform.isIOS ? 'ios' : 'android',
          confidenceScore: avgHeartRate > 0 ? 0.9 : 0.7,
          isEstimated: activeCalories == 0,
        ));
      }

      currentHour = nextHour;
    }

    return segments;
  }

  /// Calculate BMR for a specific period
  double _calculateBMRForPeriod(DateTime start, DateTime end) {
    if (_userProfile == null) {
      // Default BMR if profile not available
      return 70.0 * (end.difference(start).inMinutes / 60);
    }

    final age = _userProfile!['age'] ?? 30;
    final weight = _userProfile!['weight'] ?? 70.0;
    final height = _userProfile!['height'] ?? 170.0;
    final gender = _userProfile!['gender'] ?? 'male';

    // Mifflin-St Jeor equation
    double dailyBMR;
    if (gender.toLowerCase() == 'male') {
      dailyBMR = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      dailyBMR = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Calculate for the specific period
    final hours = end.difference(start).inMinutes / 60;
    return (dailyBMR / 24) * hours;
  }

  /// Calculate active calories based on activity metrics
  double _calculateActiveCalories({
    required int steps,
    required int heartRate,
    required int duration,
  }) {
    if (steps == 0 && heartRate == 0) return 0;

    // Steps-based calculation (0.04 cal per step is average)
    double stepCalories = steps * 0.04;

    // Heart rate adjustment
    if (heartRate > 0 && _userProfile != null) {
      final age = _userProfile!['age'] ?? 30;
      final weight = _userProfile!['weight'] ?? 70.0;

      // Calculate intensity based on heart rate
      final maxHR = 220 - age;
      final intensity = (heartRate - 60) / (maxHR - 60);

      if (intensity > 0.3) {
        // Moderate to vigorous activity
        final metValue = 3.5 + (intensity * 10); // MET value based on intensity
        final heartRateCalories = (metValue * weight * (duration / 60));

        // Use the higher value between steps and heart rate calculation
        return heartRateCalories > stepCalories ? heartRateCalories : stepCalories;
      }
    }

    return stepCalories;
  }

  /// Save segments to database
  Future<void> _saveSegments(List<CalorieSegment> segments, String userId) async {
    if (segments.isEmpty) return;

    try {
      // Batch insert for efficiency
      final segmentMaps = segments.map((s) => s.toMap()).toList();

      await _supabase
        .from('calorie_sessions')
        .upsert(segmentMaps, onConflict: 'user_id,session_start,session_end');

      // Mark as synced
      for (final segment in segments) {
        segment.syncStatus = 'synced';
        segment.syncedAt = DateTime.now();
      }

      // Trigger daily total calculation
      final dates = segments.map((s) => s.sessionDate).toSet();
      for (final date in dates) {
        await _calculateDailyTotals(userId, date);
      }

    } catch (e) {
      debugPrint('Failed to save segments: $e');
      // Add to offline queue
      _offlineQueue.addAll(segments);
      throw e;
    }
  }

  /// Calculate and update daily totals
  Future<void> _calculateDailyTotals(String userId, DateTime date) async {
    try {
      // Call the database function to aggregate
      await _supabase.rpc('calculate_daily_calorie_totals', params: {
        'p_user_id': userId,
        'p_date': date.toIso8601String().split('T')[0],
      });
    } catch (e) {
      debugPrint('Failed to calculate daily totals: $e');
    }
  }

  /// Get today's calorie total
  Future<DailyCalorieTotal?> getTodayTotal() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final response = await _supabase
        .from('daily_calorie_totals')
        .select()
        .eq('user_id', userId)
        .eq('date', todayStr)
        .maybeSingle();

      if (response != null) {
        return DailyCalorieTotal.fromMap(response);
      }
    } catch (e) {
      debugPrint('Failed to get today total: $e');
    }

    return null;
  }

  /// Get calorie history for a date range
  Future<List<DailyCalorieTotal>> getCalorieHistory({
    int days = 7,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    try {
      final response = await _supabase
        .from('daily_calorie_totals')
        .select()
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);

      return (response as List)
        .map((json) => DailyCalorieTotal.fromMap(json))
        .toList();
    } catch (e) {
      debugPrint('Failed to get calorie history: $e');
      return [];
    }
  }

  /// Process offline queue
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final toProcess = List<CalorieSegment>.from(_offlineQueue);
    _offlineQueue.clear();

    try {
      await _saveSegments(toProcess, userId);
      debugPrint('✅ Processed ${toProcess.length} offline segments');
    } catch (e) {
      // Re-add to queue if still failing
      _offlineQueue.addAll(toProcess);
    }
  }

  /// Handle sync errors
  Future<void> _handleSyncError(dynamic error) async {
    // Save error state
    await _prefs?.setString('last_calorie_sync_error', error.toString());
    await _prefs?.setString('last_calorie_sync_error_time', DateTime.now().toIso8601String());
  }

  // Helper methods

  int _getMetricForPeriod(List<dynamic>? data, DateTime start, DateTime end) {
    if (data == null || data.isEmpty) return 0;

    int total = 0;
    for (final point in data) {
      final pointTime = DateTime.parse(point['timestamp']);
      if (pointTime.isAfter(start) && pointTime.isBefore(end)) {
        total += (point['value'] as num).toInt();
      }
    }
    return total;
  }

  int _getAverageHeartRate(List<dynamic>? data, DateTime start, DateTime end) {
    if (data == null || data.isEmpty) return 0;

    final validPoints = <int>[];
    for (final point in data) {
      final pointTime = DateTime.parse(point['timestamp']);
      if (pointTime.isAfter(start) && pointTime.isBefore(end)) {
        validPoints.add((point['value'] as num).toInt());
      }
    }

    if (validPoints.isEmpty) return 0;
    return validPoints.reduce((a, b) => a + b) ~/ validPoints.length;
  }

  String _determineSegmentType(DateTime time) {
    final hour = time.hour;

    if (hour >= 0 && hour < 6) return 'sleep';
    if (hour >= 6 && hour < 9) return 'rest';
    if (hour >= 9 && hour < 17) return 'rest';
    if (hour >= 17 && hour < 21) return 'rest';
    return 'sleep';
  }

  String _determineIntensity(int? heartRate) {
    if (heartRate == null || _userProfile == null) return 'moderate';

    final age = _userProfile!['age'] ?? 30;
    final maxHR = 220 - age;
    final percentage = heartRate / maxHR;

    if (percentage < 0.5) return 'light';
    if (percentage < 0.7) return 'moderate';
    return 'vigorous';
  }

  String _getDataSource() {
    if (Platform.isIOS) return 'apple_health';
    // Could be samsung_health or google_fit, need to check
    return 'samsung_health'; // Default for Android
  }

  /// Clean up resources
  void dispose() {
    _syncTimer?.cancel();
  }
}