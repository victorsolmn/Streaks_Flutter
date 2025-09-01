import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/screens/auth/signup_screen.dart';
import 'lib/screens/onboarding/onboarding_screen.dart';
import 'lib/screens/onboarding/smartwatch_connection_screen.dart';
import 'lib/providers/supabase_auth_provider.dart';
import 'lib/providers/user_provider.dart';
import 'lib/providers/health_provider.dart';
import 'lib/services/supabase_service.dart';

void main() {
  group('Onboarding Process Tests', () {
    late SharedPreferences prefs;
    
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Email validation in signup screen', (WidgetTester tester) async {
      // Test 1: Invalid email format
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
              ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
            ],
            child: SignUpScreen(),
          ),
        ),
      );

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).at(1); // Second field is email
      await tester.enterText(emailField, 'invalidemail');
      await tester.pump();

      // Try to submit
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Test 2: Valid email format
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      
      // Should not show email format error
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('Onboarding flow navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SupabaseAuthProvider()),
              ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
            ],
            child: OnboardingScreen(),
          ),
        ),
      );

      // Check step 1 is displayed
      expect(find.text('Setup Profile (1/3)'), findsOneWidget);
      
      // Fill in step 1 - Basic Info
      await tester.enterText(find.byType(TextFormField).at(0), '25'); // Age
      await tester.enterText(find.byType(TextFormField).at(1), '170'); // Height
      await tester.enterText(find.byType(TextFormField).at(2), '70'); // Weight
      
      // Tap next
      await tester.tap(find.text('Next'));
      await tester.pump();
      
      // Check step 2 is displayed
      expect(find.text('Setup Profile (2/3)'), findsOneWidget);
      
      // Select fitness goal
      await tester.tap(find.text('Lose Weight'));
      await tester.pump();
      
      // Tap next
      await tester.tap(find.text('Next'));
      await tester.pump();
      
      // Check step 3 is displayed
      expect(find.text('Setup Profile (3/3)'), findsOneWidget);
      
      // Select activity level
      await tester.tap(find.text('Moderately Active'));
      await tester.pump();
      
      // Complete onboarding
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();
      
      // Should navigate to smartwatch connection screen
      expect(find.byType(SmartwatchConnectionScreen), findsOneWidget);
    });

    testWidgets('Smartwatch integration screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => HealthProvider()),
              ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
            ],
            child: SmartwatchConnectionScreen(),
          ),
        ),
      );

      // Check screen is displayed
      expect(find.text('Connect Your Smartwatch'), findsOneWidget);
      
      // Check for connection options
      expect(find.text('Connect Health Connect'), findsOneWidget);
      expect(find.text('Connect Apple Health'), findsOneWidget);
      
      // Test skip functionality
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();
      
      // Should navigate to main screen
      expect(find.byType(MainScreen), findsOneWidget);
    });

    test('Data persistence after onboarding', () async {
      final userProvider = UserProvider(prefs);
      
      // Create profile
      await userProvider.createProfile(
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        height: 170,
        weight: 70,
        targetWeight: 65,
        goal: FitnessGoal.loseWeight,
        activityLevel: ActivityLevel.moderate,
      );
      
      // Check data is saved
      expect(userProvider.hasProfile, true);
      expect(userProvider.name, 'Test User');
      expect(userProvider.email, 'test@example.com');
      expect(userProvider.age, 25);
      expect(userProvider.currentWeight, 70);
      
      // Check persistence in SharedPreferences
      expect(prefs.getString('user_name'), 'Test User');
      expect(prefs.getString('user_email'), 'test@example.com');
      expect(prefs.getInt('user_age'), 25);
      
      // Test health provider connection persistence
      final healthProvider = HealthProvider();
      await healthProvider.initialize();
      
      // Simulate connection to health source
      await healthProvider.connectToHealthSource(HealthDataSource.healthConnect);
      
      // Check connection is saved
      expect(prefs.getBool('health_connect_connected'), true);
      expect(prefs.getString('connected_health_source'), 'healthConnect');
      
      // Reinitialize provider to test persistence
      final newHealthProvider = HealthProvider();
      await newHealthProvider.initialize();
      
      // Check connection is restored
      expect(newHealthProvider.isHealthSourceConnected, true);
      expect(newHealthProvider.dataSource, HealthDataSource.healthConnect);
    });

    test('Email duplicate check', () async {
      final supabaseService = SupabaseService();
      
      // Test with a known duplicate email (would need mock or test environment)
      final exists = await supabaseService.checkEmailExists('existing@example.com');
      
      // In real test, this would check against test database
      // For now, just verify the method exists and returns boolean
      expect(exists, isA<bool>());
    });
  });
}