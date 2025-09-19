import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../providers/nutrition_provider.dart';
import '../utils/app_theme.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Initialize last sync time to now (assuming data is fresh on start)
    _lastSyncTime = DateTime.now();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performManualSync() async {
    // Prevent multiple sync requests
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });
    _animationController.repeat();

    try {
      // Access providers without listening to prevent rebuilds
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

      // Perform sync operations
      await Future.wait([
        // Health sync
        healthProvider.syncWithHealth(),
        // Nutrition sync
        nutritionProvider.syncOnPause(),
      ]);

      // Update last sync time
      _lastSyncTime = DateTime.now();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ All data synced successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString().split('\n').first}'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Stop syncing animation
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  String _getTimeSinceSync() {
    if (_lastSyncTime == null) return 'never';

    final difference = DateTime.now().difference(_lastSyncTime!);

    if (difference.inSeconds < 10) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If syncing, show syncing indicator
    if (_isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _animationController,
              child: const Icon(
                Icons.sync,
                color: AppTheme.primaryAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Syncing...',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show sync button when not syncing
    return GestureDetector(
      onTap: _performManualSync,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              color: AppTheme.primaryAccent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Sync',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_lastSyncTime != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${_getTimeSinceSync()})',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}