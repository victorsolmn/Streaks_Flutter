import 'package:flutter/foundation.dart';
import '../models/health_metric_model.dart';
import '../services/smartwatch_service.dart';

class HealthProvider with ChangeNotifier {
  Map<MetricType, HealthMetric> _metrics = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  final SmartwatchService _smartwatchService = SmartwatchService();
  
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
    
    // Initialize smartwatch service
    await _smartwatchService.initialize();
    
    // Set up callback for data updates
    _smartwatchService.setDataUpdateCallback((data) {
      updateMetricsFromSmartwatch(data);
    });
    
    // Initialize with zero values - will be populated from actual fitness tracker
    _metrics = {
      MetricType.steps: HealthMetric(value: 0, timestamp: DateTime.now(), type: MetricType.steps, currentValue: 0, goalValue: 10000),
      MetricType.caloriesIntake: HealthMetric(value: 0, timestamp: DateTime.now(), type: MetricType.caloriesIntake, currentValue: 0, goalValue: 2200),
      MetricType.sleep: HealthMetric(value: 0, timestamp: DateTime.now(), type: MetricType.sleep, currentValue: 0, goalValue: 8.0),
      MetricType.restingHeartRate: HealthMetric(value: 0, timestamp: DateTime.now(), type: MetricType.restingHeartRate, currentValue: 0, goalValue: 60),
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
    
    notifyListeners();
  }
  
  // Method to manually sync data
  Future<void> syncWithSmartwatch() async {
    await fetchMetrics();
  }
  
  // Check if smartwatch is connected
  bool get isSmartWatchConnected => _smartwatchService.isDeviceConnected;
  String? get connectedDevice => _smartwatchService.connectedDevice;
}