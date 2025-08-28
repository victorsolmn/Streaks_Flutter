import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../services/unified_health_service.dart';
import '../utils/app_theme.dart';
import 'health_connect_setup_guide.dart';

class HealthSourceIndicator extends StatelessWidget {
  const HealthSourceIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, healthProvider, child) {
        final sourceInfo = healthProvider.dataSourceInfo;
        final dataSource = healthProvider.dataSource;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        Color statusColor;
        IconData statusIcon;
        String tooltip;
        
        switch (dataSource) {
          case HealthDataSource.healthKit:
          case HealthDataSource.healthConnect:
            statusColor = AppTheme.successGreen;
            statusIcon = Icons.sync;
            tooltip = sourceInfo['description'] ?? 'Connected';
            break;
          case HealthDataSource.bluetooth:
            statusColor = AppTheme.secondaryLight;
            statusIcon = Icons.bluetooth_connected;
            tooltip = sourceInfo['description'] ?? 'Connected via Bluetooth';
            break;
          case HealthDataSource.unavailable:
            statusColor = AppTheme.warningYellow;
            statusIcon = Icons.sync_disabled;
            tooltip = 'Tap to connect health source';
            break;
        }
        
        return InkWell(
          onTap: () => _showHealthSourceDialog(context, healthProvider, dataSource),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  sourceInfo['icon'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    sourceInfo['source'] ?? 'Not Connected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showHealthSourceDialog(BuildContext context, HealthProvider healthProvider, HealthDataSource currentSource) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: AppTheme.primaryAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Health Data Source',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    if (currentSource == HealthDataSource.unavailable) ...[
                      _buildConnectionOption(
                        context,
                        icon: Icons.favorite,
                        title: 'Connect Health App',
                        subtitle: Theme.of(context).platform == TargetPlatform.iOS 
                          ? 'Connect to Apple Health'
                          : 'Connect to Samsung Health or Google Fit',
                        onTap: () async {
                          Navigator.pop(context);
                          
                          // Show setup guide for Android
                          if (Theme.of(context).platform == TargetPlatform.android) {
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => const HealthConnectSetupGuide(),
                            );
                            
                            if (result != 'continue') return;
                          }
                          
                          // Show loading while requesting permissions
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: AppTheme.primaryAccent),
                                    const SizedBox(height: 16),
                                    const Text('Requesting permissions...'),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          bool authorized = await healthProvider.requestHealthPermissions();
                          
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog
                            
                            if (authorized) {
                              // Start syncing data
                              await healthProvider.syncWithHealth();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Health Connect connected successfully!'),
                                  backgroundColor: AppTheme.successGreen,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please grant all health permissions to sync data'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildConnectionOption(
                        context,
                        icon: Icons.bluetooth,
                        title: 'Connect Bluetooth Device',
                        subtitle: 'Connect directly to your smartwatch',
                        onTap: () async {
                          Navigator.pop(context);
                          _showBluetoothScanDialog(context, healthProvider);
                        },
                        isDarkMode: isDarkMode,
                      ),
                    ] else ...[
                      _buildCurrentSource(context, healthProvider, isDarkMode),
                      const SizedBox(height: 16),
                      
                      if (currentSource == HealthDataSource.bluetooth) ...[
                        _buildActionButton(
                          context,
                          icon: Icons.bluetooth_disabled,
                          label: 'Disconnect Device',
                          color: AppTheme.errorRed,
                          onTap: () async {
                            Navigator.pop(context);
                            await healthProvider.disconnectBluetoothDevice();
                          },
                        ),
                      ] else ...[
                        _buildActionButton(
                          context,
                          icon: Icons.sync,
                          label: 'Sync Now',
                          color: AppTheme.primaryAccent,
                          onTap: () async {
                            Navigator.pop(context);
                            await healthProvider.syncWithHealth();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Health data synced successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          context,
                          icon: Icons.bluetooth_searching,
                          label: 'Use Bluetooth Instead',
                          color: AppTheme.secondaryLight,
                          onTap: () async {
                            Navigator.pop(context);
                            _showBluetoothScanDialog(context, healthProvider);
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildCurrentSource(BuildContext context, HealthProvider healthProvider, bool isDarkMode) {
    final sourceInfo = healthProvider.dataSourceInfo;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to ${sourceInfo['source']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sourceInfo['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sourceInfo['icon'] ?? '',
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white30 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  void _showBluetoothScanDialog(BuildContext context, HealthProvider healthProvider) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bluetooth_searching, color: AppTheme.primaryAccent),
            const SizedBox(width: 12),
            const Text('Scanning for devices...'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryAccent),
            const SizedBox(height: 16),
            Text(
              'Make sure your smartwatch is nearby and Bluetooth is enabled',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    
    try {
      final devices = await healthProvider.scanForBluetoothDevices();
      
      if (context.mounted) {
        Navigator.pop(context); // Close scanning dialog
        
        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No smartwatches found. Make sure your device is not already connected to another app.'),
            ),
          );
          return;
        }
        
        // Show device selection dialog
        showModalBottomSheet(
          context: context,
          backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Device',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...devices.map((device) => ListTile(
                      leading: Icon(
                        Icons.watch,
                        color: AppTheme.primaryAccent,
                      ),
                      title: Text(
                        device['name'] ?? 'Unknown Device',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Signal: ${device['rssi']} dBm',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Show connecting dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDarkMode ? AppTheme.darkCardBackground : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryAccent),
                                const SizedBox(height: 16),
                                Text(
                                  'Connecting to ${device['name']}...',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        bool connected = await healthProvider.connectBluetoothDevice(device);
                        
                        if (context.mounted) {
                          Navigator.pop(context); // Close connecting dialog
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                connected 
                                  ? 'Connected to ${device['name']}' 
                                  : 'Failed to connect to ${device['name']}'
                              ),
                            ),
                          );
                        }
                      },
                    )),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close scanning dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }
}