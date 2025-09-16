import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Temporarily disabled
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'services/enhanced_supabase_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/bluetooth_smartwatch_service.dart';
import 'services/realtime_sync_service.dart';
import 'services/daily_reset_service.dart';
// Using Supabase providers for cloud storage
import 'providers/supabase_auth_provider.dart';
import 'providers/supabase_nutrition_provider.dart';
import 'providers/supabase_user_provider.dart';
// Also include local providers for compatibility
import 'providers/auth_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/user_provider.dart';
import 'providers/health_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/streak_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main/main_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase services
  await SupabaseService().initialize();
  await EnhancedSupabaseService().initialize();
  
  // Initialize Bluetooth Smartwatch Service
  await BluetoothSmartwatchService().initialize();
  
  // Initialize Real-time Sync Service
  await RealtimeSyncService().initialize();
  
  // Initialize Daily Reset Service
  await DailyResetService().initialize();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase services
    FirebaseAnalyticsService().initialize();
    
    // Set up Crashlytics (only for non-web platforms)
    // Temporarily disabled due to iOS build issue
    // if (!kIsWeb) {
    //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    //   PlatformDispatcher.instance.onError = (error, stack) {
    //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    //     return true;
    //   };
    // }
    
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // App can still run with Supabase only
  }
  
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Using Supabase providers for cloud storage
        ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseUserProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseNutritionProvider()),
        // Local providers for compatibility
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
        ChangeNotifierProvider(create: (_) => NutritionProvider(prefs)),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
      ],
      child: Consumer3<SupabaseAuthProvider, SupabaseUserProvider, ThemeProvider>(
        builder: (context, auth, userProvider, themeProvider, _) {
          print('Auth state: authenticated=${auth.isAuthenticated}, loading=${auth.isLoading}');
          print('User profile: hasProfile=${userProvider.hasProfile}, onboarding=${userProvider.hasCompletedOnboarding}');
          
          // Load user profile when authenticated and profile is not loaded (only once)
          if (auth.isAuthenticated && !userProvider.hasProfile && !userProvider.isLoading && !userProvider.hasTriedLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              userProvider.loadUserProfile();
            });
          }
          
          Widget home;
          
          // Show loading if auth is in loading state or user profile is loading
          if (auth.isLoading || (auth.isAuthenticated && userProvider.isLoading)) {
            home = const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (auth.isAuthenticated) {
            // Check if user has completed onboarding and has a profile
            if (userProvider.hasProfile && userProvider.hasCompletedOnboarding) {
              home = const MainScreen();
            } else {
              // Authenticated but no profile - need onboarding
              home = const OnboardingScreen();
            }
          } else {
            // Not authenticated
            home = const WelcomeScreen();
          }
          
          return MaterialApp(
            title: 'Streaker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: home,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}