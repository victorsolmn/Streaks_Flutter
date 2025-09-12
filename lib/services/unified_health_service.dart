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

enum HealthConnectionError {
  none,
  healthConnectNotInstalled,
  healthConnectNeedsUpdate,
  permissionsDenied,
  configurationFailed,
  dataFetchFailed,
  unknown
}

class HealthConnectionResult {
  final bool success;
  final HealthConnectionError error;
  final String? errorMessage;
  final String? debugInfo;
  
  HealthConnectionResult({
    required this.success,
    this.error = HealthConnectionError.none,
    this.errorMessage,
    this.debugInfo,
  });
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
  
  // Track initialization
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Data update callback
  Function(Map<String, dynamic>)? _onDataUpdate;
  
  // Sync timer
  Timer? _syncTimer;
  
  // Debug logs
  final List<String> _debugLogs = [];
  List<String> get debugLogs => _debugLogs;
  
  // Health data types we want to read - using only basic types for better compatibility
  final List<HealthDataType> _healthTypes = Platform.isAndroid ? [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WORKOUT,
  ] : [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WORKOUT,
  ];
  
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    debugPrint('HealthService: $message');
    _debugLogs.add(logMessage);
    if (_debugLogs.length > 100) {
      _debugLogs.removeAt(0);
    }
  }
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      _log('Already initialized');
      return;
    }
    
    _log('Starting initialization...');
    
    try {
      // Initialize Bluetooth service
      await _bluetoothService.initialize();
      _log('Bluetooth service initialized');
      
      // Configure health services based on platform
      if (Platform.isAndroid) {
        _log('Android detected - configuring Health Connect...');
        try {
          await _health.configure();
          _log('Health Connect configured successfully');
        } catch (e) {
          _log('ERROR: Health Connect configuration failed: $e');
        }
      } else if (Platform.isIOS) {
        _log('iOS detected - HealthKit ready');
      }
      
      // Set up data update callback for Bluetooth
      _bluetoothService.setDataUpdateCallback((data) {
        if (_currentSource == HealthDataSource.bluetooth) {
          _onDataUpdate?.call(data);
        }
      });
      
      _isInitialized = true;
      _log('Initialization complete');
      
      // Determine best available data source
      await _determineBestDataSource();
    } catch (e) {
      _log('ERROR: Initialization failed: $e');
      _isInitialized = false;
    }
  }
  
  // Determine the best available data source
  Future<void> _determineBestDataSource() async {
    _log('Determining best data source...');
    
    // Try platform-specific health APIs first
    if (Platform.isIOS) {
      bool available = await _checkHealthKitAvailability();
      if (available) {
        _currentSource = HealthDataSource.healthKit;
        _log('Using HealthKit as data source');
        return;
      }
    } else if (Platform.isAndroid) {
      bool available = await _checkHealthConnectAvailability();
      if (available) {
        _currentSource = HealthDataSource.healthConnect;
        _log('Using Health Connect as data source');
        return;
      }
    }
    
    // Check if Bluetooth device is already connected
    if (_bluetoothService.isDeviceConnected) {
      _currentSource = HealthDataSource.bluetooth;
      _log('Using Bluetooth as data source');
      return;
    }
    
    // No source available yet
    _currentSource = HealthDataSource.unavailable;
    _log('No data source available');
  }
  
  // Check HealthKit availability (iOS)
  Future<bool> _checkHealthKitAvailability() async {
    try {
      _log('Checking HealthKit availability...');
      
      // Create permissions array matching health types length
      final permissions = List<HealthDataAccess>.filled(
        _healthTypes.length, 
        HealthDataAccess.READ,
      );
      
      // Check if we have permissions
      bool? hasPermissions = await _health.hasPermissions(
        _healthTypes,
        permissions: permissions,
      );
      
      _log('HealthKit permissions status: $hasPermissions');
      
      return hasPermissions == true;
    } catch (e) {
      _log('ERROR: HealthKit check failed: $e');
      return false;
    }
  }
  
  // Check Health Connect availability (Android)
  Future<bool> _checkHealthConnectAvailability() async {
    try {
      _log('Checking Health Connect availability...');
      
      // Try to get Health Connect SDK status
      try {
        final status = await _health.getHealthConnectSdkStatus();
        _log('Health Connect SDK status: $status');
        
        if (status == HealthConnectSdkStatus.sdkAvailable) {
          // Create permissions array matching health types length
          final permissions = List<HealthDataAccess>.filled(
            _healthTypes.length, 
            HealthDataAccess.READ,
          );
          
          // Check if we have permissions
          bool? hasPermissions = await _health.hasPermissions(
            _healthTypes,
            permissions: permissions,
          );
          _log('Health Connect permissions status: $hasPermissions');
          
          return hasPermissions == true;
        } else {
          _log('Health Connect not available: $status');
          return false;
        }
      } catch (e) {
        _log('ERROR: SDK status check failed: $e');
        return false;
      }
    } catch (e) {
      _log('ERROR: Health Connect check failed: $e');
      return false;
    }
  }
  
  // Request health permissions with detailed error handling
  Future<HealthConnectionResult> requestHealthPermissions() async {
    _log('Starting health permission request...');
    
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        _log('Service not initialized, initializing now...');
        await initialize();
      }
      
      if (Platform.isIOS) {
        _log('Requesting HealthKit permissions...');
        
        // Create a permissions list that matches the length of health types
        final permissions = List<HealthDataAccess>.filled(
          _healthTypes.length, 
          HealthDataAccess.READ,
        );
        
        // Request HealthKit permissions
        bool authorized = await _health.requestAuthorization(
          _healthTypes,
          permissions: permissions,
        );
        
        _log('HealthKit authorization result: $authorized');
        
        if (authorized) {
          _currentSource = HealthDataSource.healthKit;
          return HealthConnectionResult(
            success: true,
            debugInfo: 'HealthKit connected successfully',
          );
        } else {
          return HealthConnectionResult(
            success: false,
            error: HealthConnectionError.permissionsDenied,
            errorMessage: 'HealthKit permissions were denied',
            debugInfo: _debugLogs.join('\n'),
          );
        }
      } else if (Platform.isAndroid) {
        _log('Android platform - checking Health Connect...');
        
        // First check if Health Connect is installed
        try {
          final status = await _health.getHealthConnectSdkStatus();
          _log('Health Connect SDK status: $status');
          
          if (status == HealthConnectSdkStatus.sdkUnavailable) {
            return HealthConnectionResult(
              success: false,
              error: HealthConnectionError.healthConnectNotInstalled,
              errorMessage: 'Health Connect is not installed. Please install it from the Play Store.',
              debugInfo: _debugLogs.join('\n'),
            );
          } else if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
            return HealthConnectionResult(
              success: false,
              error: HealthConnectionError.healthConnectNeedsUpdate,
              errorMessage: 'Health Connect needs to be updated. Please update it from the Play Store.',
              debugInfo: _debugLogs.join('\n'),
            );
          }
        } catch (e) {
          _log('WARNING: Could not check SDK status: $e');
        }
        
        // Request activity recognition permission for steps
        _log('Requesting activity recognition permission...');
        var activityStatus = await Permission.activityRecognition.request();
        _log('Activity recognition permission: $activityStatus');
        
        if (activityStatus.isDenied || activityStatus.isPermanentlyDenied) {
          _log('WARNING: Activity recognition permission denied');
        }
        
        // Configure Health Connect if not already done
        _log('Configuring Health Connect...');
        try {
          await _health.configure();
          _log('Health Connect configured');
        } catch (e) {
          _log('ERROR: Health Connect configuration failed: $e');
          return HealthConnectionResult(
            success: false,
            error: HealthConnectionError.configurationFailed,
            errorMessage: 'Failed to configure Health Connect. Please check if the app is installed.',
            debugInfo: _debugLogs.join('\n'),
          );
        }
        
        // Request Health Connect permissions
        _log('Requesting Health Connect authorization for ${_healthTypes.length} data types...');
        
        bool authorized = false;
        try {
          // Create a permissions list that matches the length of health types
          final permissions = List<HealthDataAccess>.filled(
            _healthTypes.length, 
            HealthDataAccess.READ,
          );
          _log('Created ${permissions.length} permission entries for ${_healthTypes.length} data types');
          
          authorized = await _health.requestAuthorization(
            _healthTypes,
            permissions: permissions,
          );
          _log('Health Connect authorization result: $authorized');
        } catch (e) {
          _log('ERROR: Authorization request failed: $e');
          
          // Try with reduced permissions
          _log('Trying with basic permissions only...');
          try {
            final basicTypes = [HealthDataType.STEPS];
            final basicPermissions = [HealthDataAccess.READ];
            authorized = await _health.requestAuthorization(
              basicTypes,
              permissions: basicPermissions,
            );
            _log('Basic authorization result: $authorized');
          } catch (e2) {
            _log('ERROR: Basic authorization also failed: $e2');
          }
        }
        
        if (authorized) {
          _currentSource = HealthDataSource.healthConnect;
          _log('Successfully connected to Health Connect');
          return HealthConnectionResult(
            success: true,
            debugInfo: 'Health Connect connected successfully',
          );
        } else {
          _log('Health Connect authorization failed or was denied');
          return HealthConnectionResult(
            success: false,
            error: HealthConnectionError.permissionsDenied,
            errorMessage: 'Health Connect permissions were denied. Please grant permissions manually in Settings > Apps > Streaker > Permissions.',
            debugInfo: _debugLogs.join('\n'),
          );
        }
      }
      
      return HealthConnectionResult(
        success: false,
        error: HealthConnectionError.unknown,
        errorMessage: 'Unsupported platform',
        debugInfo: _debugLogs.join('\n'),
      );
    } catch (e) {
      _log('ERROR: Permission request failed with exception: $e');
      return HealthConnectionResult(
        success: false,
        error: HealthConnectionError.unknown,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
        debugInfo: _debugLogs.join('\n'),
      );
    }
  }
  
  // Test health data fetching
  Future<bool> testHealthDataFetch() async {
    _log('Testing health data fetch...');
    
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // Try to fetch just steps as a test
      _log('Attempting to fetch steps data...');
      List<HealthDataPoint> stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: midnight,
        endTime: now,
      );
      
      _log('Successfully fetched ${stepsData.length} step data points');
      
      int totalSteps = 0;
      for (var point in stepsData) {
        if (point.value is NumericHealthValue) {
          totalSteps += (point.value as NumericHealthValue).numericValue.toInt();
        }
      }
      
      _log('Total steps today: $totalSteps');
      return true;
    } catch (e) {
      _log('ERROR: Test fetch failed: $e');
      return false;
    }
  }
  
  // Fetch health data based on current source
  Future<Map<String, dynamic>> fetchHealthData() async {
    _log('Fetching health data from source: $_currentSource');
    
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
        _log('No data source available for fetching');
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
      
      _log('Fetching health data from $midnight to $now');
      
      // Fetch different health data types
      
      // Steps
      try {
        _log('Fetching steps...');
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
        _log('Steps today: $totalSteps');
      } catch (e) {
        _log('ERROR fetching steps: $e');
      }
      
      // Heart Rate (latest reading)
      try {
        _log('Fetching heart rate...');
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
            _log('Latest heart rate: ${healthData['heartRate']} bpm');
          }
        }
      } catch (e) {
        _log('ERROR fetching heart rate: $e');
      }
      
      // Calories burned
      try {
        _log('Fetching calories...');
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
        
        healthData['calories'] = totalCalories.toInt();
        _log('Calories burned: ${healthData['calories']}');
      } catch (e) {
        _log('ERROR fetching calories: $e');
      }
      
      // Distance
      try {
        _log('Fetching distance...');
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
        _log('Distance: ${totalDistance.toStringAsFixed(2)} km');
      } catch (e) {
        _log('ERROR fetching distance: $e');
      }
      
      // Sleep
      try {
        _log('Fetching sleep...');
        List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.SLEEP_ASLEEP],
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
        _log('Sleep: ${(totalSleepMinutes / 60).toStringAsFixed(1)} hours');
      } catch (e) {
        _log('ERROR fetching sleep: $e');
      }
      
      _log('Health data fetch complete');
      return healthData;
    } catch (e) {
      _log('ERROR: Failed to fetch health data: $e');
      return healthData;
    }
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
      'weight': 0.0,
      'bloodOxygen': 0,
      'bloodPressure': {'systolic': 0, 'diastolic': 0},
      'workouts': 0,
      'exerciseMinutes': 0,
      'latestHeartRate': 0,
      'heartRateType': 'none',
      'sleepMinutes': 0,
      'workoutDetails': [],
      'stepDetails': [],
      'sleepDetails': [],
    };
  }
  
  // Check if data source is available
  bool get isDataSourceAvailable => _currentSource != HealthDataSource.unavailable;
  
  // Get data source info
  Map<String, String> getDataSourceInfo() {
    switch (_currentSource) {
      case HealthDataSource.healthKit:
        return {
          'source': 'Apple Health',
          'status': 'Connected',
          'icon': '🍎',
        };
      case HealthDataSource.healthConnect:
        return {
          'source': 'Health Connect',
          'status': 'Connected',
          'icon': '🤖',
        };
      case HealthDataSource.bluetooth:
        final deviceInfo = _bluetoothService.getConnectedDeviceInfo();
        return {
          'source': deviceInfo?['name'] ?? 'Bluetooth Device',
          'status': 'Connected via Bluetooth',
          'icon': '⌚',
        };
      case HealthDataSource.unavailable:
        return {
          'source': 'Not Connected',
          'status': 'No data source',
          'icon': '❌',
        };
    }
  }
  
  // Get connected device info (for Bluetooth)
  Map<String, dynamic>? getConnectedDeviceInfo() {
    if (_currentSource == HealthDataSource.bluetooth) {
      return _bluetoothService.getConnectedDeviceInfo();
    }
    return null;
  }
  
  // Scan for Bluetooth devices
  Future<List<Map<String, dynamic>>> scanForBluetoothDevices() async {
    _log('Scanning for Bluetooth devices...');
    return await _bluetoothService.scanForDevices();
  }
  
  // Connect to Bluetooth device
  Future<bool> connectBluetoothDevice(Map<String, dynamic> deviceInfo) async {
    _log('Connecting to Bluetooth device: ${deviceInfo['name']}');
    bool connected = await _bluetoothService.connectDevice(deviceInfo);
    if (connected) {
      _currentSource = HealthDataSource.bluetooth;
      _log('Bluetooth device connected successfully');
    }
    return connected;
  }
  
  // Disconnect Bluetooth device
  Future<void> disconnectBluetoothDevice() async {
    _log('Disconnecting Bluetooth device...');
    await _bluetoothService.disconnectDevice();
    await _determineBestDataSource();
  }
  
  // Set data update callback
  void setDataUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onDataUpdate = callback;
  }
  
  // Start automatic data sync
  Future<void> startDataSync() async {
    _log('Starting automatic data sync...');
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (isDataSourceAvailable) {
        final data = await fetchHealthData();
        _onDataUpdate?.call(data);
      }
    });
  }
  
  // Stop automatic data sync
  void stopDataSync() {
    _log('Stopping automatic data sync...');
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Sync now
  Future<void> syncNow() async {
    _log('Manual sync triggered...');
    if (isDataSourceAvailable) {
      final data = await fetchHealthData();
      _onDataUpdate?.call(data);
    }
  }
  
  // Clear debug logs
  void clearDebugLogs() {
    _debugLogs.clear();
  }
  
  // Dispose
  void dispose() {
    stopDataSync();
    _bluetoothService.dispose();
  }
}