import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_metric_model.dart';
import '../services/smartwatch_service.dart';
import '../services/realtime_sync_service.dart';

class HealthProvider with ChangeNotifier {
  Map<MetricType, HealthMetric> _metrics = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  final SmartwatchService _smartwatchService = SmartwatchService();
  final RealtimeSyncService _syncService = RealtimeSyncService();
  SharedPreferences? _prefs;
  
  // Today's data
  double _todaySteps = 0;
  double _todayCaloriesBurned = 0;
  double _todayHeartRate = 0;
  double _todaySleep = 0;
  double _todayDistance = 0;
  int _todayWater = 0;
  int _todayWorkouts = 0;
  
  Map<MetricType, HealthMetric> get metrics => _metrics;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  
  // Getters for today's data
  double get todaySteps => _todaySteps;
  double get todayCaloriesBurned => _todayCaloriesBurned;
  double get todayHeartRate => _todayHeartRate;
  double get todaySleep => _todaySleep;
  double get todayDistance => _todayDistance;
  int get todayWater => _todayWater;
  int get todayWorkouts => _todayWorkouts;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved data from SharedPreferences
    await _loadHealthData();
    
    // Initialize smartwatch service
    await _smartwatchService.initialize();
    
    // Set up callback for data updates
    _smartwatchService.setDataUpdateCallback((data) {
      updateMetricsFromSmartwatch(data);
    });
    
    // Initialize with saved or zero values - will be populated from actual fitness tracker
    _metrics = {
      MetricType.steps: HealthMetric(value: _todaySteps, timestamp: DateTime.now(), type: MetricType.steps, currentValue: _todaySteps, goalValue: 10000),
      MetricType.caloriesIntake: HealthMetric(value: _todayCaloriesBurned, timestamp: DateTime.now(), type: MetricType.caloriesIntake, currentValue: _todayCaloriesBurned, goalValue: 2200),
      MetricType.sleep: HealthMetric(value: _todaySleep, timestamp: DateTime.now(), type: MetricType.sleep, currentValue: _todaySleep, goalValue: 8.0),
      MetricType.restingHeartRate: HealthMetric(value: _todayHeartRate, timestamp: DateTime.now(), type: MetricType.restingHeartRate, currentValue: _todayHeartRate, goalValue: 60),
    };
    
    // Fetch initial data from smartwatch if connected
    if (_smartwatchService.isDeviceConnected) {
      await fetchMetrics();
    }
    
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> fetchMetrics() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch data from smartwatch
      final data = await _smartwatchService.fetchHealthData();
      updateMetricsFromSmartwatch(data);
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void updateMetricsFromSmartwatch(Map<String, dynamic> data) {
    // Update today's data
    _todaySteps = (data['steps'] ?? 0).toDouble();
    _todayCaloriesBurned = (data['calories'] ?? 0).toDouble();
    _todayHeartRate = (data['heartRate'] ?? 0).toDouble();
    _todaySleep = (data['sleep'] ?? 0).toDouble();
    _todayDistance = (data['distance'] ?? 0).toDouble();
    _todayWater = data['water'] ?? 0;
    _todayWorkouts = data['workouts'] ?? 0;
    
    // Update metrics
    _metrics[MetricType.steps] = HealthMetric(
      value: _todaySteps,
      timestamp: DateTime.now(),
      type: MetricType.steps,
      currentValue: _todaySteps,
      goalValue: 10000,
    );
    
    _metrics[MetricType.caloriesIntake] = HealthMetric(
      value: _todayCaloriesBurned,
      timestamp: DateTime.now(),
      type: MetricType.caloriesIntake,
      currentValue: _todayCaloriesBurned,
      goalValue: 2200,
    );
    
    _metrics[MetricType.sleep] = HealthMetric(
      value: _todaySleep,
      timestamp: DateTime.now(),
      type: MetricType.sleep,
      currentValue: _todaySleep,
      goalValue: 8.0,
    );
    
    _metrics[MetricType.restingHeartRate] = HealthMetric(
      value: _todayHeartRate,
      timestamp: DateTime.now(),
      type: MetricType.restingHeartRate,
      currentValue: _todayHeartRate,
      goalValue: 60,
    );
    
    // Save to SharedPreferences and sync to Supabase
    _saveHealthData();
    notifyListeners();
  }
  
  // Method to manually sync data
  Future<void> syncWithSmartwatch() async {
    await fetchMetrics();
  }
  
  // Check if smartwatch is connected
  bool get isSmartWatchConnected => _smartwatchService.isDeviceConnected;
  String? get connectedDevice => _smartwatchService.connectedDevice;
  
  // Update from new Bluetooth service
  void updateFromSmartwatch(Map<String, dynamic> data) {
    updateMetricsFromSmartwatch(data);
  }
  
  // Load health data from SharedPreferences
  Future<void> _loadHealthData() async {
    if (_prefs == null) return;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Load today's data
    _todaySteps = _prefs!.getDouble('steps_$todayKey') ?? 0;
    _todayCaloriesBurned = _prefs!.getDouble('calories_burned_$todayKey') ?? 0;
    _todayHeartRate = _prefs!.getDouble('heart_rate_$todayKey') ?? 0;
    _todaySleep = _prefs!.getDouble('sleep_$todayKey') ?? 0;
    _todayDistance = _prefs!.getDouble('distance_$todayKey') ?? 0;
    _todayWater = _prefs!.getInt('water_$todayKey') ?? 0;
    _todayWorkouts = _prefs!.getInt('workouts_$todayKey') ?? 0;
  }
  
  // Save health data to SharedPreferences and sync to Supabase
  Future<void> _saveHealthData() async {
    if (_prefs == null) return;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Save to SharedPreferences
    await _prefs!.setDouble('steps_$todayKey', _todaySteps);
    await _prefs!.setDouble('calories_burned_$todayKey', _todayCaloriesBurned);
    await _prefs!.setDouble('heart_rate_$todayKey', _todayHeartRate);
    await _prefs!.setDouble('sleep_$todayKey', _todaySleep);
    await _prefs!.setDouble('distance_$todayKey', _todayDistance);
    await _prefs!.setInt('water_$todayKey', _todayWater);
    await _prefs!.setInt('workouts_$todayKey', _todayWorkouts);
    
    // Also save for RealtimeSyncService to pick up
    await _prefs!.setInt('today_steps', _todaySteps.toInt());
    await _prefs!.setInt('today_heart_rate', _todayHeartRate.toInt());
    await _prefs!.setDouble('today_sleep', _todaySleep);
    await _prefs!.setInt('today_calories_burned', _todayCaloriesBurned.toInt());
    
    // Trigger immediate sync to Supabase
    await _syncService.syncAll();
  }
  
  // Method to update water intake
  Future<void> updateWaterIntake(int glasses) async {
    _todayWater = glasses;
    await _saveHealthData();
    notifyListeners();
  }
  
  // Method to log a workout
  Future<void> logWorkout() async {
    _todayWorkouts++;
    await _saveHealthData();
    notifyListeners();
  }
}