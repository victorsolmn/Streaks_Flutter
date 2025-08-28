import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_smartwatch_service.dart';
import '../models/health_metric_model.dart';

enum HealthDataSource {
  healthKit,        // iOS - Apple Health
  healthConnect,    // Android - Health Connect / Samsung Health
  bluetooth,        // Direct BLE connection
  unavailable       // No source available
}

class UnifiedHealthService {
  static final UnifiedHealthService _instance = UnifiedHealthService._internal();
  factory UnifiedHealthService() => _instance;
  UnifiedHealthService._internal();

  // Health package instance (works for both HealthKit and Health Connect)
  final Health _health = Health();
  
  // Bluetooth service for fallback
  final BluetoothSmartwatchService _bluetoothService = BluetoothSmartwatchService();
  
  // Current data source
  HealthDataSource _currentSource = HealthDataSource.unavailable;
  HealthDataSource get currentSource => _currentSource;
  
  // Data update callback
  Function(Map<String, dynamic>)? _onDataUpdate;
  
  // Sync timer
  Timer? _syncTimer;
  
  // Health data types we want to read
  final List<HealthDataType> _healthTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.WATER,
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.WORKOUT,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.BASAL_ENERGY_BURNED,
  ];
  
  // Initialize the service
  Future<void> initialize() async {
    debugPrint('UnifiedHealthService: Initializing...');
    
    // Initialize Bluetooth service
    await _bluetoothService.initialize();
    
    // Determine best available data source
    await _determineBestDataSource();
    
    // Set up data update callback for Bluetooth
    _bluetoothService.setDataUpdateCallback((data) {
      if (_currentSource == HealthDataSource.bluetooth) {
        _onDataUpdate?.call(data);
      }
    });
  }
  
  // Determine the best available data source
  Future<void> _determineBestDataSource() async {
    debugPrint('UnifiedHealthService: Determining best data source...');
    
    // Try platform-specific health APIs first
    if (Platform.isIOS) {
      bool available = await _checkHealthKitAvailability();
      if (available) {
        _currentSource = HealthDataSource.healthKit;
        debugPrint('UnifiedHealthService: Using HealthKit as data source');
        return;
      }
    } else if (Platform.isAndroid) {
      bool available = await _checkHealthConnectAvailability();
      if (available) {
        _currentSource = HealthDataSource.healthConnect;
        debugPrint('UnifiedHealthService: Using Health Connect as data source');
        return;
      }
    }
    
    // Check if Bluetooth device is already connected
    if (_bluetoothService.isDeviceConnected) {
      _currentSource = HealthDataSource.bluetooth;
      debugPrint('UnifiedHealthService: Using Bluetooth as data source');
      return;
    }
    
    // No source available yet
    _currentSource = HealthDataSource.unavailable;
    debugPrint('UnifiedHealthService: No data source available');
  }
  
  // Check HealthKit availability (iOS)
  Future<bool> _checkHealthKitAvailability() async {
    try {
      // Check if we have permissions
      bool? hasPermissions = await _health.hasPermissions(
        _healthTypes,
        permissions: [HealthDataAccess.READ],
      );
      
      if (hasPermissions == true) {
        return true;
      }
      
      // Try to request permissions
      bool authorized = await requestHealthPermissions();
      return authorized;
    } catch (e) {
      debugPrint('UnifiedHealthService: HealthKit check failed: $e');
      return false;
    }
  }
  
  // Check Health Connect availability (Android)
  Future<bool> _checkHealthConnectAvailability() async {
    try {
      debugPrint('UnifiedHealthService: Configuring Health Connect...');
      
      // CRITICAL: Configure Health Connect first - this is what makes the app appear in Health Connect
      await _health.configure();
      
      // Try to get Health Connect SDK status
      try {
        final status = await _health.getHealthConnectSdkStatus();
        debugPrint('UnifiedHealthService: Health Connect SDK status: $status');
        
        if (status == HealthConnectSdkStatus.sdkAvailable) {
          // Check if we have permissions
          bool? hasPermissions = await _health.hasPermissions(
            _healthTypes,
            permissions: [HealthDataAccess.READ],
          );
          debugPrint('UnifiedHealthService: Has permissions: $hasPermissions');
          
          if (hasPermissions == true) {
            return true;
          }
          
          // We don't have permissions - this is expected on first run
          // Don't auto-request here, let the UI handle it
          return false;
        } else if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          debugPrint('UnifiedHealthService: Health Connect needs update');
          // Health Connect is installed but needs update
          return false;
        } else {
          debugPrint('UnifiedHealthService: Health Connect SDK unavailable: $status');
          return false;
        }
      } catch (e) {
        debugPrint('UnifiedHealthService: SDK status check failed: $e');
        // If SDK status check fails, we still configured Health Connect
        // The app should now appear in Health Connect for manual permission grant
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('UnifiedHealthService: Health Connect configuration failed: $e');
      return false;
    }
  }
  
  // Request health permissions
  Future<bool> requestHealthPermissions() async {
    try {
      if (Platform.isIOS) {
        // Request HealthKit permissions
        bool authorized = await _health.requestAuthorization(
          _healthTypes,
          permissions: [HealthDataAccess.READ],
        );
        
        if (authorized) {
          _currentSource = HealthDataSource.healthKit;
        }
        return authorized;
      } else if (Platform.isAndroid) {
        debugPrint('UnifiedHealthService: Requesting Android health permissions...');
        
        // First ensure Health Connect is configured
        await _health.configure();
        
        // Request activity recognition permission for steps
        var status = await Permission.activityRecognition.request();
        if (status.isDenied) {
          debugPrint('UnifiedHealthService: Activity recognition permission denied');
        }
        
        // Request Health Connect permissions - this should open Health Connect app
        debugPrint('UnifiedHealthService: Requesting Health Connect authorization...');
        bool authorized = await _health.requestAuthorization(
          _healthTypes,
          permissions: [HealthDataAccess.READ],
        );
        
        debugPrint('UnifiedHealthService: Health Connect authorization result: $authorized');
        
        if (authorized) {
          _currentSource = HealthDataSource.healthConnect;
        }
        return authorized;
      }
      return false;
    } catch (e) {
      debugPrint('UnifiedHealthService: Permission request failed: $e');
      return false;
    }
  }
  
  // Fetch health data based on current source
  Future<Map<String, dynamic>> fetchHealthData() async {
    switch (_currentSource) {
      case HealthDataSource.healthKit:
      case HealthDataSource.healthConnect:
        return await _fetchFromHealthAPI();
      case HealthDataSource.bluetooth:
        return await _bluetoothService.fetchHealthData();
      case HealthDataSource.unavailable:
        // Try to determine source again
        await _determineBestDataSource();
        if (_currentSource != HealthDataSource.unavailable) {
          return await fetchHealthData();
        }
        return _getEmptyHealthData();
    }
  }
  
  // Fetch data from Health API (HealthKit or Health Connect)
  Future<Map<String, dynamic>> _fetchFromHealthAPI() async {
    Map<String, dynamic> healthData = _getEmptyHealthData();
    
    try {
      // Get data from the last 24 hours
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // Fetch different health data types
      
      // Steps
      try {
        List<HealthDataPoint> stepsData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: midnight,
          endTime: now,
        );
        
        int totalSteps = 0;
        for (var point in stepsData) {
          if (point.value is NumericHealthValue) {
            totalSteps += (point.value as NumericHealthValue).numericValue.toInt();
          }
        }
        healthData['steps'] = totalSteps;
        debugPrint('UnifiedHealthService: Steps today: $totalSteps');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching steps: $e');
      }
      
      // Heart Rate (latest reading)
      try {
        List<HealthDataPoint> heartRateData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: now.subtract(Duration(hours: 1)),
          endTime: now,
        );
        
        if (heartRateData.isNotEmpty) {
          // Get the most recent heart rate
          heartRateData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (heartRateData.first.value is NumericHealthValue) {
            healthData['heartRate'] = (heartRateData.first.value as NumericHealthValue).numericValue.toInt();
            debugPrint('UnifiedHealthService: Latest heart rate: ${healthData['heartRate']} bpm');
          }
        }
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching heart rate: $e');
      }
      
      // Calories burned
      try {
        List<HealthDataPoint> caloriesData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.ACTIVE_ENERGY_BURNED],
          startTime: midnight,
          endTime: now,
        );
        
        double totalCalories = 0;
        for (var point in caloriesData) {
          if (point.value is NumericHealthValue) {
            totalCalories += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
        
        // Also add basal calories if available
        try {
          List<HealthDataPoint> basalData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.BASAL_ENERGY_BURNED],
            startTime: midnight,
            endTime: now,
          );
          
          for (var point in basalData) {
            if (point.value is NumericHealthValue) {
              totalCalories += (point.value as NumericHealthValue).numericValue.toDouble();
            }
          }
        } catch (e) {
          // Basal energy might not be available on all platforms
        }
        
        healthData['calories'] = totalCalories.toInt();
        debugPrint('UnifiedHealthService: Calories burned: ${healthData['calories']}');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching calories: $e');
      }
      
      // Distance
      try {
        List<HealthDataPoint> distanceData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.DISTANCE_WALKING_RUNNING],
          startTime: midnight,
          endTime: now,
        );
        
        double totalDistance = 0;
        for (var point in distanceData) {
          if (point.value is NumericHealthValue) {
            // Convert meters to kilometers
            totalDistance += (point.value as NumericHealthValue).numericValue.toDouble() / 1000;
          }
        }
        healthData['distance'] = totalDistance;
        debugPrint('UnifiedHealthService: Distance: ${totalDistance.toStringAsFixed(2)} km');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching distance: $e');
      }
      
      // Sleep
      try {
        List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
          types: [
            HealthDataType.SLEEP_ASLEEP,
            HealthDataType.SLEEP_DEEP,
            HealthDataType.SLEEP_REM,
          ],
          startTime: now.subtract(Duration(hours: 24)),
          endTime: now,
        );
        
        double totalSleepMinutes = 0;
        for (var point in sleepData) {
          if (point.value is NumericHealthValue) {
            totalSleepMinutes += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
        healthData['sleep'] = totalSleepMinutes / 60; // Convert to hours
        debugPrint('UnifiedHealthService: Sleep: ${(totalSleepMinutes / 60).toStringAsFixed(1)} hours');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching sleep: $e');
      }
      
      // Water intake
      try {
        List<HealthDataPoint> waterData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WATER],
          startTime: midnight,
          endTime: now,
        );
        
        double totalWater = 0;
        for (var point in waterData) {
          if (point.value is NumericHealthValue) {
            // Convert ml to glasses (250ml per glass)
            totalWater += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
        healthData['water'] = (totalWater / 250).round(); // Convert to glasses
        debugPrint('UnifiedHealthService: Water: ${healthData['water']} glasses');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching water: $e');
      }
      
      // Weight (latest)
      try {
        List<HealthDataPoint> weightData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WEIGHT],
          startTime: now.subtract(Duration(days: 30)),
          endTime: now,
        );
        
        if (weightData.isNotEmpty) {
          weightData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (weightData.first.value is NumericHealthValue) {
            healthData['weight'] = (weightData.first.value as NumericHealthValue).numericValue.toDouble();
            debugPrint('UnifiedHealthService: Latest weight: ${healthData['weight']} kg');
          }
        }
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching weight: $e');
      }
      
      // Blood oxygen (latest)
      try {
        List<HealthDataPoint> oxygenData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.BLOOD_OXYGEN],
          startTime: now.subtract(Duration(hours: 24)),
          endTime: now,
        );
        
        if (oxygenData.isNotEmpty) {
          oxygenData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          if (oxygenData.first.value is NumericHealthValue) {
            healthData['bloodOxygen'] = (oxygenData.first.value as NumericHealthValue).numericValue.toInt();
            debugPrint('UnifiedHealthService: Blood oxygen: ${healthData['bloodOxygen']}%');
          }
        }
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching blood oxygen: $e');
      }
      
      // Blood pressure (latest)
      try {
        List<HealthDataPoint> systolicData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
          startTime: now.subtract(Duration(days: 7)),
          endTime: now,
        );
        
        List<HealthDataPoint> diastolicData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
          startTime: now.subtract(Duration(days: 7)),
          endTime: now,
        );
        
        if (systolicData.isNotEmpty && diastolicData.isNotEmpty) {
          systolicData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          diastolicData.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
          
          if (systolicData.first.value is NumericHealthValue && 
              diastolicData.first.value is NumericHealthValue) {
            healthData['bloodPressure'] = {
              'systolic': (systolicData.first.value as NumericHealthValue).numericValue.toInt(),
              'diastolic': (diastolicData.first.value as NumericHealthValue).numericValue.toInt(),
            };
            debugPrint('UnifiedHealthService: Blood pressure: ${healthData['bloodPressure']['systolic']}/${healthData['bloodPressure']['diastolic']}');
          }
        }
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching blood pressure: $e');
      }
      
      // Exercise time / Active minutes
      try {
        List<HealthDataPoint> exerciseData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.EXERCISE_TIME],
          startTime: midnight,
          endTime: now,
        );
        
        double totalMinutes = 0;
        for (var point in exerciseData) {
          if (point.value is NumericHealthValue) {
            totalMinutes += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
        healthData['activeMinutes'] = totalMinutes.toInt();
        debugPrint('UnifiedHealthService: Active minutes: ${healthData['activeMinutes']}');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching exercise time: $e');
      }
      
      // Workouts count
      try {
        List<HealthDataPoint> workoutData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WORKOUT],
          startTime: midnight,
          endTime: now,
        );
        
        healthData['workouts'] = workoutData.length;
        debugPrint('UnifiedHealthService: Workouts today: ${healthData['workouts']}');
      } catch (e) {
        debugPrint('UnifiedHealthService: Error fetching workouts: $e');
      }
      
    } catch (e) {
      debugPrint('UnifiedHealthService: Error fetching health data from API: $e');
    }
    
    // Notify listeners
    _onDataUpdate?.call(healthData);
    
    return healthData;
  }
  
  // Get empty health data structure
  Map<String, dynamic> _getEmptyHealthData() {
    return {
      'steps': 0,
      'heartRate': 0,
      'calories': 0,
      'sleep': 0.0,
      'distance': 0.0,
      'water': 0,
      'workouts': 0,
      'weight': 0.0,
      'bloodOxygen': 0,
      'bloodPressure': {'systolic': 0, 'diastolic': 0},
      'activeMinutes': 0,
    };
  }
  
  // Scan for Bluetooth devices (fallback option)
  Future<List<Map<String, dynamic>>> scanForBluetoothDevices() async {
    return await _bluetoothService.scanForDevices();
  }
  
  // Connect to Bluetooth device
  Future<bool> connectBluetoothDevice(Map<String, dynamic> deviceInfo) async {
    bool connected = await _bluetoothService.connectDevice(deviceInfo);
    if (connected) {
      _currentSource = HealthDataSource.bluetooth;
    }
    return connected;
  }
  
  // Disconnect Bluetooth device
  Future<void> disconnectBluetoothDevice() async {
    await _bluetoothService.disconnectDevice();
    // Re-determine best source
    await _determineBestDataSource();
  }
  
  // Start automatic data sync
  Future<void> startDataSync() async {
    // Stop any existing timer
    stopDataSync();
    
    // Fetch initial data
    await fetchHealthData();
    
    // Set up periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await fetchHealthData();
    });
    
    // Also start Bluetooth sync if that's the source
    if (_currentSource == HealthDataSource.bluetooth) {
      await _bluetoothService.startDataSync();
    }
  }
  
  // Stop data sync
  void stopDataSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _bluetoothService.stopDataSync();
  }
  
  // Set callback for data updates
  void setDataUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onDataUpdate = callback;
    // Also set for Bluetooth service
    _bluetoothService.setDataUpdateCallback((data) {
      if (_currentSource == HealthDataSource.bluetooth) {
        callback(data);
      }
    });
  }
  
  // Check if any source is available
  bool get isDataSourceAvailable => _currentSource != HealthDataSource.unavailable;
  
  // Check if Bluetooth device is connected
  bool get isBluetoothDeviceConnected => _bluetoothService.isDeviceConnected;
  
  // Get connected device info (if using Bluetooth)
  Map<String, dynamic>? getConnectedDeviceInfo() {
    if (_currentSource == HealthDataSource.bluetooth) {
      return _bluetoothService.getConnectedDeviceInfo();
    }
    return null;
  }
  
  // Get data source info
  Map<String, String> getDataSourceInfo() {
    switch (_currentSource) {
      case HealthDataSource.healthKit:
        return {
          'source': 'Apple Health',
          'icon': '🍎',
          'description': 'Syncing with Apple Health'
        };
      case HealthDataSource.healthConnect:
        return {
          'source': 'Health Connect',
          'icon': '🤖',
          'description': 'Syncing with Samsung Health'
        };
      case HealthDataSource.bluetooth:
        var deviceInfo = _bluetoothService.getConnectedDeviceInfo();
        return {
          'source': deviceInfo?['name'] ?? 'Bluetooth Device',
          'icon': '⌚',
          'description': 'Connected via Bluetooth'
        };
      case HealthDataSource.unavailable:
        return {
          'source': 'No Source',
          'icon': '❌',
          'description': 'Connect a device to sync'
        };
    }
  }
  
  // Manual sync trigger
  Future<void> syncNow() async {
    await fetchHealthData();
  }
  
  // Clean up resources
  void dispose() {
    stopDataSync();
    _bluetoothService.dispose();
  }
}