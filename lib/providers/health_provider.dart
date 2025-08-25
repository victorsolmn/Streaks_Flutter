import 'package:flutter/foundation.dart';
import '../models/health_metric_model.dart';

class HealthProvider with ChangeNotifier {
  Map<MetricType, HealthMetric> _metrics = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  
  Map<MetricType, HealthMetric> get metrics => _metrics;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Create mock data for demo
    _metrics = {
      MetricType.steps: HealthMetric(value: 7700, timestamp: DateTime.now(), type: MetricType.steps, currentValue: 7700, goalValue: 10000),
      MetricType.caloriesIntake: HealthMetric(value: 2100, timestamp: DateTime.now(), type: MetricType.caloriesIntake, currentValue: 2100, goalValue: 2200),
      MetricType.sleep: HealthMetric(value: 7.5, timestamp: DateTime.now(), type: MetricType.sleep, currentValue: 7.5, goalValue: 8.0),
      MetricType.restingHeartRate: HealthMetric(value: 68, timestamp: DateTime.now(), type: MetricType.restingHeartRate, currentValue: 68, goalValue: 60),
    };
    
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> fetchMetrics() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isLoading = false;
    notifyListeners();
  }
}