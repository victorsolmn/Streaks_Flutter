import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Samsung Health SDK requires partnership approval - using BLE characteristics instead
import '../models/health_metric_model.dart';

class BluetoothSmartwatchService {
  static final BluetoothSmartwatchService _instance = BluetoothSmartwatchService._internal();
  factory BluetoothSmartwatchService() => _instance;
  BluetoothSmartwatchService._internal();

  // Samsung Health data will be fetched via BLE characteristics
  
  // Bluetooth state
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  // Connected device info
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceType;
  Timer? _syncTimer;
  Function(Map<String, dynamic>)? _onDataUpdate;
  
  // Standard BLE UUIDs for health services
  final Map<String, String> _bleHealthServiceUuids = {
    'heart_rate': '0000180d-0000-1000-8000-00805f9b34fb',
    'battery': '0000180f-0000-1000-8000-00805f9b34fb',
    'device_info': '0000180a-0000-1000-8000-00805f9b34fb',
    'fitness_machine': '00001826-0000-1000-8000-00805f9b34fb',
    'running_speed': '00001814-0000-1000-8000-00805f9b34fb',
  };
  
  // Standard BLE characteristic UUIDs
  final Map<String, String> _bleCharacteristicUuids = {
    'heart_rate_measurement': '00002a37-0000-1000-8000-00805f9b34fb',
    'battery_level': '00002a19-0000-1000-8000-00805f9b34fb',
    'rsc_measurement': '00002a53-0000-1000-8000-00805f9b34fb',
    'fitness_machine_feature': '00002acc-0000-1000-8000-00805f9b34fb',
  };
  
  // Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDevice = prefs.getString('connected_smartwatch');
    final savedDeviceAddress = prefs.getString('connected_device_address');
    
    if (savedDevice != null && savedDeviceAddress != null) {
      // Try to reconnect to saved device
      await _reconnectToSavedDevice(savedDevice, savedDeviceAddress);
    }
    
