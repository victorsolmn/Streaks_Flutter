import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/native_health_connect_service.dart';
import '../utils/app_theme.dart';

class HealthDebugScreen extends StatefulWidget {
  @override
  _HealthDebugScreenState createState() => _HealthDebugScreenState();
}

class _HealthDebugScreenState extends State<HealthDebugScreen> {
  final NativeHealthConnectService _healthService = NativeHealthConnectService();
  bool _isLoading = false;
  Map<String, dynamic> _debugData = {};
  List<String> _logs = [];
  String _currentTest = '';

  @override
  void initState() {
    super.initState();
    _loadDebugLogs();
  }

  void _loadDebugLogs() {
    setState(() {
      _logs = List.from(_healthService.debugLogs);
    });
  }

  void _log(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _logs.add('[$timestamp] $message');
      if (_logs.length > 100) _logs.removeAt(0);
    });
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _debugData = {};
    });

    try {
      _log('=== STARTING FULL DIAGNOSTIC ===');
      
      // Step 1: Check Health Connect Availability
      _log('Step 1: Checking Health Connect availability...');
      setState(() => _currentTest = 'Checking Health Connect...');
      final availability = await _healthService.checkAvailability();
      _debugData['availability'] = availability;
      _log('Available: ${availability['available']}');
      _log('Status: ${availability['status']}');
      
      if (availability['available'] != true) {
        _log('❌ Health Connect not available!');
        _log('Please install Health Connect from Play Store');
        setState(() => _isLoading = false);
        return;
      }
      
      // Step 2: Check Permissions
      _log('\nStep 2: Checking permissions...');
      setState(() => _currentTest = 'Checking permissions...');
      final permissions = await _healthService.checkPermissions();
      _debugData['permissions'] = permissions;
      _log('Permissions granted: ${permissions['granted']}');
      _log('Granted count: ${permissions['grantedCount']}/${permissions['requiredCount']}');
      
      // Step 3: Read All Health Data
      _log('\nStep 3: Reading health data...');
      setState(() => _currentTest = 'Reading health data...');
      final healthData = await _healthService.readAllHealthData();
      _debugData['healthData'] = healthData;
      
      // Log data sources
      if (healthData['dataSources'] != null) {
        final sources = healthData['dataSources'] as List;
        _log('\nData Sources Found (${sources.length}):');
        for (var source in sources) {
          _log('  • $source');
          if (source.toString().contains('samsung') || 
              source.toString().contains('shealth') || 
              source.toString().contains('gear')) {
            _log('    ✅ Samsung device detected!');
          }
        }
      } else {
        _log('⚠️ No data sources found');
      }
      
      // Log step details
      if (healthData['stepDetails'] != null) {
        final stepDetails = healthData['stepDetails'] as List;
        _log('\nStep Records (${stepDetails.length} records):');
        for (var i = 0; i < stepDetails.length && i < 5; i++) {
          final detail = stepDetails[i] as Map;
          _log('  Record ${i+1}:');
          _log('    Steps: ${detail['count']}');
          _log('    Source: ${detail['source']}');
          _log('    Time: ${detail['startTime']?.toString()?.substring(0, 19)}');
        }
        if (stepDetails.length > 5) {
          _log('  ... and ${stepDetails.length - 5} more records');
        }
      }
      
      // Log summary
      _log('\n=== DATA SUMMARY ===');
      _log('Steps: ${healthData['steps'] ?? 0}');
      _log('Heart Rate: ${healthData['heartRate'] ?? 0} bpm');
      _log('Calories: ${healthData['calories'] ?? 0}');
      _log('Distance: ${healthData['distance'] ?? 0.0} km');
      _log('Last Sync: ${healthData['lastSync']?.toString()?.substring(0, 19) ?? 'Never'}');
      
      // Step 4: Check Last Background Sync
      _log('\nStep 4: Checking background sync...');
      setState(() => _currentTest = 'Checking background sync...');
      final syncInfo = await _healthService.getLastSyncInfo();
      _debugData['syncInfo'] = syncInfo;
      _log('Last background sync: ${syncInfo['timeAgo'] ?? 'Never'}');
      _log('Has Samsung data: ${syncInfo['hasSamsungData'] ?? false}');
      
      // Step 5: Manual sync trigger
      _log('\nStep 5: Starting background sync...');
      setState(() => _currentTest = 'Starting background sync...');
      final syncResult = await _healthService.startBackgroundSync();
      _log('Background sync: ${syncResult['message'] ?? 'Unknown'}');
      
      _log('\n=== DIAGNOSTIC COMPLETE ===');
      
      // Analyze results
      _analyzeResults();
      
    } catch (e) {
      _log('❌ ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _currentTest = '';
      });
      _loadDebugLogs();
    }
  }

  void _analyzeResults() {
    _log('\n=== ANALYSIS ===');
    
    final healthData = _debugData['healthData'] as Map<String, dynamic>?;
    final permissions = _debugData['permissions'] as Map<String, dynamic>?;
    final availability = _debugData['availability'] as Map<String, dynamic>?;
    
    // Check common issues
    if (availability?['available'] != true) {
      _log('❌ ISSUE: Health Connect not installed');
      _log('  SOLUTION: Install Health Connect from Play Store');
    } else if (permissions?['granted'] != true) {
      _log('❌ ISSUE: Permissions not granted');
      _log('  SOLUTION: Grant all permissions in Health Connect settings');
    } else if (healthData?['dataSources'] == null || 
               (healthData!['dataSources'] as List).isEmpty) {
      _log('⚠️ ISSUE: No data sources found');
      _log('  POSSIBLE CAUSES:');
      _log('  1. Samsung Health not syncing to Health Connect');
      _log('  2. No data recorded today');
      _log('  3. Sync delay between Samsung Health and Health Connect');
      _log('  SOLUTIONS:');
      _log('  1. Open Samsung Health → Settings → Connected services');
      _log('  2. Check if Health Connect is connected');
      _log('  3. Force sync in Samsung Health');
      _log('  4. Record some steps and wait 5 minutes');
    } else if (!(healthData!['dataSources'] as List).any((s) => 
               s.toString().contains('samsung') || 
               s.toString().contains('shealth'))) {
      _log('⚠️ ISSUE: Data not from Samsung Health');
      _log('  Data is coming from: ${(healthData['dataSources'] as List).join(', ')}');
      _log('  SOLUTION: Check Samsung Health → Health Connect connection');
    } else if ((healthData['steps'] as int?) == 0) {
      _log('⚠️ ISSUE: Zero steps recorded');
      _log('  POSSIBLE CAUSES:');
      _log('  1. No activity recorded today');
      _log('  2. Data not synced yet');
      _log('  SOLUTION: Walk around and check Samsung Health shows steps');
    } else {
      _log('✅ Everything appears to be working correctly!');
      _log('  Data is coming from Samsung devices');
      _log('  Steps are being recorded');
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final logsText = _logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logs copied to clipboard'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Health Connect Diagnostic'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy logs',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runFullDiagnostic,
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCardBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runFullDiagnostic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _currentTest.isEmpty ? 'Running Diagnostic...' : _currentTest,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : Text(
                          'Run Full Diagnostic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (_debugData.isNotEmpty) ...[
                  SizedBox(height: 16),
                  // Quick Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusChip(
                        'Health Connect',
                        _debugData['availability']?['available'] == true,
                      ),
                      _buildStatusChip(
                        'Permissions',
                        _debugData['permissions']?['granted'] == true,
                      ),
                      _buildStatusChip(
                        'Samsung Data',
                        _debugData['syncInfo']?['hasSamsungData'] == true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Debug Logs
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
              ),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(
                        'Tap "Run Full Diagnostic" to start',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.white70;
                        
                        if (log.contains('✅')) textColor = Colors.greenAccent;
                        else if (log.contains('❌')) textColor = Colors.redAccent;
                        else if (log.contains('⚠️')) textColor = Colors.orangeAccent;
                        else if (log.contains('===')) textColor = AppTheme.primaryAccent;
                        else if (log.contains('SOLUTION:')) textColor = Colors.lightBlueAccent;
                        
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          
          // Instructions
          Container(
            padding: EdgeInsets.all(12),
            color: AppTheme.darkCardBackground,
            child: Column(
              children: [
                Text(
                  'Troubleshooting Steps:',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Run diagnostic and copy logs\n'
                  '2. Check Samsung Health → Settings → Connected services\n'
                  '3. Ensure Health Connect shows as connected\n'
                  '4. Force sync in Samsung Health (pull down to refresh)\n'
                  '5. Wait 5 minutes and run diagnostic again',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isOk) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            size: 16,
            color: isOk ? Colors.green : Colors.red,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: isOk 
          ? Colors.green.withOpacity(0.2)
          : Colors.red.withOpacity(0.2),
    );
  }
}