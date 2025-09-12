import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
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
  
  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  Timer? _syncTimer;
  
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
  double _todayWeight = 0.0;
  int _todayBloodOxygen = 0;
  Map<String, int> _todayBloodPressure = {'systolic': 0, 'diastolic': 0};
  int _todayExerciseMinutes = 0;
  
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
  double get todayWeight => _todayWeight;
  int get todayBloodOxygen => _todayBloodOxygen;
  Map<String, int> get todayBloodPressure => _todayBloodPressure;
  int get todayExerciseMinutes => _todayExerciseMinutes;
  HealthDataSource get dataSource => _currentDataSource;
  Map<String, String> get dataSourceInfo => _healthService.getDataSourceInfo();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved data from SharedPreferences
    await _loadHealthData();
    
    // Setup connectivity monitoring
    _setupConnectivityMonitoring();
    
    // Initialize unified health service
    await _healthService.initialize();
    
    // Set up callback for data updates
    _healthService.setDataUpdateCallback((data) {
      updateMetricsFromHealth(data);
    });
    
    // Get current data source (prefer saved one over detected)
    if (_currentDataSource == HealthDataSource.unavailable) {
      _currentDataSource = _healthService.currentSource;
    }
    
    // Initialize with saved values - will be updated from health service if available
    _metrics = {
      MetricType.steps: HealthMetric(value: _todaySteps, timestamp: DateTime.now(), type: MetricType.steps, currentValue: _todaySteps, goalValue: 10000),
      MetricType.caloriesIntake: HealthMetric(value: _todayCaloriesBurned, timestamp: DateTime.now(), type: MetricType.caloriesIntake, currentValue: _todayCaloriesBurned, goalValue: 2200),
      MetricType.sleep: HealthMetric(value: _todaySleep, timestamp: DateTime.now(), type: MetricType.sleep, currentValue: _todaySleep, goalValue: 8.0),
      MetricType.restingHeartRate: HealthMetric(value: _todayHeartRate, timestamp: DateTime.now(), type: MetricType.restingHeartRate, currentValue: _todayHeartRate, goalValue: 60),
    };
    
    // If we have a saved connection, try to reconnect
    if (_currentDataSource != HealthDataSource.unavailable) {
      await connectToHealthSource(_currentDataSource);
    }
    
    // Request permissions and fetch initial data if source available
    if (_healthService.isDataSourceAvailable) {
      await fetchMetrics();
    } else if (_currentDataSource == HealthDataSource.unavailable) {
      // Only try to request permissions if we don't have a saved connection
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
    // Check if we have Samsung Health data source info
    final stepsBySource = data['stepsBySource'] as Map<String, dynamic>?;
    final dataSource = stepsBySource?['dataSource'] ?? 'Unknown';
    debugPrint('Samsung Health Integration: Data from $dataSource');
    
    // Check if data is valid (not all zeros which indicates no real data)
    bool hasValidData = (data['steps'] ?? 0) > 0 || 
                       (data['calories'] ?? 0) > 0 || 
                       (data['heartRate'] ?? 0) > 0 || 
                       (data['sleep'] ?? 0) > 0 ||
                       (data['water'] ?? 0) > 0 ||
                       (data['workouts'] ?? 0) > 0;
    
    // Log Samsung Health prioritization for key metrics
    if (stepsBySource != null) {
      debugPrint('Samsung Health Steps: ${stepsBySource['samsung']} (priority)');
      debugPrint('Google Fit Steps: ${stepsBySource['googleFit']} (fallback)');
      debugPrint('Using: ${stepsBySource['dataSource']}');
    }
    
    // Only update if we have valid data, otherwise keep existing values
    if (hasValidData) {
      // Update today's data with Samsung Health prioritization
      _todaySteps = (data['steps'] != null && data['steps'] > 0) ? data['steps'].toDouble() : _todaySteps;
      _todayCaloriesBurned = (data['calories'] != null && data['calories'] > 0) ? data['calories'].toDouble() : _todayCaloriesBurned;
      _todayHeartRate = (data['heartRate'] != null && data['heartRate'] > 0) ? data['heartRate'].toDouble() : _todayHeartRate;
      _todaySleep = (data['sleep'] != null && data['sleep'] > 0) ? data['sleep'].toDouble() : _todaySleep;
      _todayDistance = (data['distance'] != null && data['distance'] > 0) ? data['distance'].toDouble() : _todayDistance;
      _todayWater = (data['water'] != null && data['water'] > 0) ? data['water'] : _todayWater;
      _todayWorkouts = (data['workouts'] != null && data['workouts'] > 0) ? data['workouts'] : _todayWorkouts;
      
      // New Samsung Health metrics
      _todayWeight = (data['weight'] != null && data['weight'] > 0) ? data['weight'].toDouble() : _todayWeight;
      _todayBloodOxygen = (data['bloodOxygen'] != null && data['bloodOxygen'] > 0) ? data['bloodOxygen'] : _todayBloodOxygen;
      _todayExerciseMinutes = (data['exerciseMinutes'] != null && data['exerciseMinutes'] > 0) ? data['exerciseMinutes'] : _todayExerciseMinutes;
      
      // Blood pressure handling
      if (data['bloodPressure'] is Map) {
        final bp = data['bloodPressure'] as Map<String, dynamic>;
        _todayBloodPressure = {
          'systolic': (bp['systolic'] != null && bp['systolic'] > 0) ? bp['systolic'] : _todayBloodPressure['systolic']!,
          'diastolic': (bp['diastolic'] != null && bp['diastolic'] > 0) ? bp['diastolic'] : _todayBloodPressure['diastolic']!,
        };
      }
      
      debugPrint('Samsung Health Metrics Updated:');
      debugPrint('  Steps: $_todaySteps (from $dataSource)');
      debugPrint('  Heart Rate: $_todayHeartRate bpm');
      debugPrint('  Calories: $_todayCaloriesBurned kcal');
      debugPrint('  Sleep: $_todaySleep hours');
      debugPrint('  Distance: $_todayDistance km');
      debugPrint('  Water: $_todayWater ml');
      debugPrint('  Weight: $_todayWeight kg');
      debugPrint('  Blood Oxygen: $_todayBloodOxygen%');
      debugPrint('  Blood Pressure: ${_todayBloodPressure['systolic']}/${_todayBloodPressure['diastolic']}');
      debugPrint('  Workouts: $_todayWorkouts ($_todayExerciseMinutes min)');
    } else {
      // No valid data from health source, keep existing values
      debugPrint('No valid health data received, keeping existing values');
      debugPrint('Current values - Steps: $_todaySteps, Calories: $_todayCaloriesBurned, HR: $_todayHeartRate, Sleep: $_todaySleep');
    }
    
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
    
    // Automatically sync with Supabase
    saveHealthDataToSupabase();
    
    notifyListeners();
  }
  
  // Method to manually sync data
  Future<void> connectToHealthSource(HealthDataSource source) async {
    _currentDataSource = source;
    
    // Save the connection state
    if (_prefs != null) {
      String sourceString = '';
      switch (source) {
        case HealthDataSource.healthConnect:
          sourceString = 'healthConnect';
          break;
        case HealthDataSource.healthKit:
          sourceString = 'healthKit';
          break;
        case HealthDataSource.bluetooth:
          sourceString = 'bluetooth';
          break;
        default:
          sourceString = '';
      }
      if (sourceString.isNotEmpty) {
        await _prefs!.setString('connected_health_source', sourceString);
      }
    }
    
    notifyListeners();
  }
  
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
    
    // Load today's data with demo values as fallback for testing - All Samsung Health metrics
    _todaySteps = _prefs!.getDouble('steps_$todayKey') ?? 5432.0;
    _todayCaloriesBurned = _prefs!.getDouble('calories_burned_$todayKey') ?? 345.0;
    _todayHeartRate = _prefs!.getDouble('heart_rate_$todayKey') ?? 72.0;
    _todaySleep = _prefs!.getDouble('sleep_$todayKey') ?? 7.5;
    _todayDistance = _prefs!.getDouble('distance_$todayKey') ?? 3.2;
    _todayWater = _prefs!.getInt('water_$todayKey') ?? 1800;
    _todayWorkouts = _prefs!.getInt('workouts_$todayKey') ?? 1;
    _todayWeight = _prefs!.getDouble('weight_$todayKey') ?? 70.0;
    _todayBloodOxygen = _prefs!.getInt('blood_oxygen_$todayKey') ?? 98;
    _todayExerciseMinutes = _prefs!.getInt('exercise_minutes_$todayKey') ?? 45;
    _todayBloodPressure = {
      'systolic': _prefs!.getInt('bp_systolic_$todayKey') ?? 120,
      'diastolic': _prefs!.getInt('bp_diastolic_$todayKey') ?? 80,
    };
    
    // Check for saved health source connection
    final connectedSource = _prefs!.getString('connected_health_source');
    if (connectedSource != null) {
      // Restore the connection state
      if (connectedSource == 'healthConnect') {
        _currentDataSource = HealthDataSource.healthConnect;
      } else if (connectedSource == 'healthKit') {
        _currentDataSource = HealthDataSource.healthKit;
      }
      debugPrint('Restored health source connection: $connectedSource');
    }
  }
  
  // Save health data to SharedPreferences and sync to Supabase
  Future<void> _saveHealthData() async {
    if (_prefs == null) return;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Save to SharedPreferences - All Samsung Health metrics
    await _prefs!.setDouble('steps_$todayKey', _todaySteps);
    await _prefs!.setDouble('calories_burned_$todayKey', _todayCaloriesBurned);
    await _prefs!.setDouble('heart_rate_$todayKey', _todayHeartRate);
    await _prefs!.setDouble('sleep_$todayKey', _todaySleep);
    await _prefs!.setDouble('distance_$todayKey', _todayDistance);
    await _prefs!.setInt('water_$todayKey', _todayWater);
    await _prefs!.setInt('workouts_$todayKey', _todayWorkouts);
    await _prefs!.setDouble('weight_$todayKey', _todayWeight);
    await _prefs!.setInt('blood_oxygen_$todayKey', _todayBloodOxygen);
    await _prefs!.setInt('exercise_minutes_$todayKey', _todayExerciseMinutes);
    await _prefs!.setInt('bp_systolic_$todayKey', _todayBloodPressure['systolic']!);
    await _prefs!.setInt('bp_diastolic_$todayKey', _todayBloodPressure['diastolic']!);
    
    // Also save for RealtimeSyncService to pick up
    await _prefs!.setInt('today_steps', _todaySteps.toInt());
    await _prefs!.setInt('today_heart_rate', _todayHeartRate.toInt());
    await _prefs!.setDouble('today_sleep', _todaySleep);
    await _prefs!.setInt('today_calories_burned', _todayCaloriesBurned.toInt());
    await _prefs!.setDouble('today_distance', _todayDistance);
    await _prefs!.setInt('today_water', _todayWater);
    await _prefs!.setDouble('today_weight', _todayWeight);
    await _prefs!.setInt('today_blood_oxygen', _todayBloodOxygen);
    await _prefs!.setInt('today_exercise_minutes', _todayExerciseMinutes);
    
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

    // Check if online
    if (!_isOnline) {
      debugPrint('Offline - data will sync when connection restored');
      return;
    }

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
      
      debugPrint('Health data synced to Supabase successfully');
    } catch (e) {
      debugPrint('Error saving health data to Supabase: $e');
    }
  }
  
  // Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      
      if (wasOffline && _isOnline) {
        debugPrint('Connection restored - syncing data with Supabase');
        // Sync data when coming back online
        saveHealthDataToSupabase();
        loadHealthDataFromSupabase();
      }
    });
    
    // Check initial connectivity
    _connectivity.checkConnectivity().then((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }
  
  // Sync health data on app open - called when user opens the app
  Future<void> syncOnAppOpen() async {
    if (_isOnline && _isInitialized) {
      debugPrint('Syncing health data on app open...');
      await syncWithHealth();
      await saveHealthDataToSupabase();
      debugPrint('Health data sync completed on app open');
    } else {
      debugPrint('Skipping sync: online=$_isOnline, initialized=$_isInitialized');
    }
  }
  
  // Ensure data is synced when app is paused
  Future<void> syncOnPause() async {
    if (_isOnline) {
      await saveHealthDataToSupabase();
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}