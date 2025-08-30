import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Native Health Connect service that communicates with the native Android implementation
class NativeHealthConnectService {
  static const MethodChannel _channel = MethodChannel('com.streaker/health_connect');
  static final NativeHealthConnectService _instance = NativeHealthConnectService._internal();
  
  factory NativeHealthConnectService() => _instance;
  NativeHealthConnectService._internal() {
    // Set up method call handler for callbacks from native
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  // Debug logs
  final List<String> _debugLogs = [];
  List<String> get debugLogs => _debugLogs;
  
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    debugPrint('NativeHealthConnect: $message');
    _debugLogs.add(logMessage);
    if (_debugLogs.length > 100) {
      _debugLogs.removeAt(0);
    }
  }
  
  // Handle method calls from native
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    _log('Received callback from native: ${call.method}');
    
    switch (call.method) {
      case 'onPermissionsChecked':
        final Map<dynamic, dynamic> data = call.arguments;
        _log('Permissions checked: $data');
        // You can emit events or update state here
        break;
      default:
        _log('Unknown method call from native: ${call.method}');
    }
    return null;
  }
  
  /// Check if Health Connect is available on the device
  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      _log('Checking Health Connect availability...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('checkAvailability');
      
      final availability = Map<String, dynamic>.from(result);
      _log('Availability result: $availability');
      
      return availability;
    } on PlatformException catch (e) {
      _log('ERROR checking availability: ${e.message}');
      return {
        'available': false,
        'status': 'error',
        'error': e.message,
      };
    }
  }
  
  /// Request Health Connect permissions
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      _log('Requesting Health Connect permissions...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('requestPermissions');
      
      final response = Map<String, dynamic>.from(result);
      _log('Permission request initiated: $response');
      
      // Wait a bit for the permission dialog to complete
      await Future.delayed(Duration(seconds: 2));
      
      // Check the actual permission status
      return await checkPermissions();
    } on PlatformException catch (e) {
      _log('ERROR requesting permissions: ${e.message}');
      return {
        'granted': false,
        'error': e.message,
      };
    }
  }
  
  /// Check current permission status
  Future<Map<String, dynamic>> checkPermissions() async {
    try {
      _log('Checking current permissions...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('checkPermissions');
      
      final permissions = Map<String, dynamic>.from(result);
      _log('Permission status: $permissions');
      
      return permissions;
    } on PlatformException catch (e) {
      _log('ERROR checking permissions: ${e.message}');
      return {
        'granted': false,
        'error': e.message,
      };
    }
  }
  
  /// Read steps data
  Future<int> readSteps() async {
    try {
      _log('Reading steps...');
      final int steps = await _channel.invokeMethod('readSteps');
      _log('Steps read: $steps');
      return steps;
    } on PlatformException catch (e) {
      _log('ERROR reading steps: ${e.message}');
      return 0;
    }
  }
  
  /// Read heart rate data
  Future<int> readHeartRate() async {
    try {
      _log('Reading heart rate...');
      final int heartRate = await _channel.invokeMethod('readHeartRate');
      _log('Heart rate read: $heartRate bpm');
      return heartRate;
    } on PlatformException catch (e) {
      _log('ERROR reading heart rate: ${e.message}');
      return 0;
    }
  }
  
  /// Read calories data
  Future<int> readCalories() async {
    try {
      _log('Reading calories...');
      final int calories = await _channel.invokeMethod('readCalories');
      _log('Calories read: $calories');
      return calories;
    } on PlatformException catch (e) {
      _log('ERROR reading calories: ${e.message}');
      return 0;
    }
  }
  
  /// Read distance data
  Future<double> readDistance() async {
    try {
      _log('Reading distance...');
      final double distance = await _channel.invokeMethod('readDistance');
      _log('Distance read: $distance km');
      return distance;
    } on PlatformException catch (e) {
      _log('ERROR reading distance: ${e.message}');
      return 0.0;
    }
  }
  
  /// Read all health data at once
  Future<Map<String, dynamic>> readAllHealthData() async {
    try {
      _log('Reading all health data...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('readAllData');
      
      final healthData = Map<String, dynamic>.from(result);
      
      // Log data sources
      if (healthData.containsKey('dataSources')) {
        final sources = healthData['dataSources'] as List<dynamic>;
        _log('Data sources: ${sources.join(', ')}');
        
        // Check for Samsung Health/Galaxy Watch
        // Samsung Health uses com.sec.android.app.shealth
        final hasSamsungData = sources.any((source) => 
          source.toString().contains('samsung') || 
          source.toString().contains('shealth') || 
          source.toString().contains('com.sec.android') || 
          source.toString().contains('gear'));
        
        if (hasSamsungData) {
          _log('✅ Samsung Health/Galaxy Watch data detected!');
        } else {
          _log('⚠️ No Samsung Health/Galaxy Watch data found. Sources: $sources');
        }
      }
      
      // Log step details if available
      if (healthData.containsKey('stepDetails')) {
        final stepDetails = healthData['stepDetails'] as List<dynamic>;
        _log('Found ${stepDetails.length} step records');
        for (var detail in stepDetails) {
          _log('  - ${detail['count']} steps from ${detail['source']}');
        }
      }
      
      // Log which data source is being used
      if (healthData.containsKey('stepsBySource')) {
        final stepsBySource = healthData['stepsBySource'] as Map<dynamic, dynamic>;
        _log('Steps by source:');
        _log('  Samsung Health: ${stepsBySource['samsung']} steps');
        _log('  Google Fit: ${stepsBySource['googleFit']} steps');
        _log('  Using: ${stepsBySource['dataSource']}');
      }
      
      _log('Health data summary:');
      _log('  Steps: ${healthData['steps']}');
      _log('  Heart Rate: ${healthData['heartRate']} bpm (${healthData['heartRateType'] ?? 'unknown'})');
      _log('  Calories: ${healthData['calories']} kcal');
      _log('  Distance: ${healthData['distance']} km');
      _log('  Sleep: ${healthData['sleep']} hours');
      _log('Last sync: ${healthData['lastSync']}');
      
      return healthData;
    } on PlatformException catch (e) {
      _log('ERROR reading all health data: ${e.message}');
      return {
        'steps': 0,
        'heartRate': 0,
        'calories': 0,
        'distance': 0.0,
        'sleep': 0.0,
        'water': 0,
        'weight': 0.0,
        'error': e.message,
        'lastSync': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Test the complete Health Connect flow
  Future<Map<String, dynamic>> testHealthConnectFlow() async {
    final testResults = <String, dynamic>{};
    
    try {
      // Step 1: Check availability
      _log('=== Testing Health Connect Flow ===');
      _log('Step 1: Checking availability...');
      final availability = await checkAvailability();
      testResults['availability'] = availability;
      
      if (availability['available'] != true) {
        _log('Health Connect not available: ${availability['status']}');
        testResults['success'] = false;
        testResults['error'] = 'Health Connect not available: ${availability['status']}';
        return testResults;
      }
      
      // Step 2: Check current permissions
      _log('Step 2: Checking current permissions...');
      var permissions = await checkPermissions();
      testResults['initialPermissions'] = permissions;
      
      // Step 3: Request permissions if not granted
      if (permissions['granted'] != true) {
        _log('Step 3: Requesting permissions...');
        permissions = await requestPermissions();
        testResults['permissionRequest'] = permissions;
      }
      
      // Step 4: Try to read data if permissions granted
      if (permissions['granted'] == true) {
        _log('Step 4: Reading health data...');
        final healthData = await readAllHealthData();
        testResults['healthData'] = healthData;
        testResults['success'] = true;
      } else {
        testResults['success'] = false;
        testResults['error'] = 'Permissions not granted';
      }
      
      _log('=== Test Complete ===');
      return testResults;
    } catch (e) {
      _log('ERROR in test flow: $e');
      testResults['success'] = false;
      testResults['error'] = e.toString();
      return testResults;
    }
  }
  
  /// Clear debug logs
  void clearDebugLogs() {
    _debugLogs.clear();
  }
  
  /// Start background sync for hourly health data updates
  Future<Map<String, dynamic>> startBackgroundSync() async {
    try {
      _log('Starting background health sync...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('startBackgroundSync');
      
      final response = Map<String, dynamic>.from(result);
      _log('Background sync response: $response');
      
      return response;
    } on PlatformException catch (e) {
      _log('ERROR starting background sync: ${e.message}');
      return {
        'success': false,
        'error': e.message,
      };
    }
  }
  
  /// Stop background sync
  Future<Map<String, dynamic>> stopBackgroundSync() async {
    try {
      _log('Stopping background health sync...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('stopBackgroundSync');
      
      final response = Map<String, dynamic>.from(result);
      _log('Stop sync response: $response');
      
      return response;
    } on PlatformException catch (e) {
      _log('ERROR stopping background sync: ${e.message}');
      return {
        'success': false,
        'error': e.message,
      };
    }
  }
  
  /// Get information about the last background sync
  Future<Map<String, dynamic>> getLastSyncInfo() async {
    try {
      _log('Getting last sync info...');
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getLastSyncInfo');
      
      final syncInfo = Map<String, dynamic>.from(result);
      _log('Last sync info: $syncInfo');
      
      // Format the time for display
      if (syncInfo['lastSyncTime'] != null && syncInfo['lastSyncTime'] > 0) {
        final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(syncInfo['lastSyncTime'] as int);
        final timeDiff = DateTime.now().difference(lastSyncDate);
        
        String timeAgo;
        if (timeDiff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (timeDiff.inMinutes < 60) {
          timeAgo = '${timeDiff.inMinutes} minutes ago';
        } else if (timeDiff.inHours < 24) {
          timeAgo = '${timeDiff.inHours} hours ago';
        } else {
          timeAgo = '${timeDiff.inDays} days ago';
        }
        
        syncInfo['timeAgo'] = timeAgo;
        syncInfo['lastSyncDateTime'] = lastSyncDate.toIso8601String();
      } else {
        syncInfo['timeAgo'] = 'Never synced';
      }
      
      return syncInfo;
    } on PlatformException catch (e) {
      _log('ERROR getting last sync info: ${e.message}');
      return {
        'error': e.message,
        'lastSyncTime': 0,
        'timeAgo': 'Error',
      };
    }
  }
}