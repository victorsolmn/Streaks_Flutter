import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class HealthLogCaptureService {
  static const platform = MethodChannel('com.streaker/health_connect');

  static Future<Map<String, dynamic>> captureAndSaveHealthLogs() async {
    try {
      print('🔍 Capturing detailed Health Connect API logs...');

      // Call the native Android method to capture detailed health data logs
      final result = await platform.invokeMethod('captureHealthDataLogs');

      if (result != null && result['logData'] != null) {
        final String logData = result['logData'];
        final String summary = result['summary'] ?? 'No summary available';

        // Get the desktop path - for mobile, we'll use Documents directory
        String savePath;
        if (Platform.isAndroid) {
          // On Android, save to Downloads folder
          savePath = '/storage/emulated/0/Download';
        } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
          // On desktop, save to Desktop
          savePath = '${Platform.environment['HOME']}/Desktop';
        } else {
          // Fallback to temp directory
          savePath = Directory.systemTemp.path;
        }

        final String timestamp =
            DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        final String fileName = 'health_data_logs_$timestamp.json';
        final File logFile = File('$savePath/$fileName');

        // Create directory if it doesn't exist
        final directory = Directory(savePath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Write the JSON data to file
        await logFile.writeAsString(logData);

        // Parse the JSON for analysis
        final Map<String, dynamic> jsonData = json.decode(logData);
        final calorieData = jsonData['calorieData'];

        // Build analysis result
        final Map<String, dynamic> analysisResult = {
          'success': true,
          'filePath': logFile.path,
          'summary': summary,
          'timestamp': timestamp,
          'analysis': _analyzeCalorieData(calorieData),
        };

        print('\n✅ Health data logs captured successfully!');
        print('📁 Saved to: ${logFile.path}');
        print('📊 $summary');

        return analysisResult;
      } else {
        return {
          'success': false,
          'error': 'No data received from Health Connect',
        };
      }
    } on PlatformException catch (e) {
      print('❌ Platform error: ${e.message}');
      return {
        'success': false,
        'error': 'Platform error: ${e.message}',
      };
    } catch (e) {
      print('❌ Error capturing health data logs: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Map<String, dynamic> _analyzeCalorieData(dynamic calorieData) {
    final Map<String, dynamic> analysis = {
      'hasActiveCalories': false,
      'hasTotalCalories': false,
      'hasBasalMetabolicRate': false,
      'hasExerciseSessions': false,
      'activeCaloriesSources': <String>[],
      'totalCaloriesSources': <String>[],
      'recommendations': <String>[],
    };

    if (calorieData == null) return analysis;

    // Check for active calories
    if (calorieData['activeCaloriesCount'] != null &&
        calorieData['activeCaloriesCount'] > 0) {
      analysis['hasActiveCalories'] = true;
      analysis['activeCaloriesCount'] = calorieData['activeCaloriesCount'];

      if (calorieData['activeCaloriesBySource'] != null) {
        final sources = calorieData['activeCaloriesBySource'] as Map;
        analysis['activeCaloriesSources'] = sources.keys.toList();

        // Check for Samsung Health
        bool hasSamsungActive = sources.keys.any((source) =>
            source.toString().contains('shealth') ||
            source.toString().contains('com.sec.android'));

        if (hasSamsungActive) {
          analysis['recommendations'].add(
              'Samsung Health provides ActiveCaloriesBurnedRecord - use this directly for active calories');
        }
      }
    }

    // Check for total calories
    if (calorieData['totalCaloriesCount'] != null &&
        calorieData['totalCaloriesCount'] > 0) {
      analysis['hasTotalCalories'] = true;
      analysis['totalCaloriesCount'] = calorieData['totalCaloriesCount'];

      if (calorieData['totalCaloriesBySource'] != null) {
        final sources = calorieData['totalCaloriesBySource'] as Map;
        analysis['totalCaloriesSources'] = sources.keys.toList();

        // Check for Samsung Health
        bool hasSamsungTotal = sources.keys.any((source) =>
            source.toString().contains('shealth') ||
            source.toString().contains('com.sec.android'));

        if (hasSamsungTotal && !analysis['hasActiveCalories']) {
          analysis['recommendations'].add(
              'Samsung Health only provides TotalCaloriesBurnedRecord - subtract BMR to get active calories');
        }
      }
    }

    // Check for BMR
    if (calorieData['basalMetabolicRateCount'] != null &&
        calorieData['basalMetabolicRateCount'] > 0) {
      analysis['hasBasalMetabolicRate'] = true;
      analysis['basalMetabolicRateCount'] = calorieData['basalMetabolicRateCount'];
      analysis['recommendations'].add(
          'BMR data available - can be used to calculate active calories from total');
    }

    // Check for exercise sessions
    if (calorieData['exerciseSessionCount'] != null &&
        calorieData['exerciseSessionCount'] > 0) {
      analysis['hasExerciseSessions'] = true;
      analysis['exerciseSessionCount'] = calorieData['exerciseSessionCount'];
    }

    // General recommendations
    if (analysis['hasActiveCalories'] == true) {
      analysis['recommendations'].add(
          'PRIMARY: Use ActiveCaloriesBurnedRecord.energy.inKilocalories for active calorie burn');
    } else if (analysis['hasTotalCalories'] == true) {
      if (analysis['hasBasalMetabolicRate'] == true) {
        analysis['recommendations'].add(
            'FALLBACK: Calculate active = TotalCalories - BMR (use actual BMR data)');
      } else {
        analysis['recommendations'].add(
            'FALLBACK: Estimate active = TotalCalories - (1600 * hours/24) for rough BMR');
      }
    }

    return analysis;
  }

  static Future<void> printLogSummary(Map<String, dynamic> result) async {
    if (!result['success']) {
      print('❌ Failed to capture logs: ${result['error']}');
      return;
    }

    print('\n' + '=' * 60);
    print('📊 HEALTH DATA LOG ANALYSIS');
    print('=' * 60);

    final analysis = result['analysis'];

    print('\n📱 Data Sources Found:');
    print('  • Active Calories: ${analysis['hasActiveCalories'] ? '✅' : '❌'} '
        '${analysis['activeCaloriesCount'] ?? 0} records');
    print('  • Total Calories: ${analysis['hasTotalCalories'] ? '✅' : '❌'} '
        '${analysis['totalCaloriesCount'] ?? 0} records');
    print('  • Basal Metabolic Rate: ${analysis['hasBasalMetabolicRate'] ? '✅' : '❌'} '
        '${analysis['basalMetabolicRateCount'] ?? 0} records');
    print('  • Exercise Sessions: ${analysis['hasExerciseSessions'] ? '✅' : '❌'} '
        '${analysis['exerciseSessionCount'] ?? 0} records');

    if (analysis['activeCaloriesSources'].isNotEmpty) {
      print('\n🔥 Active Calorie Sources:');
      for (String source in analysis['activeCaloriesSources']) {
        print('  • $source');
      }
    }

    if (analysis['totalCaloriesSources'].isNotEmpty) {
      print('\n💪 Total Calorie Sources:');
      for (String source in analysis['totalCaloriesSources']) {
        print('  • $source');
      }
    }

    if (analysis['recommendations'].isNotEmpty) {
      print('\n💡 Recommendations:');
      for (String rec in analysis['recommendations']) {
        print('  → $rec');
      }
    }

    print('\n📁 Full logs saved to: ${result['filePath']}');
    print('=' * 60);
  }
}