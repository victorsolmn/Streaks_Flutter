import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AndroidHealthPermissionGuide extends StatelessWidget {
  final bool isSamsung;
  final int androidVersion;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const AndroidHealthPermissionGuide({
    Key? key,
    required this.isSamsung,
    required this.androidVersion,
    required this.onProceed,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'Enable Health Permissions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),

            // Description based on device
            Text(
              _getDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            // Steps
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Steps to enable:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12),
                  ..._getSteps().map((step) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppTheme.primaryAccent,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDescription() {
    if (isSamsung && androidVersion >= 34) {
      return 'Your Samsung device has Health Connect integrated. We need to open the health settings for you to grant permissions.';
    } else if (androidVersion >= 34) {
      return 'Health Connect is integrated into your system. We\'ll open the settings where you can grant health permissions.';
    } else {
      return 'We need to open Health Connect to grant health data permissions. This allows Streaker to track your fitness data.';
    }
  }

  List<String> _getSteps() {
    if (isSamsung && androidVersion >= 34) {
      return [
        'The Health Connect settings will open',
        'Look for "Streaker" in the app list',
        'Enable all requested permissions',
        'Use the back button to return here',
        'Your health data will sync automatically',
      ];
    } else if (androidVersion >= 34) {
      return [
        'Health settings will open for Streaker',
        'Toggle ON all health permissions',
        'Pay special attention to Steps and Heart Rate',
        'Press back to return to the app',
      ];
    } else {
      return [
        'Health Connect app will open',
        'Find "Streaker" in the apps list',
        'Grant access to all health data types',
        'Return to Streaker when done',
      ];
    }
  }
}