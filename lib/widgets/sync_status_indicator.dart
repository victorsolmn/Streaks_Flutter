import 'package:flutter/material.dart';
import '../services/realtime_sync_service.dart';

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
    if (!_isOnline) {
      return IconButton(
        icon: Stack(
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.orange,
            ),
            if (_offlineQueueSize > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$_offlineQueueSize',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Offline Mode'),
              content: Text(
                _offlineQueueSize > 0
                    ? 'You are currently offline. $_offlineQueueSize changes will sync when connection is restored.'
                    : 'You are currently offline. Changes will sync when connection is restored.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        tooltip: 'Offline - $_offlineQueueSize pending',
      );
    }

    if (_isSyncing) {
      return IconButton(
        icon: RotationTransition(
          turns: _animationController,
          child: const Icon(
            Icons.sync,
            color: Colors.blue,
          ),
        ),
        onPressed: null,
        tooltip: 'Syncing...',
      );
    }

    return IconButton(
      icon: const Icon(
        Icons.cloud_done,
        color: Colors.green,
      ),
      onPressed: () async {
        await _syncService.forceSyncNow();
      },
      tooltip: 'Synced - Tap to sync now',
    );
  }
}