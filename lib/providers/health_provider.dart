import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_metric_model.dart';
import '../services/unified_health_service.dart';
import '../services/realtime_sync_service.dart';
import '../services/supabase_service.dart';

class HealthProvider with ChangeNotifier {
  Map<MetricType, HealthMetric> _metrics = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  final UnifiedHealthService _healthService = UnifiedHealthService();
  final RealtimeSyncService _syncService = RealtimeSyncService();
  final SupabaseService _supabaseService = SupabaseService();
  SharedPreferences? _prefs;
  HealthDataSource _currentDataSource = HealthDataSource.unavailable;
  
  // Expose health service for direct access
  UnifiedHealthService get healthService => _healthService;
  
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
  HealthDataSource get dataSource => _currentDataSource;
  Map<String, String> get dataSourceInfo => _healthService.getDataSourceInfo();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved data from SharedPreferences
    await _loadHealthData();
    
    // Initialize unified health service
    await _healthService.initialize();
    
    // Set up callback for data updates
    _healthService.setDataUpdateCallback((data) {
      updateMetricsFromHealth(data);
    });
    
    // Get current data source
    _currentDataSource = _healthService.currentSource;
    
    // Initialize with saved or zero values - will be populated from health service
    _metrics = {
      MetricType.steps: HealthMetric(value: _todaySteps, timestamp: DateTime.now(), type: MetricType.steps, currentValue: _todaySteps, goalValue: 10000),
      MetricType.caloriesIntake: HealthMetric(value: _todayCaloriesBurned, timestamp: DateTime.now(), type: MetricType.caloriesIntake, currentValue: _todayCaloriesBurned, goalValue: 2200),
      MetricType.sleep: HealthMetric(value: _todaySleep, timestamp: DateTime.now(), type: MetricType.sleep, currentValue: _todaySleep, goalValue: 8.0),
      MetricType.restingHeartRate: HealthMetric(value: _todayHeartRate, timestamp: DateTime.now(), type: MetricType.restingHeartRate, currentValue: _todayHeartRate, goalValue: 60),
    };
    
    // Request permissions and fetch initial data if source available
    if (_healthService.isDataSourceAvailable) {
      await fetchMetrics();
    } else {
      // Try to request permissions for platform health APIs
      final result = await _healthService.requestHealthPermissions();
      if (result.success) {
        _currentDataSource = _healthService.currentSource;
        await fetchMetrics();
      }
    }
    
    // Start automatic sync
    await _healthService.startDataSync();
    
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> fetchMetrics() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch data from unified health service
      final data = await _healthService.fetchHealthData();
      _currentDataSource = _healthService.currentSource;
      updateMetricsFromHealth(data);
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void updateMetricsFromHealth(Map<String, dynamic> data) {
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
  Future<void> syncWithHealth() async {
    await _healthService.syncNow();
    await fetchMetrics();
  }
  
  // Check if health source is connected
  bool get isHealthSourceConnected => _healthService.isDataSourceAvailable;
  String? get connectedDevice {
    if (_currentDataSource == HealthDataSource.bluetooth) {
      var deviceInfo = _healthService.getConnectedDeviceInfo();
      return deviceInfo?['name'];
    }
    return _healthService.getDataSourceInfo()['source'];
  }
  
  // Scan for Bluetooth devices (fallback option)
  Future<List<Map<String, dynamic>>> scanForBluetoothDevices() async {
    return await _healthService.scanForBluetoothDevices();
  }
  
  // Connect to Bluetooth device
  Future<bool> connectBluetoothDevice(Map<String, dynamic> deviceInfo) async {
    bool connected = await _healthService.connectBluetoothDevice(deviceInfo);
    if (connected) {
      _currentDataSource = HealthDataSource.bluetooth;
      await fetchMetrics();
    }
    return connected;
  }
  
  // Disconnect Bluetooth device
  Future<void> disconnectBluetoothDevice() async {
    await _healthService.disconnectBluetoothDevice();
    _currentDataSource = _healthService.currentSource;
    notifyListeners();
  }
  
  // Request health permissions
  Future<bool> requestHealthPermissions() async {
    final result = await _healthService.requestHealthPermissions();
    if (result.success) {
      _currentDataSource = _healthService.currentSource;
      await fetchMetrics();
    }
    return result.success;
  }

  // Initialize health service connection (for UI calls)
  Future<bool> initializeHealth() async {
    try {
      // Initialize the health service
      await _healthService.initialize();
      
      // Update current data source
      _currentDataSource = _healthService.currentSource;
      
      // If source is available, fetch initial data
      if (_healthService.isDataSourceAvailable) {
        await fetchMetrics();
        return true;
      } else {
        // Try to request permissions
        final result = await _healthService.requestHealthPermissions();
        if (result.success) {
          _currentDataSource = _healthService.currentSource;
          await fetchMetrics();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('HealthProvider: Error initializing health service: $e');
      return false;
    }
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
    
    // Save to Supabase directly
    await saveHealthDataToSupabase();
    
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
  
  // Update health connection status
  Future<void> updateHealthConnectionStatus(bool connected) async {
    if (connected) {
      _currentDataSource = _healthService.currentSource;
      await fetchMetrics();
    } else {
      _currentDataSource = HealthDataSource.unavailable;
    }
    notifyListeners();
  }

  // Load health data from Supabase
  Future<void> loadHealthDataFromSupabase() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      // If not logged in, just load from local storage
      await _loadHealthData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get today's date
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Load today's health metrics from Supabase
      final healthData = await _supabaseService.getHealthMetrics(
        userId: userId,
        date: todayStr,
      );

      if (healthData != null) {
        // Update local data with Supabase data
        _todaySteps = (healthData['steps'] ?? 0).toDouble();
        _todayCaloriesBurned = (healthData['calories_burned'] ?? 0).toDouble();
        _todayHeartRate = (healthData['heart_rate'] ?? 0).toDouble();
        _todaySleep = (healthData['sleep_hours'] ?? 0).toDouble();
        _todayDistance = (healthData['distance'] ?? 0).toDouble();
        
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
        
        // Save to local storage
        await _saveHealthData();
      } else {
        // No data in Supabase, load from local
        await _loadHealthData();
      }
    } catch (e) {
      debugPrint('Error loading health data from Supabase: $e');
      // Fallback to local data
      await _loadHealthData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save health data to Supabase
  Future<void> saveHealthDataToSupabase() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      await _supabaseService.saveHealthMetrics(
        userId: userId,
        date: todayStr,
        metrics: {
          'steps': _todaySteps.toInt(),
          'heart_rate': _todayHeartRate.toInt(),
          'sleep_hours': _todaySleep,
          'calories_burned': _todayCaloriesBurned.toInt(),
          'distance': _todayDistance,
          'active_minutes': _todayWorkouts * 30, // Approximate
        },
      );
    } catch (e) {
      debugPrint('Error saving health data to Supabase: $e');
    }
  }
}