    // Listen to Bluetooth adapter state changes
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      debugPrint('Bluetooth adapter state: $state');
    });
  }
  
  // Check and request necessary permissions
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      // Request Bluetooth permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();
      
      // Check if all permissions are granted
      bool allGranted = statuses.values.every((status) => status == PermissionStatus.granted);
      
      if (!allGranted) {
        debugPrint('Not all permissions granted: $statuses');
        return false;
      }
    }
    
    return true;
  }
  
  // Scan for available Bluetooth devices
  Future<List<Map<String, dynamic>>> scanForDevices() async {
    List<Map<String, dynamic>> discoveredDevices = [];
    
    // Check permissions first
    bool hasPermissions = await checkPermissions();
    if (!hasPermissions) {
      throw Exception('Bluetooth permissions not granted');
    }
    
    // Check if Bluetooth is on
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;
    
    // Start scanning
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (ScanResult result in results) {
          // Filter for smartwatch/fitness tracker devices
          String deviceName = result.device.advName.isNotEmpty 
              ? result.device.advName 
              : result.device.platformName;
          
          if (_isSmartwatch(deviceName)) {
            // Check if device is not already in the list
            bool exists = discoveredDevices.any((d) => d['id'] == result.device.remoteId.str);
            
            if (!exists) {
              discoveredDevices.add({
                'id': result.device.remoteId.str,
                'name': deviceName,
                'rssi': result.rssi,
                'device': result.device,
                'type': _getDeviceType(deviceName),
              });
              
              debugPrint('Discovered smartwatch: $deviceName (${result.device.remoteId})');
            }
          }
        }
      },
      onError: (e) {
        debugPrint('Scan error: $e');
      },
    );
    
    // Wait for scan to complete
    await Future.delayed(const Duration(seconds: 15));
    await FlutterBluePlus.stopScan();
    
    return discoveredDevices;
  }
  
  // Check if device name indicates a smartwatch
  bool _isSmartwatch(String deviceName) {
    final watchKeywords = [
      'watch', 'galaxy', 'garmin', 'fitbit', 'band', 
      'amazfit', 'huawei', 'samsung', 'gear', 'active',
      'versa', 'sense', 'charge', 'mi', 'honor', 'gt'
    ];
    
    String lowerName = deviceName.toLowerCase();
    return watchKeywords.any((keyword) => lowerName.contains(keyword));
  }
  
  // Get device type from name
  String _getDeviceType(String deviceName) {
    String lowerName = deviceName.toLowerCase();
    
    if (lowerName.contains('galaxy') || lowerName.contains('samsung')) {
      return 'samsung_watch';
    } else if (lowerName.contains('garmin')) {
      return 'garmin';
    } else if (lowerName.contains('fitbit')) {
      return 'fitbit';
    } else if (lowerName.contains('mi band')) {
      return 'mi_band';
    } else if (lowerName.contains('amazfit')) {
      return 'amazfit';
    } else if (lowerName.contains('huawei') || lowerName.contains('honor')) {
      return 'huawei';
    } else if (lowerName.contains('apple')) {
      return 'apple_watch';
    } else {
      return 'generic_ble';
    }
  }
  
  // Connect to a specific device
  Future<bool> connectDevice(Map<String, dynamic> deviceInfo) async {
    try {
      BluetoothDevice device = deviceInfo['device'];
      String deviceType = deviceInfo['type'];
      String deviceName = deviceInfo['name'];
      
      debugPrint('Connecting to $deviceName...');
      
      // Connect to the device
      await device.connect(
        autoConnect: false,
        mtu: null,
      );
      
      // Wait for connection to be established
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first;
      
      _connectedDevice = device;
      _connectedDeviceType = deviceType;
      
      // Save device info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_smartwatch', deviceType);
      await prefs.setString('connected_device_address', device.remoteId.str);
      await prefs.setString('connected_device_name', deviceName);
      
      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('Device disconnected');
          _handleDisconnection();
        }
      });
      
      // For Samsung devices, we'll use BLE characteristics
      // Samsung Health SDK requires partnership approval
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      debugPrint('Discovered ${services.length} services');
      
      // Start data sync
      await startDataSync();
      
      debugPrint('Successfully connected to $deviceName');
      return true;
      
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      return false;
    }
  }
  
  // Fetch Samsung watch data via BLE
  Future<Map<String, dynamic>> _fetchSamsungWatchData() async {
    Map<String, dynamic> healthData = _getEmptyHealthData();
    
    if (_connectedDevice == null) return healthData;
    
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      debugPrint('Found ${services.length} services on Samsung device');
      
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        debugPrint('Service UUID: $serviceUuid');
        
        // Heart Rate Service
        if (serviceUuid.contains('180d')) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('2a37')) {
              // Subscribe to heart rate notifications
              if (char.properties.notify) {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  if (value.isNotEmpty && value.length >= 2) {
                    int heartRate = value[1];
                    healthData['heartRate'] = heartRate;
                    debugPrint('Heart Rate: $heartRate bpm');
                    _onDataUpdate?.call(healthData);
                  }
                });
              }
            }
          }
        }
        
        // Battery Service
        if (serviceUuid.contains('180f')) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('2a19')) {
              List<int> value = await char.read();
              if (value.isNotEmpty) {
                int batteryLevel = value[0];
                debugPrint('Battery Level: $batteryLevel%');
              }
            }
          }
        }
        
        // Running Speed and Cadence Service
        if (serviceUuid.contains('1814')) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.properties.notify) {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((value) {
                if (value.length >= 4) {
                  // Parse speed and cadence data
                  int speed = (value[1] | (value[2] << 8));
                  int cadence = value[3];
                  
                  // Convert to meaningful units
                  double speedKmh = speed / 256.0;
                  healthData['speed'] = speedKmh;
                  healthData['cadence'] = cadence;
                  
                  // Estimate steps from cadence (rough approximation)
                  if (cadence > 0) {
                    healthData['steps'] = (healthData['steps'] ?? 0) + cadence;
                  }
                  
                  debugPrint('Speed: ${speedKmh.toStringAsFixed(2)} km/h, Cadence: $cadence');
                  _onDataUpdate?.call(healthData);
                }
              });
            }
          }
        }
        
        // Fitness Machine Service (for treadmills, bikes, etc)
        if (serviceUuid.contains('1826')) {
          for (BluetoothCharacteristic char in service.characteristics) {
            String charUuid = char.uuid.toString().toLowerCase();
            
            // Treadmill data
            if (charUuid.contains('2acd')) {
              if (char.properties.notify) {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  if (value.length >= 6) {
                    // Parse distance and calories
                    int distance = value[1] | (value[2] << 8) | (value[3] << 16);
                    int calories = value[4] | (value[5] << 8);
                    
                    healthData['distance'] = distance / 1000.0; // Convert to km
                    healthData['calories'] = calories;
                    
                    debugPrint('Distance: ${distance}m, Calories: $calories');
                    _onDataUpdate?.call(healthData);
                  }
                });
              }
            }
          }
        }
        
        // Custom Samsung Services (may vary by device)
        // Samsung devices often use custom UUIDs for additional data
        if (serviceUuid.contains('6e40') || serviceUuid.contains('7905')) {
          debugPrint('Found Samsung custom service: $serviceUuid');
          for (BluetoothCharacteristic char in service.characteristics) {
            debugPrint('  Characteristic: ${char.uuid}');
            
            // Try to read if readable
            if (char.properties.read) {
              try {
                List<int> value = await char.read();
                debugPrint('    Value: $value');
              } catch (e) {
                debugPrint('    Could not read: $e');
              }
            }
            
            // Subscribe if notifiable
            if (char.properties.notify) {
              try {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  debugPrint('    Notification: $value');
                });
              } catch (e) {
                debugPrint('    Could not subscribe: $e');
              }
            }
          }
        }
      }
      
      // For demo purposes, add simulated step data
      // In production, this would come from actual BLE characteristics
      final now = DateTime.now();
      final hour = now.hour;
      
      // Simulate realistic step pattern based on time of day
      if (hour >= 6 && hour <= 22) {
        healthData['steps'] = healthData['steps'] ?? (hour * 500 + now.minute * 8);
        healthData['calories'] = healthData['calories'] ?? (healthData['steps'] as int) ~/ 20;
        healthData['distance'] = healthData['distance'] ?? (healthData['steps'] as int) / 1300.0;
        healthData['activeMinutes'] = ((healthData['steps'] as int) / 100).round();
      }
      
    } catch (e) {
      debugPrint('Error reading Samsung watch BLE data: $e');
    }
    
    return healthData;
  }
  
  
  // Fetch health data based on device type
  Future<Map<String, dynamic>> fetchHealthData() async {
    if (_connectedDevice == null) {
      return _getEmptyHealthData();
    }
    
    Map<String, dynamic> healthData;
    
    switch (_connectedDeviceType) {
      case 'samsung_watch':
        // Use BLE for Samsung watches since SDK requires partnership
        healthData = await _fetchSamsungWatchData();
        break;
      default:
        // For other devices, try to read BLE characteristics
        healthData = await _fetchBLEData();
        break;
    }
    
    // Notify listeners
    _onDataUpdate?.call(healthData);
    
    return healthData;
  }
  
  // Fetch data from BLE characteristics
  Future<Map<String, dynamic>> _fetchBLEData() async {
    Map<String, dynamic> healthData = _getEmptyHealthData();
    
    if (_connectedDevice == null) return healthData;
    
    try {
      // Discover services if not already done
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (BluetoothService service in services) {
        // Look for standard health service UUIDs
        if (service.uuid.toString().contains('180d')) { // Heart Rate Service
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().contains('2a37')) { // Heart Rate Measurement
              List<int> value = await characteristic.read();
              if (value.isNotEmpty) {
                healthData['heartRate'] = value[1]; // Simplified parsing
              }
            }
          }
        }
        
        // Add more standard BLE health services here
        // Step counter, battery level, etc.
      }
      
    } catch (e) {
      debugPrint('Error reading BLE characteristics: $e');
    }
    
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
  }
  
  // Stop data sync
  void stopDataSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Disconnect current device
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    
    _handleDisconnection();
  }
  
  // Handle device disconnection
  void _handleDisconnection() {
    _connectedDevice = null;
    _connectedDeviceType = null;
    stopDataSync();
    
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    // Clear saved device info
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('connected_smartwatch');
      prefs.remove('connected_device_address');
      prefs.remove('connected_device_name');
    });
  }
  
  // Try to reconnect to saved device
  Future<void> _reconnectToSavedDevice(String deviceType, String deviceAddress) async {
    try {
      // Check if Bluetooth is on
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first;
      
      // Try to connect to the device
      BluetoothDevice device = BluetoothDevice.fromId(deviceAddress);
      
      await device.connect(
        autoConnect: true,
        mtu: null,
      );
      
      _connectedDevice = device;
      _connectedDeviceType = deviceType;
      
      // Samsung devices will use BLE characteristics
      
      // Start data sync
      await startDataSync();
      
      debugPrint('Reconnected to saved device: $deviceAddress');
      
    } catch (e) {
      debugPrint('Failed to reconnect to saved device: $e');
      _handleDisconnection();
    }
  }
  
  // Set callback for data updates
  void setDataUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onDataUpdate = callback;
  }
  
  // Check if a device is connected
  bool get isDeviceConnected => _connectedDevice != null;
  
  // Get connected device info
  Map<String, dynamic>? getConnectedDeviceInfo() {
    if (_connectedDevice == null) return null;
    
    return {
      'id': _connectedDevice!.remoteId.str,
      'name': _connectedDevice!.platformName,
      'type': _connectedDeviceType,
    };
  }
  
  // Manual sync trigger
  Future<void> syncNow() async {
    await fetchHealthData();
  }
  
  // Clean up resources
  void dispose() {
    stopDataSync();
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
  }
}