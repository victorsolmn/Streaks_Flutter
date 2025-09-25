import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../providers/health_provider.dart';
import '../services/unified_health_service.dart';
import '../services/permission_flow_manager.dart';
import '../widgets/android_health_permission_guide.dart';

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
    // Check if already marked as connected in preferences
    final isConnected = _prefs.getBool(_healthConnectedKey) ?? false;
    if (isConnected) {
      return false;
    }

    // If already connected via provider, don't show
    if (healthProvider.isHealthSourceConnected) {
      // Also mark in preferences to avoid future checks
      await _prefs.setBool(_healthConnectedKey, true);
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
      // Initialize and start permission flow
      final permissionManager = PermissionFlowManager();
      permissionManager.initialize();
      permissionManager.startPermissionFlow();

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

        // End permission flow with success
        permissionManager.endPermissionFlow(success: true);

        return HealthPermissionResult(
          success: true,
          message: 'Health data connected successfully!',
        );
      } else {
        // Check if settings were opened (special case for Android)
        final settingsOpened = result.debugInfo?.contains('settings_opened') ?? false;

        if (settingsOpened && Platform.isAndroid) {
          // Settings were opened successfully, don't show error
          if (context.mounted) {
            // Mark that we're waiting for settings return
            permissionManager.markOpeningSettings(onReturn: () async {
              // Recheck permissions when app resumes
              if (context.mounted) {
                await _recheckPermissionsAfterSettings(context);
              }
            });

            // Show waiting dialog
            await _showWaitingForPermissionsDialog(context);

            // After waiting dialog closes, permissions were either granted or denied
            // The dialog self-closes based on state, so we can check here
            final finalState = permissionManager.currentState;

            if (finalState == PermissionFlowState.completed) {
              return HealthPermissionResult(
                success: true,
                message: 'Health Connect permissions granted successfully!',
              );
            } else {
              return HealthPermissionResult(
                success: false,
                message: 'Health Connect setup incomplete',
                actionRequired: 'You can grant permissions later from Settings',
                error: result.error,
              );
            }
          }
        }

        // Handle other errors
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

        // End permission flow with failure
        permissionManager.endPermissionFlow(success: false);

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

      // End permission flow with failure
      PermissionFlowManager().endPermissionFlow(success: false);

      return HealthPermissionResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Show waiting dialog while user is in settings
  Future<void> _showWaitingForPermissionsDialog(BuildContext context) async {
    final permissionManager = PermissionFlowManager();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StreamBuilder<PermissionFlowState>(
        stream: permissionManager.flowStateStream,
        initialData: permissionManager.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? PermissionFlowState.idle;

          // Auto-close dialog when permissions are granted or failed
          if (state == PermissionFlowState.completed || state == PermissionFlowState.failed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(dialogContext)) {
                Navigator.of(dialogContext).pop();
              }
            });
          }

          return Dialog(
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
                  if (state == PermissionFlowState.checkingPermissions)
                    const CircularProgressIndicator()
                  else
                    const Icon(
                      Icons.health_and_safety,
                      size: 48,
                      color: Colors.blue,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    state == PermissionFlowState.checkingPermissions
                        ? 'Checking permissions...'
                        : 'Waiting for Health Connect',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state == PermissionFlowState.checkingPermissions
                        ? 'Please wait while we verify your permissions...'
                        : 'Please grant all permissions in Health Connect settings and return to the app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state == PermissionFlowState.inSettings) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Recheck permissions after returning from settings
  Future<void> _recheckPermissionsAfterSettings(BuildContext context) async {
    final permissionManager = PermissionFlowManager();

    try {
      // State will be updated automatically by the manager on app resume

      // Wait a bit for system to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if permissions were granted
      final hasPermissions = await healthService.hasHealthPermissions();

      if (hasPermissions) {
        // Permissions granted!
        await markHealthConnected();
        await healthProvider.syncWithHealth();

        permissionManager.endPermissionFlow(success: true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health Connect permissions granted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Permissions still not granted
        permissionManager.endPermissionFlow(success: false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health Connect permissions were not granted. You can try again from Settings.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      permissionManager.endPermissionFlow(success: false);
      print('Error rechecking permissions: $e');
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