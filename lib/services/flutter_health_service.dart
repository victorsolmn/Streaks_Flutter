import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Flutter Health Service following the official health plugin recommendations
/// Supports both iOS (HealthKit) and Android (Health Connect) seamlessly
/// Compatible with all major smartwatches: Apple Watch, Samsung Galaxy Watch, Google Pixel Watch, Fitbit, Garmin, etc.
class FlutterHealthService {
  static final FlutterHealthService _instance = FlutterHealthService._internal();
  factory FlutterHealthService() => _instance;
  FlutterHealthService._internal();

  final Health _health = Health();
  bool _isInitialized = false;
  
  // Define all health data types we want to access
  static const List<HealthDataType> _healthTypes = [
    // Basic activity data
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    // Note: TOTAL_CALORIES_BURNED is not supported on iOS
    HealthDataType.DISTANCE_WALKING_RUNNING,
    
    // Heart rate data  
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    
    // Sleep data
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    
    // Health metrics
    HealthDataType.WEIGHT,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    
    // Hydration
    HealthDataType.WATER,
    
    // Exercise sessions
    HealthDataType.WORKOUT,
  ];

  // Define permissions (read permissions for all data types)
  static List<HealthDataAccess> get _permissions => _healthTypes
      .map((type) => HealthDataAccess.READ)
      .toList();

