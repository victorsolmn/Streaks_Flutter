import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../services/version_manager_service.dart';

class ForceUpdateDialog extends StatelessWidget {
  final UpdateCheckResult updateResult;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  const ForceUpdateDialog({
    Key? key,
    required this.updateResult,
    this.onUpdate,
    this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final canDismiss = !updateResult.forceUpdate && updateResult.updateSeverity != 'critical';

    // Maintenance mode dialog
    if (updateResult.maintenanceMode) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Maintenance Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.construction,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),

                // Title
                Text(
                  'Under Maintenance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Message
                Text(
                  updateResult.maintenanceMessage ??
                  'We\'re updating our servers to bring you a better experience. Please check back in a few minutes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the app
                      Navigator.of(context).popUntil((route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade500,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Update dialog
    return WillPopScope(
      onWillPop: () async => canDismiss,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon based on severity
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: _getGradientBySeverity(updateResult.updateSeverity),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconBySeverity(updateResult.updateSeverity),
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),

              // Title
              Text(
                _getTitleBySeverity(updateResult.updateSeverity),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Version info
              if (updateResult.currentVersion != null && updateResult.requiredVersion != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                      ? Colors.grey[900]
                      : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v${updateResult.currentVersion}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                      Text(
                        'v${updateResult.requiredVersion}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),

              // Message
              Text(
                updateResult.updateMessage ?? _getDefaultMessage(updateResult.updateSeverity),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              // Features list (if available)
              if (updateResult.features.isNotEmpty) ...[
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                      ? Colors.grey[900]?.withOpacity(0.5)
                      : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...updateResult.features.map((feature) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          feature,
                          style: TextStyle(fontSize: 13),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),

              // Action buttons
              if (updateResult.forceUpdate || updateResult.updateSeverity == 'critical') ...[
                // Force update - single button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpdate ?? () {
                      VersionManagerService().openAppStore(
                        customUrl: updateResult.updateUrl,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Optional update - two buttons
                Row(
                  children: [
                    if (canDismiss) ...[
                      Expanded(
                        child: TextButton(
                          onPressed: onLater ?? () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Later'),
                        ),
                      ),
                      SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onUpdate ?? () {
                          VersionManagerService().openAppStore(
                            customUrl: updateResult.updateUrl,
                          );
                          if (canDismiss) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],

              // Skip version option for recommended updates
              if (updateResult.updateSeverity == 'recommended' && !updateResult.forceUpdate) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    // Save preference to skip this version
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'skipped_version',
                      updateResult.requiredVersion ?? '',
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Skip this version',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientBySeverity(String severity) {
    switch (severity) {
      case 'critical':
        return LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        );
      case 'required':
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        );
      case 'recommended':
        return AppTheme.primaryGradient;
      default:
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        );
    }
  }

  IconData _getIconBySeverity(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'required':
        return Icons.system_update;
      case 'recommended':
        return Icons.arrow_circle_up;
      default:
        return Icons.info_outline;
    }
  }

  String _getTitleBySeverity(String severity) {
    switch (severity) {
      case 'critical':
        return 'Critical Update Required';
      case 'required':
        return 'Update Required';
      case 'recommended':
        return 'Update Available';
      default:
        return 'New Version Available';
    }
  }

  String _getDefaultMessage(String severity) {
    switch (severity) {
      case 'critical':
        return 'This update contains critical fixes and must be installed to continue using Streaker.';
      case 'required':
        return 'Please update to the latest version to continue using all features of Streaker.';
      case 'recommended':
        return 'A new version of Streaker is available with improvements and new features.';
      default:
        return 'A new version is available. Update now to get the latest features.';
    }
  }
}

// Helper method to show the dialog
Future<void> showForceUpdateDialog(
  BuildContext context,
  UpdateCheckResult updateResult,
) async {
  final canDismiss = !updateResult.forceUpdate &&
                     updateResult.updateSeverity != 'critical' &&
                     !updateResult.maintenanceMode;

  await showDialog(
    context: context,
    barrierDismissible: canDismiss,
    builder: (context) => ForceUpdateDialog(
      updateResult: updateResult,
    ),
  );
}