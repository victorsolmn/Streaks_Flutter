import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/realtime_sync_service.dart';
import '../providers/health_provider.dart';
import '../providers/nutrition_provider.dart';
import '../utils/app_theme.dart';

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({Key? key}) : super(key: key);

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> with SingleTickerProviderStateMixin {
  final RealtimeSyncService _syncService = RealtimeSyncService();
  late AnimationController _animationController;
  bool _isSyncing = false;
  bool _isOnline = true;
  int _offlineQueueSize = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    // Set up callbacks
    _syncService.onSyncStatusChanged = _onSyncStatusChanged;
    _syncService.onSyncError = _onSyncError;
    
    // Initial state
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _isSyncing = _syncService.isSyncing;
      _isOnline = _syncService.isOnline;
      _offlineQueueSize = _syncService.offlineQueueSize;
    });

    if (_isSyncing) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  void _onSyncStatusChanged(bool isSyncing) {
    _updateStatus();
  }

  void _onSyncError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _syncService.onSyncStatusChanged = null;
    _syncService.onSyncError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers for sync status
    final healthProvider = Provider.of<HealthProvider>(context);
    final nutritionProvider = Provider.of<NutritionProvider>(context);
    
    // Update sync status based on providers
    final isProviderSyncing = healthProvider.isLoading || nutritionProvider.isLoading;
    if (isProviderSyncing != _isSyncing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isSyncing = isProviderSyncing;
          if (_isSyncing) {
            _animationController.repeat();
          } else {
            _animationController.stop();
            _lastSyncTime = DateTime.now();
          }
        });
      });
    }
    if (!_isOnline) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              color: Colors.orange,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              _offlineQueueSize > 0 ? 'Offline ($_offlineQueueSize)' : 'Offline',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isSyncing) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              child: Icon(
                Icons.sync,
                color: AppTheme.primaryAccent,
                size: 16,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Syncing',
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
    
    return GestureDetector(
      onTap: () async {
        setState(() {
          _isSyncing = true;
        });
        _animationController.repeat();
        
        // Trigger manual sync
        await Future.wait([
          healthProvider.syncWithHealth(),
          nutritionProvider.loadDataFromSupabase(),
        ]);
        
        setState(() {
          _isSyncing = false;
          _lastSyncTime = DateTime.now();
        });
        _animationController.stop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Data synced successfully'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              color: AppTheme.successGreen,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              _lastSyncTime != null
                  ? 'Synced ${_getTimeSinceSync()}'
                  : 'Synced',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTimeSinceSync() {
    if (_lastSyncTime == null) return '';
    
    final difference = DateTime.now().difference(_lastSyncTime!);
    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}