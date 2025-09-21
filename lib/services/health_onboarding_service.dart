import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../providers/health_provider.dart';
import '../services/unified_health_service.dart';

class HealthOnboardingService {
  static const String _healthPromptShownKey = 'health_prompt_shown';
  static const String _healthPromptDismissedCountKey = 'health_prompt_dismissed_count';
  static const String _lastHealthPromptDateKey = 'last_health_prompt_date';
  static const String _healthConnectedKey = 'health_connected';
  static const String _shouldShowSyncIndicatorKey = 'should_show_sync_indicator';

  final SharedPreferences _prefs;
  final HealthProvider healthProvider;
  final UnifiedHealthService healthService;

  HealthOnboardingService({
    required SharedPreferences prefs,
    required this.healthProvider,
  }) : _prefs = prefs,
       healthService = healthProvider.healthService;

  // Check if we should show the health permission dialog
  Future<bool> shouldShowHealthPrompt() async {
    // If already connected, don't show
    if (healthProvider.isHealthSourceConnected) {
      return false;
    }

    // Check if we've shown it before
    final hasShown = _prefs.getBool(_healthPromptShownKey) ?? false;
    if (!hasShown) {
      return true; // First time, definitely show
    }

    // Check dismissed count and last prompt date for re-engagement
    final dismissedCount = _prefs.getInt(_healthPromptDismissedCountKey) ?? 0;
    final lastPromptDateStr = _prefs.getString(_lastHealthPromptDateKey);

    // If dismissed more than 3 times, stop showing
    if (dismissedCount >= 3) {
      return false;
    }

    // If we have a last prompt date, check if enough time has passed
    if (lastPromptDateStr != null) {
      final lastPromptDate = DateTime.parse(lastPromptDateStr);
      final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;

      // Re-show after 3 days for first dismiss, 7 days for second
      final requiredDays = dismissedCount == 1 ? 3 : 7;
      return daysSinceLastPrompt >= requiredDays;
    }

    return false;
  }

  // Mark that we've shown the health prompt
  Future<void> markHealthPromptShown() async {
    await _prefs.setBool(_healthPromptShownKey, true);
    await _prefs.setString(_lastHealthPromptDateKey, DateTime.now().toIso8601String());
  }

  // Mark that the user dismissed the prompt
  Future<void> markHealthPromptDismissed() async {
    final currentCount = _prefs.getInt(_healthPromptDismissedCountKey) ?? 0;
    await _prefs.setInt(_healthPromptDismissedCountKey, currentCount + 1);
    await _prefs.setString(_lastHealthPromptDateKey, DateTime.now().toIso8601String());
  }

  // Reset dismiss count when user connects
  Future<void> markHealthConnected() async {
    await _prefs.setBool(_healthConnectedKey, true);
    await _prefs.setInt(_healthPromptDismissedCountKey, 0);
    await _prefs.setBool(_shouldShowSyncIndicatorKey, true);
  }

  // Request health permissions with proper error handling
  Future<HealthPermissionResult> requestHealthPermissions(BuildContext context) async {
    try {
      // Show loading indicator
      _showLoadingDialog(context);

      // Check platform and request permissions
      final result = await healthService.requestHealthPermissions();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Mark as connected
        await markHealthConnected();

        // Trigger immediate sync
        await healthProvider.syncWithHealth();

        return HealthPermissionResult(
          success: true,
          message: 'Health data connected successfully!',
        );
      } else {
        // Handle specific errors
        String errorMessage = 'Failed to connect health data.';
        String actionRequired = '';

        switch (result.error) {
          case HealthConnectionError.healthConnectNotInstalled:
            errorMessage = 'Health Connect is not installed on your device.';
            actionRequired = 'Please install Health Connect from the Play Store.';
            break;
          case HealthConnectionError.permissionsDenied:
            errorMessage = 'Health permissions were denied.';
            actionRequired = 'You can grant permissions later in Settings.';
            break;
          case HealthConnectionError.configurationFailed:
            errorMessage = 'Failed to configure health services.';
            actionRequired = 'Please try again later.';
            break;
          default:
            errorMessage = result.errorMessage ?? 'An unknown error occurred.';
        }

        return HealthPermissionResult(
          success: false,
          message: errorMessage,
          actionRequired: actionRequired,
          error: result.error,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      return HealthPermissionResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Show loading dialog while requesting permissions
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                Platform.isIOS
                  ? 'Requesting HealthKit permissions...'
                  : 'Connecting to Health Connect...',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Please grant all permissions when prompted',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check if sync indicator should be shown
  bool shouldShowSyncIndicator() {
    return _prefs.getBool(_shouldShowSyncIndicatorKey) ?? false;
  }

  // Hide sync indicator after first successful sync
  Future<void> hideSyncIndicator() async {
    await _prefs.setBool(_shouldShowSyncIndicatorKey, false);
  }

  // Get re-engagement message based on dismiss count
  String getReengagementMessage() {
    final dismissedCount = _prefs.getInt(_healthPromptDismissedCountKey) ?? 0;

    switch (dismissedCount) {
      case 1:
        return 'You\'re missing out on real health insights!';
      case 2:
        return 'Your fitness data is waiting to be unlocked';
      default:
        return 'Connect your health data for accurate tracking';
    }
  }

  // Check if we're using demo data
  bool isUsingDemoData() {
    return !healthProvider.isHealthSourceConnected;
  }
}

class HealthPermissionResult {
  final bool success;
  final String message;
  final String? actionRequired;
  final HealthConnectionError? error;

  HealthPermissionResult({
    required this.success,
    required this.message,
    this.actionRequired,
    this.error,
  });
}