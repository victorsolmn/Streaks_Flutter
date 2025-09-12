import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/app_theme.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
  loading,
}

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  late FToast _fToast;
  bool _isInitialized = false;

  void initialize(BuildContext context) {
    _fToast = FToast();
    _fToast.init(context);
    _isInitialized = true;
  }

  // Show floating toast message
  void showToast({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool isDismissible = true,
  }) {
    if (!_isInitialized) {
      debugPrint('ToastService not initialized. Call initialize(context) first.');
      return;
    }

    _fToast.removeQueuedCustomToasts();
    
    Widget toast = _buildToastWidget(message, type, isDismissible);
    
    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.TOP,
      toastDuration: duration,
    );
  }

  Widget _buildToastWidget(String message, ToastType type, bool isDismissible) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppTheme.successGreen;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        backgroundColor = AppTheme.errorRed;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.warning_rounded;
        break;
      case ToastType.loading:
        backgroundColor = AppTheme.primaryAccent;
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.hourglass_empty_rounded;
        break;
      case ToastType.info:
      default:
        backgroundColor = const Color(0xFF2196F3);
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDismissible) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _fToast.removeCustomToast(),
              child: Icon(
                Icons.close_rounded,
                color: iconColor.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Convenience methods
  void showSuccess(String message, {Duration? duration, bool isDismissible = true}) {
    showToast(
      message: message,
      type: ToastType.success,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: isDismissible,
    );
  }

  void showError(String message, {Duration? duration, bool isDismissible = true}) {
    showToast(
      message: message,
      type: ToastType.error,
      duration: duration ?? const Duration(seconds: 4),
      isDismissible: isDismissible,
    );
  }

  void showWarning(String message, {Duration? duration, bool isDismissible = true}) {
    showToast(
      message: message,
      type: ToastType.warning,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: isDismissible,
    );
  }

  void showInfo(String message, {Duration? duration, bool isDismissible = true}) {
    showToast(
      message: message,
      type: ToastType.info,
      duration: duration ?? const Duration(seconds: 3),
      isDismissible: isDismissible,
    );
  }

  void showLoading(String message, {Duration? duration}) {
    showToast(
      message: message,
      type: ToastType.loading,
      duration: duration ?? const Duration(seconds: 2),
      isDismissible: false,
    );
  }

  // Clear all toasts
  void clearAll() {
    if (_isInitialized) {
      _fToast.removeQueuedCustomToasts();
    }
  }
}