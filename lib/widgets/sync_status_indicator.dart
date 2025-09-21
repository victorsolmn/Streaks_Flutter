import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../utils/app_theme.dart';

class SyncStatusIndicator extends StatefulWidget {
  final bool showLabel;
  final bool isCompact;

  const SyncStatusIndicator({
    Key? key,
    this.showLabel = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, healthProvider, _) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final isConnected = healthProvider.isHealthSourceConnected;
        final isSyncing = healthProvider.isSyncing;

        // Start or stop animation based on sync state
        if (isSyncing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
          _rotationController.reset();
        }

        if (!isConnected) {
          // Don't show anything if health is not connected
          return const SizedBox.shrink();
        }

        if (widget.isCompact) {
          // Compact version for app bar
          return _buildCompactIndicator(healthProvider, isSyncing, isDarkMode);
        }

        // Full version with label
        return _buildFullIndicator(healthProvider, isSyncing, isDarkMode);
      },
    );
  }

  Widget _buildDemoDataBadge(bool isDarkMode) {
    if (widget.isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Demo',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Colors.orange,
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 6),
            const Text(
              'Demo Data',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(
    HealthProvider healthProvider,
    bool isSyncing,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: isSyncing ? null : () => _handleSync(healthProvider),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSyncing
              ? AppTheme.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: RotationTransition(
          turns: _rotationController,
          child: Icon(
            Icons.sync,
            size: 20,
            color: isSyncing
                ? AppTheme.primaryAccent
                : (isDarkMode ? Colors.white70 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildFullIndicator(
    HealthProvider healthProvider,
    bool isSyncing,
    bool isDarkMode,
  ) {
    final hasRecentSync = healthProvider.hasRecentSync;

    return GestureDetector(
      onTap: isSyncing ? null : () => _handleSync(healthProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSyncing
              ? AppTheme.primaryAccent.withOpacity(0.1)
              : hasRecentSync
                  ? AppTheme.successGreen.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.sync,
                size: 16,
                color: isSyncing
                    ? AppTheme.primaryAccent
                    : hasRecentSync
                        ? AppTheme.successGreen
                        : Colors.grey,
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                isSyncing
                    ? 'Syncing...'
                    : hasRecentSync
                        ? 'Synced'
                        : 'Sync',
                style: TextStyle(
                  color: isSyncing
                      ? AppTheme.primaryAccent
                      : hasRecentSync
                          ? AppTheme.successGreen
                          : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleSync(HealthProvider healthProvider) async {
    await healthProvider.syncWithHealth();
  }
}

// Mini version for use in app bar
class MiniSyncIndicator extends StatelessWidget {
  const MiniSyncIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SyncStatusIndicator(
      showLabel: false,
      isCompact: true,
    );
  }
}