  /// Initialize the health service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🔧 Initializing Flutter Health Service...');
        print('📱 Platform: ${Platform.isIOS ? "iOS (HealthKit)" : "Android (Health Connect)"}');
        print('📊 Requesting access to ${_healthTypes.length} health data types');
      }

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Flutter Health Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Flutter Health Service: $e');
      }
      rethrow;
    }
  }

  /// Request permissions for all health data types
  Future<bool> requestPermissions() async {
    try {
      if (kDebugMode) {
        print('🔐 Requesting health permissions...');
        if (Platform.isIOS) {
          print('📱 iOS: Requesting HealthKit permissions');
        } else if (Platform.isAndroid) {
          print('📱 Android: Requesting Health Connect permissions');
          print('🔧 Note: Make sure Health Connect app is installed from Play Store');
        }
      }

      // Request authorization for all health data types
      final bool requested = await _health.requestAuthorization(
        _healthTypes,
        permissions: _permissions,
      );

      if (kDebugMode) {
        if (requested) {
          print('✅ Health permissions requested successfully');
        } else {
          print('❌ Health permission request failed or was denied');
          if (Platform.isAndroid) {
            print('💡 Troubleshooting:');
            print('   • Install Health Connect from Google Play Store');
            print('   • Make sure device runs Android 14+ (API 34+) or has Health Connect installed');
            print('   • Check if Health Connect is enabled in device settings');
          }
        }
      }

      return requested;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting health permissions: $e');
        if (Platform.isAndroid && e.toString().contains('No Activity found')) {
          print('💡 Health Connect app not found or not properly configured');
          print('📲 Install Health Connect from Google Play Store:');
          print('   https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata');
        }
      }
      return false;
    }
  }

  /// Check if permissions are granted for specific data types
  Future<bool> hasPermissions([List<HealthDataType>? types]) async {
    try {
      final typesToCheck = types ?? _healthTypes;
      
      for (final type in typesToCheck) {
        final status = await _health.hasPermissions([type]);
        if (status != true) {
          if (kDebugMode) {
            print('⚠️ Missing permission for: $type');
          }
          return false;
        }
      }
      
      if (kDebugMode) {
        print('✅ All required permissions are granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking permissions: $e');
      }
      return false;
    }
  }

  /// Get health data for the last 24 hours
  Future<Map<String, dynamic>> getTodaysHealthData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      
      if (kDebugMode) {
        print('📊 Fetching health data from $yesterday to $now');
      }

      final healthData = await _health.getHealthDataFromTypes(
        types: _healthTypes,
        startTime: yesterday,
        endTime: now,
      );

      if (kDebugMode) {
        print('📈 Retrieved ${healthData.length} health data points');
      }

      return _processHealthData(healthData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching health data: $e');
      }
      return _getEmptyHealthData();
    }
  }

  /// Get steps count for today
  Future<int> getTodaysSteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      int totalSteps = 0;
      for (final data in healthData) {
        if (data.type == HealthDataType.STEPS) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      if (kDebugMode) {
        print('👟 Today\'s steps: $totalSteps from ${healthData.length} data points');
      }

      return totalSteps;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching steps: $e');
      }
      return 0;
    }
  }

  /// Get heart rate data
  Future<Map<String, dynamic>> getHeartRateData() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE, HealthDataType.RESTING_HEART_RATE],
        startTime: yesterday,
        endTime: now,
      );

      int latestHeartRate = 0;
      int restingHeartRate = 0;
      String heartRateSource = 'Unknown';

      for (final data in heartRateData) {
        final value = (data.value as NumericHealthValue).numericValue.toInt();
        
        if (data.type == HealthDataType.HEART_RATE) {
          latestHeartRate = value;
          heartRateSource = data.sourceName;
        } else if (data.type == HealthDataType.RESTING_HEART_RATE) {
          restingHeartRate = value;
        }
      }

      if (kDebugMode) {
        print('❤️ Heart Rate - Latest: $latestHeartRate bpm, Resting: $restingHeartRate bpm');
        print('📱 Source: $heartRateSource');
      }

      return {
        'heartRate': latestHeartRate,
        'restingHeartRate': restingHeartRate,
        'source': heartRateSource,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching heart rate: $e');
      }
      return {
        'heartRate': 0,
        'restingHeartRate': 0,
        'source': 'Error',
      };
    }
  }

  /// Process raw health data into organized format
  Map<String, dynamic> _processHealthData(List<HealthDataPoint> healthData) {
    final Map<String, dynamic> processedData = _getEmptyHealthData();
    
    // Group data by source to prioritize smartwatch data
    final Map<String, List<HealthDataPoint>> dataBySource = {};
    
    for (final dataPoint in healthData) {
      final source = dataPoint.sourceName.toLowerCase();
      dataBySource.putIfAbsent(source, () => []).add(dataPoint);
    }

    if (kDebugMode) {
      print('📊 Data sources found:');
      dataBySource.keys.forEach((source) {
        final count = dataBySource[source]!.length;
        print('  • $source: $count data points');
      });
    }

    // Process each data type
    for (final dataPoint in healthData) {
      final source = dataPoint.sourceName;
      
      switch (dataPoint.type) {
        case HealthDataType.STEPS:
          final steps = (dataPoint.value as NumericHealthValue).numericValue.toInt();
          processedData['steps'] = (processedData['steps'] as int) + steps;
          break;
          
        case HealthDataType.ACTIVE_ENERGY_BURNED:
        case HealthDataType.TOTAL_CALORIES_BURNED:
          final calories = (dataPoint.value as NumericHealthValue).numericValue.toInt();
          processedData['calories'] = (processedData['calories'] as int) + calories;
          break;
          
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          final distance = (dataPoint.value as NumericHealthValue).numericValue;
          processedData['distance'] = (processedData['distance'] as double) + distance;
          break;
          
        case HealthDataType.HEART_RATE:
          final heartRate = (dataPoint.value as NumericHealthValue).numericValue.toInt();
          processedData['heartRate'] = heartRate;
          processedData['heartRateSource'] = source;
          break;
          
        case HealthDataType.RESTING_HEART_RATE:
          final restingHeartRate = (dataPoint.value as NumericHealthValue).numericValue.toInt();
          processedData['restingHeartRate'] = restingHeartRate;
          break;
          
        case HealthDataType.WATER:
          final water = (dataPoint.value as NumericHealthValue).numericValue;
          processedData['water'] = (processedData['water'] as int) + (water * 1000).toInt(); // Convert to ml
          break;
          
        case HealthDataType.WEIGHT:
          final weight = (dataPoint.value as NumericHealthValue).numericValue;
          processedData['weight'] = weight;
          break;
          
        case HealthDataType.SLEEP_ASLEEP:
          final sleepMinutes = dataPoint.dateTo.difference(dataPoint.dateFrom).inMinutes;
          processedData['sleepMinutes'] = (processedData['sleepMinutes'] as int) + sleepMinutes;
          processedData['sleep'] = (processedData['sleepMinutes'] as int) / 60.0;
          break;
          
        default:
          break;
      }
    }

    // Calculate smartwatch compatibility score
    final smartwatchSources = _identifySmartWatchSources(dataBySource.keys.toList());
    processedData['smartwatchSources'] = smartwatchSources;
    processedData['hasSmartWatchData'] = smartwatchSources.isNotEmpty;
    
    if (kDebugMode) {
      print('⌚ Detected smartwatch sources: $smartwatchSources');
      print('📊 Final processed data: ${processedData.keys.join(", ")}');
    }

    processedData['lastSync'] = DateTime.now().toIso8601String();
    return processedData;
  }

  /// Identify smartwatch sources from data sources
  List<String> _identifySmartWatchSources(List<String> sources) {
    final smartwatchSources = <String>[];
    
    for (final source in sources) {
      final lowerSource = source.toLowerCase();
      
      if (lowerSource.contains('apple watch') || 
          lowerSource.contains('watch') && Platform.isIOS) {
        smartwatchSources.add('Apple Watch');
      } else if (lowerSource.contains('samsung') || 
                 lowerSource.contains('galaxy watch') ||
                 lowerSource.contains('shealth')) {
        smartwatchSources.add('Samsung Galaxy Watch');
      } else if (lowerSource.contains('google') || 
                 lowerSource.contains('pixel watch')) {
        smartwatchSources.add('Google Pixel Watch');
      } else if (lowerSource.contains('fitbit')) {
        smartwatchSources.add('Fitbit');
      } else if (lowerSource.contains('garmin')) {
        smartwatchSources.add('Garmin');
      } else if (lowerSource.contains('wear os') || 
                 lowerSource.contains('wearos')) {
        smartwatchSources.add('Wear OS Device');
      }
    }
    
    return smartwatchSources.toSet().toList(); // Remove duplicates
  }

  /// Get empty health data structure
  Map<String, dynamic> _getEmptyHealthData() {
    return {
      'steps': 0,
      'heartRate': 0,
      'restingHeartRate': 0,
      'calories': 0,
      'distance': 0.0,
      'sleep': 0.0,
      'sleepMinutes': 0,
      'water': 0,
      'weight': 0.0,
      'bloodOxygen': 0,
      'bloodPressure': {'systolic': 0, 'diastolic': 0},
      'workouts': 0,
      'exerciseMinutes': 0,
      'smartwatchSources': <String>[],
      'hasSmartWatchData': false,
      'heartRateSource': 'Unknown',
      'lastSync': DateTime.now().toIso8601String(),
    };
  }

  /// Check if Health Connect is available (Android only)
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      if (kDebugMode) {
        print('🔍 Checking Health Connect availability...');
      }
      
      // Try to check permissions first (this shouldn't trigger permission request)
      final hasPermissions = await this.hasPermissions([HealthDataType.STEPS]);
      
      if (kDebugMode) {
        print('📋 Current permissions status: $hasPermissions');
      }
      
      return true; // Health Connect is available for checking
    } catch (e) {
      if (kDebugMode) {
        print('❌ Health Connect availability check failed: $e');
        if (e.toString().contains('No Activity found') || 
            e.toString().contains('health connect')) {
          print('💡 Health Connect app may not be installed');
          print('📲 Install from: https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata');
        }
      }
      return false;
    }
  }

  /// Check if HealthKit is available (iOS only)
  Future<bool> isHealthKitAvailable() async {
    if (!Platform.isIOS) return false;
    
    try {
      final result = await requestPermissions();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKit availability check failed: $e');
      }
      return false;
    }
  }

  /// Get detailed device and platform information
  Map<String, dynamic> getDeviceInfo() {
    return {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'healthSystem': Platform.isIOS ? 'HealthKit' : 'Health Connect',
      'supportedWatches': Platform.isIOS 
        ? ['Apple Watch', 'Compatible third-party devices via HealthKit']
        : ['Samsung Galaxy Watch', 'Google Pixel Watch', 'Wear OS devices', 'Fitbit (via Health Connect)', 'Garmin (via Health Connect)'],
      'requiresInstallation': Platform.isAndroid ? 'Health Connect app' : 'Built-in HealthKit',
    };
  }
}