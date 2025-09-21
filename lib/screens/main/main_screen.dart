import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../services/toast_service.dart';
import '../../services/popup_service.dart';
import '../../widgets/sync_status_indicator.dart';
import 'home_screen_clean.dart';
import 'progress_screen_new.dart';
import 'nutrition_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isDataLoaded = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  GlobalKey? _profileKey;

  @override
  void initState() {
    super.initState();
    // Set initial index from widget parameter
    _currentIndex = widget.initialIndex;
    _profileKey = GlobalKey();
    // Add observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Initialize toast service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ToastService().initialize(context);
      }
    });
    // Load data and sync health on startup
    _loadUserDataAndSyncHealth();
    
    // If navigating to profile page, show smartwatch integration after delay
    if (widget.initialIndex == 4) {
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted && _profileKey?.currentState != null) {
          // Trigger smartwatch integration dialog in profile screen
          // Try to call the method if the state exists
          try {
            final profileState = _profileKey?.currentState as dynamic;
            profileState?.showSmartwatchIntegrationDialog();
          } catch (e) {
            debugPrint('Could not trigger smartwatch dialog: $e');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App has come to foreground - only sync if needed (with throttling)
      _syncHealthDataIfNeeded();
      // Note: _syncHealthDataIfNeeded already handles loading data if needed
    } else if (state == AppLifecycleState.paused) {
      // App is going to background - sync data to Supabase
      healthProvider.syncOnPause();
      nutritionProvider.syncOnPause();
    }
  }

  Future<void> _loadUserDataAndSyncHealth() async {
    if (_isDataLoaded) return;

    // Early return if widget is not mounted
    if (!mounted) return;

    // Show sync indicator
    setState(() {
      _isSyncing = true;
    });

    try {
      // Check mounted before accessing context
      if (!mounted) return;

      // Load nutrition data from Supabase
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.loadDataFromSupabase();

      // Check mounted after async operation
      if (!mounted) return;

      // Load and sync health data
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);

      // FIRST: Load existing data from Supabase (before any initialization)
      debugPrint('MainScreen: Loading existing data from Supabase...');
      await healthProvider.loadHealthDataFromSupabase();

      // Check mounted after async operation
      if (!mounted) return;

      // Initialize health provider if not already done
      if (!healthProvider.isInitialized) {
        await healthProvider.initialize();
      }

      // Check mounted after async operation
      if (!mounted) return;

      // Smart permission check: Auto-connect if permissions already exist
      debugPrint('MainScreen: Performing smart permission check...');
      final autoConnected = await healthProvider.healthService.checkAndAutoConnect();
      if (autoConnected) {
        debugPrint('MainScreen: ✅ Auto-connected to health source!');

        // IMPORTANT: Immediately sync health data after successful connection
        debugPrint('MainScreen: Fetching health data after auto-connect...');
        await healthProvider.syncWithHealth();

        // Save the fetched data to Supabase
        await healthProvider.saveHealthDataToSupabase();
      } else {
        debugPrint('MainScreen: No existing permissions found, manual connection required');
      }

      // Check mounted after async operation
      if (!mounted) return;

      // Check if we need to sync (in case auto-connect didn't work)
      if (!autoConnected && healthProvider.isHealthSourceConnected) {
        debugPrint('MainScreen: Auto-syncing health data on app startup...');
        await healthProvider.syncWithHealth();

        // Check mounted after async operation
        if (!mounted) return;

        _lastSyncTime = DateTime.now();

        // Show success message
        if (mounted && context.mounted) {
          ToastService().showSuccess('Health data synced successfully! 📊');
        }
      } else {
        debugPrint('MainScreen: Health source not connected, skipping auto-sync');
      }
      
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
          _isSyncing = false;
        });
      }
    } catch (e) {
      debugPrint('MainScreen: Error during initial data load: $e');
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        // Only show popup if still mounted and context is valid
        if (mounted && context.mounted) {
          // Show network error popup with retry option
          PopupService.showNetworkError(
            context,
            onRetry: () => _loadUserDataAndSyncHealth(),
            customMessage: 'Failed to load health data. Please check your connection and try again.',
          );
        }
      }
    }
  }
  
  Future<void> _syncHealthDataIfNeeded() async {
    // Prevent multiple simultaneous syncs
    if (_isSyncing) {
      debugPrint('MainScreen: Sync already in progress, skipping');
      return;
    }

    // Check if we should sync (throttle to prevent excessive syncing)
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      // Only sync if it's been more than 60 seconds since last sync (increased from 30)
      if (timeSinceLastSync.inSeconds < 60) {
        debugPrint('MainScreen: Skipping sync, last sync was ${timeSinceLastSync.inSeconds} seconds ago');
        return;
      }
    }

    final healthProvider = Provider.of<HealthProvider>(context, listen: false);

    // Smart permission check on app resume
    debugPrint('MainScreen: Checking for existing permissions on app resume...');
    final autoConnected = await healthProvider.healthService.checkAndAutoConnect();
    if (autoConnected) {
      debugPrint('MainScreen: ✅ Auto-connected on resume!');
    }

    // Only sync if health source is connected
    if (!healthProvider.isHealthSourceConnected) {
      debugPrint('MainScreen: Health source not connected, skipping auto-sync');
      return;
    }
    
    if (mounted) {
      setState(() {
        _isSyncing = true;
      });
    }
    
    try {
      debugPrint('MainScreen: Auto-syncing health data on app resume...');
      await healthProvider.syncWithHealth();
      _lastSyncTime = DateTime.now();
      
      // Show subtle sync indicator
      if (mounted && context.mounted) {
        ToastService().showInfo('Health data updated! 🔄');
      }
    } catch (e) {
      debugPrint('MainScreen: Error syncing health data: $e');
      // Only show popup if still mounted and context is valid
      if (mounted && context.mounted) {
        // Show network error popup with retry option
        PopupService.showNetworkError(
          context,
          onRetry: () => _syncHealthDataIfNeeded(),
          customMessage: 'Failed to sync health data. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  List<Widget> get _screens => [
    const HomeScreenClean(),
    const ProgressScreenNew(),
    const NutritionScreen(),
    const ChatScreen(),
    ProfileScreen(key: _profileKey),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/images/streaker_logo.svg',
          colorFilter: ColorFilter.mode(
            AppTheme.textSecondary,
            BlendMode.srcIn,
          ),
        ),
      ),
      activeIcon: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/images/streaker_logo.svg',
          colorFilter: ColorFilter.mode(
            AppTheme.primaryAccent,
            BlendMode.srcIn,
          ),
        ),
      ),
      label: 'Streaks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.restaurant_outlined),
      activeIcon: Icon(Icons.restaurant_rounded),
      label: 'Nutrition',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center_outlined),
      activeIcon: Icon(Icons.fitness_center_rounded),
      label: 'Workouts',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Sync status indicator - only show on home screen
          if (_currentIndex == 0) // Only show on home screen
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: const SyncStatusIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: _bottomNavItems,
        ),
      ),
    );
  }
}