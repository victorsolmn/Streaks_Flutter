import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

Future<void> captureHealthDataLogs() async {
  const platform = MethodChannel('com.streaker/health_connect');

  try {
    print('Capturing Health Connect API logs...');

    // Call the native Android method to capture detailed health data logs
    final result = await platform.invokeMethod('captureHealthDataLogs');

    if (result != null && result['logData'] != null) {
      final String logData = result['logData'];
      final String summary = result['summary'] ?? 'No summary available';

      print('\n✅ Log capture successful!');
      print('📊 $summary');

      // Get the desktop path
      final String desktopPath = '${Platform.environment['HOME']}/Desktop';
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final String fileName = 'health_data_logs_$timestamp.json';
      final File logFile = File('$desktopPath/$fileName');

      // Write the JSON data to file
      await logFile.writeAsString(logData);

      print('\n📁 Logs saved to: $desktopPath/$fileName');
      print('\nLog file contains:');
      print('  • Active Calorie Burned Records (exercise calories)');
      print('  • Total Calorie Burned Records (BMR + active)');
      print('  • Basal Metabolic Rate Records');
      print('  • Exercise Session Records');
      print('  • Steps and Distance by source');
      print('  • Analysis and recommendations');

      // Parse and display key insights
      final Map<String, dynamic> jsonData = json.decode(logData);
      final calorieData = jsonData['calorieData'];

      print('\n🔍 Key Insights:');

      // Active Calories
      if (calorieData['activeCaloriesBySource'] != null) {
        print('\n📱 Active Calories by Source:');
        final activeBySource = calorieData['activeCaloriesBySource'];
        activeBySource.forEach((source, calories) {
          print('   • $source: ${calories.toStringAsFixed(2)} kcal');
        });
      }

      // Total Calories
      if (calorieData['totalCaloriesBySource'] != null) {
        print('\n🔥 Total Calories by Source:');
        final totalBySource = calorieData['totalCaloriesBySource'];
        totalBySource.forEach((source, calories) {
          print('   • $source: ${calories.toStringAsFixed(2)} kcal');
        });
      }

      // BMR
      if (calorieData['basalMetabolicRateCount'] != null &&
          calorieData['basalMetabolicRateCount'] > 0) {
        print('\n💪 Basal Metabolic Rate Records: ${calorieData['basalMetabolicRateCount']}');
      }

      // Exercise Sessions
      if (calorieData['exerciseSessionCount'] != null &&
          calorieData['exerciseSessionCount'] > 0) {
        print('\n🏃 Exercise Sessions: ${calorieData['exerciseSessionCount']}');
      }

      print('\n✨ Please review the log file to determine which calorie field to use.');
      print('   Look for "ActiveCaloriesBurnedRecord" vs "TotalCaloriesBurnedRecord"');
      print('   from Samsung Health (com.sec.android.app.shealth) source.');

    } else {
      print('❌ Failed to capture health data logs');
    }
  } catch (e) {
    print('❌ Error capturing health data logs: $e');
    if (e.toString().contains('MissingPluginException')) {
      print('\n⚠️ This script must be run from within the Flutter app');
      print('   Please add this code to your app and trigger it from there.');
    }
  }
}

// Main function for testing
void main() async {
  await captureHealthDataLogs();
}