import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/unified_health_service.dart';
import '../../services/native_health_connect_service.dart';
import '../../utils/app_theme.dart';
import '../main/main_screen.dart';
import 'dart:io' show Platform;

class SmartwatchConnectionScreen extends StatefulWidget {
  const SmartwatchConnectionScreen({Key? key}) : super(key: key);

  @override
  State<SmartwatchConnectionScreen> createState() => _SmartwatchConnectionScreenState();
}

class _SmartwatchConnectionScreenState extends State<SmartwatchConnectionScreen> 
    with SingleTickerProviderStateMixin {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectedDevice;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  final UnifiedHealthService _healthService = UnifiedHealthService();
  final NativeHealthConnectService _nativeHealthService = NativeHealthConnectService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
    
    // Check for existing connections
    _checkExistingConnections();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConnections() async {
    if (Platform.isAndroid) {
      // Check if Health Connect is available
      try {
        final testResult = await _nativeHealthService.testHealthConnectFlow();
        if (testResult['available'] == true) {
          setState(() {
            _connectedDevice = 'Health Connect';
          });
        }
      } catch (e) {
        // Health Connect not available
      }
    }
  }

  Future<void> _connectToHealthSource() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      if (Platform.isAndroid) {
        // Android: Connect to Health Connect
        await _connectToHealthConnect();
      } else if (Platform.isIOS) {
        // iOS: Connect to HealthKit
        await _connectToHealthKit();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect: ${e.toString()}';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectToHealthConnect() async {
    try {
      // Initialize health provider first
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      
      // Initialize if not already done
      if (!healthProvider.isInitialized) {
        await healthProvider.initialize();
      }
      
      // Request permissions using the unified health service (like profile does)
      final result = await healthProvider.healthService.requestHealthPermissions();
      
      if (result.success) {
        
        // Connect to health source
        await healthProvider.connectToHealthSource(HealthDataSource.healthConnect);
        
        // Sync with health data
        await healthProvider.syncWithHealth();
        
        // Save the connection state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connect_connected', true);
        await prefs.setString('connected_health_source', 'healthConnect');
        
        setState(() {
          _isConnected = true;
          _connectedDevice = 'Samsung Health / Google Fit';
          _isConnecting = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Connected to Health Connect'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        // Wait a moment for user to see the success state
        await Future.delayed(Duration(seconds: 2));
        _navigateToHome();
      } else {
        // Show specific error message based on the error type
        String errorMessage = 'Failed to connect';
        if (result.error == HealthConnectionError.permissionsDenied) {
          errorMessage = 'Please grant all requested permissions to connect';
        } else if (result.error == HealthConnectionError.healthConnectNotInstalled) {
          errorMessage = 'Health Connect is not installed. Please install it from Play Store';
        } else if (result.error == HealthConnectionError.healthConnectNeedsUpdate) {
          errorMessage = 'Health Connect needs to be updated';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _connectToHealthKit() async {
    try {
      // Initialize health provider first
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);
      
      // Initialize if not already done
      if (!healthProvider.isInitialized) {
        await healthProvider.initialize();
      }
      
      // Request permissions using the unified health service
      final result = await healthProvider.healthService.requestHealthPermissions();
      
      if (result.success) {
        
        // Connect to health source
        await healthProvider.connectToHealthSource(HealthDataSource.healthKit);
        
        // Sync with health data
        await healthProvider.syncWithHealth();
        
        // Save the connection state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_kit_connected', true);
        await prefs.setString('connected_health_source', 'healthKit');
        
        setState(() {
          _isConnected = true;
          _connectedDevice = 'Apple Health';
          _isConnecting = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Connected to Apple Health'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        // Wait a moment for user to see the success state
        await Future.delayed(Duration(seconds: 2));
        _navigateToHome();
      } else {
        // Show specific error message
        String errorMessage = 'Failed to connect';
        if (result.error == HealthConnectionError.permissionsDenied) {
          errorMessage = 'Please grant all requested permissions to connect';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _connectToBluetooth() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Request Bluetooth permissions
      final bluetoothPermission = await Permission.bluetoothScan.request();
      final bluetoothConnectPermission = await Permission.bluetoothConnect.request();
      
      if (bluetoothPermission.isGranted && bluetoothConnectPermission.isGranted) {
        // TODO: Implement actual Bluetooth device scanning and connection
        // For now, simulate connection
        await Future.delayed(Duration(seconds: 2));
        
        setState(() {
          _isConnected = true;
          _connectedDevice = 'Bluetooth Smartwatch';
          _isConnecting = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Connected via Bluetooth'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        
        await Future.delayed(Duration(seconds: 2));
        _navigateToHome();
      } else {
        throw Exception('Bluetooth permissions not granted');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect via Bluetooth: ${e.toString()}';
        _isConnecting = false;
      });
    }
  }

  void _skipConnection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Connection?'),
        content: Text(
          'You can connect your smartwatch later from the Profile settings. '
          'Without a connected device, some health metrics won\'t be available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
            child: Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect Your Device'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isConnecting ? null : _skipConnection,
            child: Text(
              'Skip',
              style: TextStyle(
                color: _isConnecting ? Colors.grey : AppTheme.primaryAccent,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: 1.0, // Last step
                backgroundColor: AppTheme.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
              ),
              
              SizedBox(height: 32),
              
              // Icon and Title
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isConnecting ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isConnected ? Icons.check : Icons.watch,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 32),
              
              Text(
                _isConnected 
                  ? 'Connected Successfully!' 
                  : 'Connect Your Smartwatch',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16),
              
              Text(
                _isConnected
                  ? 'Your health data is now syncing'
                  : 'For a personalized experience, please connect to your smartwatch or health app',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              if (_connectedDevice != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        color: AppTheme.successGreen,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _connectedDevice!,
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              Spacer(),
              
              // Connection Options
              if (!_isConnected && !_isConnecting) ...[
                Text(
                  'Choose Connection Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 24),
                
                // Health App Connection (Primary)
                _buildConnectionOption(
                  icon: Platform.isAndroid ? Icons.favorite : Icons.favorite,
                  title: Platform.isAndroid ? 'Samsung Health / Google Fit' : 'Apple Health',
                  subtitle: 'Recommended for best experience',
                  onTap: _connectToHealthSource,
                  isPrimary: true,
                  isDarkMode: isDarkMode,
                ),
                
                SizedBox(height: 16),
                
                // Bluetooth Connection (Secondary)
                _buildConnectionOption(
                  icon: Icons.bluetooth,
                  title: 'Bluetooth Smartwatch',
                  subtitle: 'Connect directly via Bluetooth',
                  onTap: _connectToBluetooth,
                  isPrimary: false,
                  isDarkMode: isDarkMode,
                ),
              ],
              
              if (_isConnecting) ...[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                ),
                SizedBox(height: 16),
                Text(
                  'Connecting to your device...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
              
              if (_isConnected) ...[
                ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary 
            ? AppTheme.primaryAccent.withOpacity(0.1)
            : (isDarkMode ? Colors.grey[900] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary 
              ? AppTheme.primaryAccent.withOpacity(0.3)
              : (isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isPrimary 
                  ? AppTheme.primaryAccent.withOpacity(0.2)
                  : (isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isPrimary 
                  ? AppTheme.primaryAccent
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}