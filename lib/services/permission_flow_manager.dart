import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages the Health Connect permission flow lifecycle
/// Prevents navigation issues during permission granting
class PermissionFlowManager with WidgetsBindingObserver {
  static final PermissionFlowManager _instance = PermissionFlowManager._internal();
  factory PermissionFlowManager() => _instance;
  PermissionFlowManager._internal();

  // Track if permission flow is active
  bool _isPermissionFlowActive = false;
  bool get isPermissionFlowActive => _isPermissionFlowActive;

  // Track if we're waiting for user to return from settings
  bool _isWaitingForSettingsReturn = false;
  bool get isWaitingForSettingsReturn => _isWaitingForSettingsReturn;

  // Callback for when user returns from settings
  Function()? _onSettingsReturn;

  // Stream controller for permission flow state
  final _flowStateController = StreamController<PermissionFlowState>.broadcast();
  Stream<PermissionFlowState> get flowStateStream => _flowStateController.stream;

  // Current state
  PermissionFlowState _currentState = PermissionFlowState.idle;
  PermissionFlowState get currentState => _currentState;

  // Initialize the manager
  void initialize() {
    debugPrint('🔧 PermissionFlowManager: Initializing');
    WidgetsBinding.instance.addObserver(this);
  }

  // Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flowStateController.close();
  }

  // Start permission flow
  void startPermissionFlow() {
    debugPrint('🚀 PermissionFlowManager: Starting permission flow');
    _isPermissionFlowActive = true;
    _updateState(PermissionFlowState.requesting);
  }

  // Mark that we're opening settings
  void markOpeningSettings({Function()? onReturn}) {
    debugPrint('📱 PermissionFlowManager: Opening Health Connect settings');
    _isWaitingForSettingsReturn = true;
    _onSettingsReturn = onReturn;
    _updateState(PermissionFlowState.inSettings);
  }

  // End permission flow
  void endPermissionFlow({bool success = false}) {
    debugPrint('✅ PermissionFlowManager: Ending permission flow (success: $success)');
    _isPermissionFlowActive = false;
    _isWaitingForSettingsReturn = false;
    _onSettingsReturn = null;
    _updateState(success ? PermissionFlowState.completed : PermissionFlowState.failed);

    // Reset to idle after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateState(PermissionFlowState.idle);
    });
  }

  // Update state and notify listeners
  void _updateState(PermissionFlowState newState) {
    _currentState = newState;
    _flowStateController.add(newState);
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 PermissionFlowManager: App lifecycle changed to $state');

    if (state == AppLifecycleState.resumed && _isWaitingForSettingsReturn) {
      debugPrint('👁️ PermissionFlowManager: App resumed from settings');
      _isWaitingForSettingsReturn = false;
      _updateState(PermissionFlowState.checkingPermissions);

      // Call the return callback after a small delay to ensure UI is ready
      if (_onSettingsReturn != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          debugPrint('🔍 PermissionFlowManager: Triggering permission recheck');
          _onSettingsReturn?.call();
        });
      }
    }
  }

  // Check if navigation should be blocked
  bool shouldBlockNavigation() {
    // Block navigation if we're in the middle of permission flow
    // but not if we're just checking permissions
    return _isPermissionFlowActive &&
           _currentState != PermissionFlowState.checkingPermissions &&
           _currentState != PermissionFlowState.idle;
  }

  // Get user-friendly message for current state
  String getStateMessage() {
    switch (_currentState) {
      case PermissionFlowState.idle:
        return '';
      case PermissionFlowState.requesting:
        return 'Requesting health permissions...';
      case PermissionFlowState.inSettings:
        return 'Please grant all permissions in Health Connect settings';
      case PermissionFlowState.checkingPermissions:
        return 'Checking permissions...';
      case PermissionFlowState.completed:
        return 'Permissions granted successfully!';
      case PermissionFlowState.failed:
        return 'Permission setup incomplete';
    }
  }
}

// Permission flow states
enum PermissionFlowState {
  idle,
  requesting,
  inSettings,
  checkingPermissions,
  completed,
  failed,
}