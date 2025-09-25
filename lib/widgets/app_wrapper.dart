import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/version_manager_service.dart';
import 'force_update_dialog.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  final VersionManagerService _versionManager = VersionManagerService();
  bool _isCheckingVersion = false;
  bool _hasCheckedVersion = false;
  UpdateCheckResult? _updateResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check version on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersion();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check version when app comes to foreground
    if (state == AppLifecycleState.resumed && _hasCheckedVersion) {
      _checkAppVersion(skipCache: true);
    }
  }

  Future<void> _checkAppVersion({bool skipCache = false}) async {
    // Skip version check in development mode unless explicitly testing
    if (_versionManager.shouldSkipVersionCheck()) {
      setState(() {
        _hasCheckedVersion = true;
      });
      return;
    }

    // Avoid multiple simultaneous checks
    if (_isCheckingVersion) return;

    setState(() {
      _isCheckingVersion = true;
    });

    try {
      final result = await _versionManager.checkForUpdate(skipCache: skipCache);

      setState(() {
        _updateResult = result;
        _hasCheckedVersion = true;
        _isCheckingVersion = false;
      });

      // Show update dialog if needed
      if (result.updateRequired || result.maintenanceMode) {
        if (mounted) {
          _showUpdateDialog(result);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking app version: $e');
      }
      setState(() {
        _isCheckingVersion = false;
        _hasCheckedVersion = true;
      });
    }
  }

  void _showUpdateDialog(UpdateCheckResult result) {
    // Check if dialog is already showing
    if (!mounted) return;

    final canDismiss = !result.forceUpdate &&
                       result.updateSeverity != 'critical' &&
                       !result.maintenanceMode;

    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => canDismiss,
        child: ForceUpdateDialog(
          updateResult: result,
          onUpdate: () {
            // Open store for update
            _versionManager.openAppStore(customUrl: result.updateUrl);

            // If it's not a force update, close dialog
            if (canDismiss) {
              Navigator.of(dialogContext).pop();
            }
          },
          onLater: canDismiss ? () {
            Navigator.of(dialogContext).pop();

            // For recommended updates, check again after a delay
            if (result.updateSeverity == 'recommended') {
              Future.delayed(const Duration(hours: 24), () {
                if (mounted) {
                  _checkAppVersion(skipCache: true);
                }
              });
            }
          } : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking initial version
    if (!_hasCheckedVersion && _isCheckingVersion) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Checking for updates...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // If we have a critical update or maintenance mode, block app usage
    if (_updateResult != null &&
        (_updateResult!.maintenanceMode ||
         (_updateResult!.forceUpdate && _updateResult!.updateRequired))) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _updateResult!.maintenanceMode
                    ? Icons.construction
                    : Icons.system_update,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                _updateResult!.maintenanceMode
                    ? 'Under Maintenance'
                    : 'Update Required',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _updateResult!.maintenanceMode
                      ? _updateResult!.maintenanceMessage ?? 'The app is currently under maintenance. Please try again later.'
                      : 'Please update the app to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              if (!_updateResult!.maintenanceMode)
                ElevatedButton.icon(
                  onPressed: () {
                    _versionManager.openAppStore(customUrl: _updateResult!.updateUrl);
                  },
                  icon: const Icon(Icons.update),
                  label: const Text('Update Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Normal app flow
    return widget.child;
  }
}