import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_theme.dart';
import 'toast_service.dart';

class PopupService {
  static final PopupService _instance = PopupService._internal();
  factory PopupService() => _instance;
  PopupService._internal();

  // Show network error popup
  static void showNetworkError(
    BuildContext context, {
    required VoidCallback onRetry,
    String? customMessage,
    bool canDismiss = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkCardBackground 
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.errorRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customMessage ?? 
                'Unable to connect to the internet. Please check your connection and try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              // Connection status indicator
              FutureBuilder<List<ConnectivityResult>>(
                future: Connectivity().checkConnectivity(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final isConnected = !snapshot.data!.contains(ConnectivityResult.none);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isConnected 
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isConnected 
                              ? AppTheme.successGreen.withOpacity(0.3)
                              : AppTheme.errorRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: isConnected ? AppTheme.successGreen : AppTheme.errorRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected ? 'Connected' : 'No Connection',
                            style: TextStyle(
                              color: isConnected ? AppTheme.successGreen : AppTheme.errorRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          actions: [
            if (canDismiss)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show app update popup
  static void showAppUpdate(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required String updateUrl,
    String? releaseNotes,
    bool isForced = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkCardBackground 
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForced ? 'Update Required' : 'Update Available',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version $latestVersion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isForced) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is required to continue using the app.',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Text(
                'A new version of Streaker is available with improvements and bug fixes.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Version comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800] 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          latestVersion,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (releaseNotes != null) ...[
                const SizedBox(height: 16),
                Text(
                  'What\'s New:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[300] 
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchUpdate(updateUrl, context);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(isForced ? 'Update Now' : 'Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isForced ? AppTheme.errorRed : AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show maintenance popup
  static void showMaintenance(
    BuildContext context, {
    String? message,
    String? expectedDuration,
    DateTime? expectedBackTime,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkCardBackground 
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.build_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message ?? 
                'We\'re currently performing maintenance to improve your experience. Please try again shortly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[300] 
                      : Colors.grey[700],
                ),
              ),
              if (expectedDuration != null || expectedBackTime != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (expectedDuration != null)
                        Text(
                          'Expected Duration: $expectedDuration',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (expectedBackTime != null)
                        Text(
                          'Expected Back: ${expectedBackTime.toString().substring(0, 16)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Launch update URL
  static Future<void> _launchUpdate(String updateUrl, BuildContext context) async {
    try {
      final Uri url = Uri.parse(updateUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ToastService().showError('Unable to open update link');
      }
    } catch (e) {
      ToastService().showError('Error opening update: $e');
    }
  }

  // Get app version info
  static Future<PackageInfo> getAppInfo() async {
    return await PackageInfo.fromPlatform();
  }

  // Check for app updates (mock implementation - you'd integrate with your update service)
  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // TODO: Replace with your actual update check API
      // This is a mock implementation
      return {
        'hasUpdate': false, // Set to true to test
        'latestVersion': '1.0.1',
        'currentVersion': currentVersion,
        'isForced': false,
        'updateUrl': 'https://play.google.com/store/apps/details?id=com.streaker.streaker',
        'releaseNotes': '• Improved Samsung Health integration\n• Fixed streak calculation bugs\n• Performance improvements',
      };
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }
}