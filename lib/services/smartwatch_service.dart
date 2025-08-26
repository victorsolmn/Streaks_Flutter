import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:health/health.dart'; // Temporarily disabled for compatibility
import '../models/health_metric_model.dart';

class SmartwatchService {
  static final SmartwatchService _instance = SmartwatchService._internal();
  factory SmartwatchService() => _instance;
  SmartwatchService._internal();

  // final Health _health = Health(); // Temporarily disabled
  Timer? _syncTimer;
  String? _connectedDevice;
  Function(Map<String, dynamic>)? _onDataUpdate;
  
  // Health data types we want to sync (kept for future use)
  // final List<HealthDataType> _healthTypes = [
  //   HealthDataType.STEPS,
  //   HealthDataType.HEART_RATE,
  //   HealthDataType.SLEEP_ASLEEP,
  //   HealthDataType.SLEEP_AWAKE,
  //   HealthDataType.SLEEP_DEEP,
  //   HealthDataType.SLEEP_REM,
  //   HealthDataType.ACTIVE_ENERGY_BURNED,
  //   HealthDataType.DISTANCE_WALKING_RUNNING,
  //   HealthDataType.WORKOUT,
  //   HealthDataType.WATER,
  //   HealthDataType.BLOOD_OXYGEN,
  //   HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  //   HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  //   HealthDataType.BODY_TEMPERATURE,
  //   HealthDataType.WEIGHT,
  //   HealthDataType.HEIGHT,
  // ];

  // Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedDevice = prefs.getString('connected_smartwatch');
    
    if (_connectedDevice != null) {
      await startDataSync();
    }
  }

  // Check if a device is connected
  bool get isDeviceConnected => _connectedDevice != null;
  String? get connectedDevice => _connectedDevice;

  // Connect to a smartwatch
  Future<bool> connectDevice(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_smartwatch', deviceId);
      _connectedDevice = deviceId;
      
      // Request permissions for health data
      // if (deviceId == 'apple_watch' || deviceId == 'google_fit') {
      //   bool requested = await _health.requestAuthorization(_healthTypes);
      //   if (!requested) {
      //     return false;
      //   }
      // }
      
      // Start syncing data
      await startDataSync();
      return true;
    } catch (e) {
      debugPrint('Error connecting device: $e');
      return false;
    }
  }

  // Disconnect device
  Future<void> disconnectDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_smartwatch');
    _connectedDevice = null;
    stopDataSync();
  }

  // Start automatic data sync
  Future<void> startDataSync() async {
    // Stop any existing timer
    stopDataSync();
    
    // Fetch initial data
    await fetchHealthData();
    
    // Set up periodic sync (every 5 minutes)
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      await fetchHealthData();
    });
  }

  // Stop data sync
  void stopDataSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Set callback for data updates
  void setDataUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onDataUpdate = callback;
  }

  // Fetch health data from connected device
  Future<Map<String, dynamic>> fetchHealthData() async {
    Map<String, dynamic> healthData = {
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

    if (_connectedDevice == null) {
      _onDataUpdate?.call(healthData);
      return healthData;
    }

    try {
      // Get data from the last 24 hours
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      // For now, use simulated data for all devices
      // Real Health package integration will be added when compatibility is resolved
      healthData = _simulateDeviceData(_connectedDevice!);

      // Notify listeners about the update
      _onDataUpdate?.call(healthData);
      
    } catch (e) {
      debugPrint('Error fetching health data: $e');
    }

    return healthData;
  }

  // Simulate data for devices that don't have direct API access yet
  Map<String, dynamic> _simulateDeviceData(String deviceId) {
    // In production, these would connect to respective device APIs
    // For now, return realistic sample data based on device type
    
    final baseData = {
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

    // Return base data (0 values) for now
    // In production, each device would have its own SDK integration
    switch (deviceId) {
      case 'samsung_watch':
        // Would integrate with Samsung Health SDK
        return baseData;
      case 'garmin':
        // Would integrate with Garmin Connect IQ
        return baseData;
      case 'fitbit':
        // Would integrate with Fitbit Web API
        return baseData;
      case 'mi_band':
        // Would integrate with Mi Fit SDK
        return baseData;
      case 'amazfit':
        // Would integrate with Zepp SDK
        return baseData;
      case 'huawei':
        // Would integrate with Huawei Health Kit
        return baseData;
      default:
        return baseData;
    }
  }

  // Manual sync trigger
  Future<void> syncNow() async {
    await fetchHealthData();
  }

  // Clean up
  void dispose() {
    stopDataSync();
  }
}