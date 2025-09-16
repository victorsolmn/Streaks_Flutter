import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:math';

class EnhancedSupabaseService {
  static final EnhancedSupabaseService _instance = EnhancedSupabaseService._internal();
  factory EnhancedSupabaseService() => _instance;
  EnhancedSupabaseService._internal();

  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  SupabaseClient get client => _supabase;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Use existing Supabase instance (initialized in SupabaseService)
    _supabase = Supabase.instance.client;
    _isInitialized = true;
    debugPrint('✅ Enhanced Supabase Service initialized');
  }

  // ========================================
  // AUTHENTICATION METHODS
  // ========================================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      debugPrint('✅ User signed up: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ User signed in: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // ========================================
  // PROFILE METHODS
  // ========================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('✅ Profile fetched for user: $userId');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? fitnessGoal,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (activityLevel != null) updates['activity_level'] = activityLevel;
      if (fitnessGoal != null) updates['fitness_goal'] = fitnessGoal;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      debugPrint('✅ Profile updated for user: $userId');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // ========================================
  // NUTRITION METHODS
  // ========================================

  Future<void> addNutritionEntry({
    required String userId,
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0.0,
    int quantityGrams = 100,
    String mealType = 'snack',
    String? foodSource,
    DateTime? date,
  }) async {
    try {
      await _supabase.from('nutrition_entries').insert({
        'user_id': userId,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'quantity_grams': quantityGrams,
        'meal_type': mealType,
        'food_source': foodSource,
        'date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      debugPrint('✅ Nutrition entry added: $foodName');
    } catch (e) {
      debugPrint('❌ Error adding nutrition entry: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionEntries({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      // For simplicity, we'll filter in memory for now
      // In production, you'd want to use proper date filtering

      final response = await query;
      debugPrint('✅ Fetched ${response.length} nutrition entries');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching nutrition entries: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDailyNutritionSummary({
    required String userId,
    DateTime? date,
  }) async {
    try {
      final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_nutrition_summary')
          .select()
          .eq('user_id', userId)
          .eq('date', targetDate)
          .maybeSingle();

      return response ?? {
        'total_calories': 0,
        'total_protein': 0.0,
        'total_carbs': 0.0,
        'total_fat': 0.0,
        'total_fiber': 0.0,
        'entries_count': 0,
      };
    } catch (e) {
      debugPrint('❌ Error fetching daily nutrition summary: $e');
      return {
        'total_calories': 0,
        'total_protein': 0.0,
        'total_carbs': 0.0,
        'total_fat': 0.0,
        'total_fiber': 0.0,
        'entries_count': 0,
      };
    }
  }

  // ========================================
  // HEALTH METRICS METHODS
  // ========================================

  Future<void> saveHealthMetrics({
    required String userId,
    DateTime? date,
    int? steps,
    int? heartRate,
    double? sleepHours,
    int? caloriesBurned,
    double? distance,
    int? activeMinutes,
    int? waterIntake,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      };

      if (steps != null) data['steps'] = steps;
      if (heartRate != null) data['heart_rate'] = heartRate;
      if (sleepHours != null) data['sleep_hours'] = sleepHours;
      if (caloriesBurned != null) data['calories_burned'] = caloriesBurned;
      if (distance != null) data['distance'] = distance;
      if (activeMinutes != null) data['active_minutes'] = activeMinutes;
      if (waterIntake != null) data['water_intake'] = waterIntake;

      await _supabase.from('health_metrics').upsert(data);
      debugPrint('✅ Health metrics saved for ${data['date']}');
    } catch (e) {
      debugPrint('❌ Error saving health metrics: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getHealthMetrics({
    required String userId,
    DateTime? date,
  }) async {
    try {
      final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];

      final response = await _supabase
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .eq('date', targetDate)
          .maybeSingle();

      debugPrint('✅ Health metrics fetched for $targetDate');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching health metrics: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHealthMetricsHistory({
    required String userId,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(days + 10); // Get a bit more to account for filtering

      debugPrint('✅ Fetched ${response.length} health metrics records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching health metrics history: $e');
      return [];
    }
  }

  // ========================================
  // STREAKS METHODS
  // ========================================

  Future<void> updateStreak({
    required String userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    String streakType = 'daily',
    bool? targetAchieved,
  }) async {
    try {
      final data = <String, dynamic>{
        'user_id': userId,
        'streak_type': streakType,
      };

      if (currentStreak != null) data['current_streak'] = currentStreak;
      if (longestStreak != null) data['longest_streak'] = longestStreak;
      if (lastActivityDate != null) data['last_activity_date'] = lastActivityDate.toIso8601String().split('T')[0];
      if (targetAchieved != null) data['target_achieved'] = targetAchieved;

      await _supabase.from('streaks').upsert(data);
      debugPrint('✅ Streak updated: $streakType');
    } catch (e) {
      debugPrint('❌ Error updating streak: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getStreak({
    required String userId,
    String streakType = 'daily',
  }) async {
    try {
      final response = await _supabase
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .eq('streak_type', streakType)
          .maybeSingle();

      debugPrint('✅ Streak fetched: $streakType');
      return response;
    } catch (e) {
      debugPrint('❌ Error fetching streak: $e');
      return null;
    }
  }

  // ========================================
  // USER GOALS METHODS
  // ========================================

  Future<void> setUserGoal({
    required String userId,
    required String goalType,
    required double targetValue,
    required String unit,
    bool isActive = true,
  }) async {
    try {
      await _supabase.from('user_goals').upsert({
        'user_id': userId,
        'goal_type': goalType,
        'target_value': targetValue,
        'unit': unit,
        'is_active': isActive,
      });

      debugPrint('✅ Goal set: $goalType = $targetValue $unit');
    } catch (e) {
      debugPrint('❌ Error setting goal: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserGoals({
    required String userId,
    bool activeOnly = true,
  }) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Filter in memory for now
      List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response);
      if (activeOnly) {
        results = results.where((goal) => goal['is_active'] == true).toList();
      }

      debugPrint('✅ Fetched ${results.length} user goals');
      return results;
    } catch (e) {
      debugPrint('❌ Error fetching user goals: $e');
      return [];
    }
  }

  Future<void> updateGoalProgress({
    required String userId,
    required String goalType,
    required double currentValue,
  }) async {
    try {
      await _supabase
          .from('user_goals')
          .update({'current_value': currentValue})
          .eq('user_id', userId)
          .eq('goal_type', goalType);

      debugPrint('✅ Goal progress updated: $goalType = $currentValue');
    } catch (e) {
      debugPrint('❌ Error updating goal progress: $e');
      rethrow;
    }
  }

  // ========================================
  // DASHBOARD & ANALYTICS METHODS
  // ========================================

  Future<Map<String, dynamic>> getUserDashboard(String userId) async {
    try {
      final response = await _supabase
          .from('user_dashboard')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('✅ Dashboard data fetched for user: $userId');
      return response ?? {};
    } catch (e) {
      debugPrint('❌ Error fetching dashboard: $e');
      return {};
    }
  }

  // ========================================
  // TEST DATA GENERATION METHODS
  // ========================================

  Future<void> generateTestData() async {
    try {
      debugPrint('🚀 Starting test data generation...');

      final testUsers = [
        {'email': 'john.doe@test.com', 'name': 'John Doe', 'password': 'testpass123'},
        {'email': 'jane.smith@test.com', 'name': 'Jane Smith', 'password': 'testpass123'},
        {'email': 'mike.wilson@test.com', 'name': 'Mike Wilson', 'password': 'testpass123'},
        {'email': 'sarah.jones@test.com', 'name': 'Sarah Jones', 'password': 'testpass123'},
        {'email': 'alex.brown@test.com', 'name': 'Alex Brown', 'password': 'testpass123'},
        {'email': 'lisa.davis@test.com', 'name': 'Lisa Davis', 'password': 'testpass123'},
        {'email': 'david.miller@test.com', 'name': 'David Miller', 'password': 'testpass123'},
        {'email': 'emma.taylor@test.com', 'name': 'Emma Taylor', 'password': 'testpass123'},
        {'email': 'chris.lee@test.com', 'name': 'Chris Lee', 'password': 'testpass123'},
        {'email': 'anna.white@test.com', 'name': 'Anna White', 'password': 'testpass123'},
      ];

      final random = Random();
      final foods = ['Chicken Breast', 'Rice', 'Broccoli', 'Salmon', 'Apple', 'Banana', 'Oats', 'Yogurt', 'Spinach', 'Almonds'];
      final activityLevels = ['sedentary', 'lightly_active', 'moderately_active', 'very_active'];
      final fitnessGoals = ['lose_weight', 'maintain_weight', 'gain_weight', 'build_muscle', 'improve_fitness'];
      final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

      for (int i = 0; i < testUsers.length; i++) {
        final user = testUsers[i];
        debugPrint('📝 Creating test user ${i + 1}: ${user['name']}');

        // Sign up user
        try {
          await signUp(
            email: user['email']!,
            password: user['password']!,
            name: user['name']!,
          );

          // Wait for user creation
          await Future.delayed(Duration(seconds: 2));

          // Sign in to get user ID
          final authResponse = await signIn(
            email: user['email']!,
            password: user['password']!,
          );

          if (authResponse.user == null) {
            debugPrint('❌ Failed to create user: ${user['name']}');
            continue;
          }

          final userId = authResponse.user!.id;
          debugPrint('✅ User created with ID: $userId');

          // Update profile with random data
          await updateUserProfile(
            userId: userId,
            age: 20 + random.nextInt(40),
            height: 150.0 + random.nextDouble() * 50,
            weight: 50.0 + random.nextDouble() * 50,
            activityLevel: activityLevels[random.nextInt(activityLevels.length)],
            fitnessGoal: fitnessGoals[random.nextInt(fitnessGoals.length)],
          );

          // Add nutrition entries for the last 7 days
          for (int day = 0; day < 7; day++) {
            final date = DateTime.now().subtract(Duration(days: day));

            // Add 3-5 food entries per day
            final entriesCount = 3 + random.nextInt(3);
            for (int entry = 0; entry < entriesCount; entry++) {
              await addNutritionEntry(
                userId: userId,
                foodName: foods[random.nextInt(foods.length)],
                calories: 100 + random.nextInt(400),
                protein: 5.0 + random.nextDouble() * 25,
                carbs: 10.0 + random.nextDouble() * 40,
                fat: 2.0 + random.nextDouble() * 15,
                fiber: random.nextDouble() * 10,
                mealType: mealTypes[random.nextInt(mealTypes.length)],
                foodSource: 'test_data',
                date: date,
              );
            }
          }

          // Add health metrics for the last 30 days
          for (int day = 0; day < 30; day++) {
            final date = DateTime.now().subtract(Duration(days: day));

            await saveHealthMetrics(
              userId: userId,
              date: date,
              steps: 3000 + random.nextInt(12000),
              heartRate: 60 + random.nextInt(40),
              sleepHours: 6.0 + random.nextDouble() * 4,
              caloriesBurned: 1500 + random.nextInt(1000),
              distance: 2.0 + random.nextDouble() * 10,
              activeMinutes: 30 + random.nextInt(120),
              waterIntake: 1500 + random.nextInt(1500),
            );
          }

          // Update streaks
          await updateStreak(
            userId: userId,
            currentStreak: random.nextInt(30),
            longestStreak: 30 + random.nextInt(70),
            lastActivityDate: DateTime.now(),
            targetAchieved: random.nextBool(),
          );

          // Set custom goals
          await setUserGoal(
            userId: userId,
            goalType: 'daily_calories',
            targetValue: 2000 + random.nextInt(500).toDouble(),
            unit: 'kcal',
          );

          await setUserGoal(
            userId: userId,
            goalType: 'daily_steps',
            targetValue: 8000 + random.nextInt(4000).toDouble(),
            unit: 'steps',
          );

          await setUserGoal(
            userId: userId,
            goalType: 'daily_water',
            targetValue: 2000 + random.nextInt(1000).toDouble(),
            unit: 'ml',
          );

          debugPrint('✅ Test data generated for user: ${user['name']}');

          // Sign out
          await signOut();
          await Future.delayed(Duration(seconds: 1));

        } catch (e) {
          debugPrint('❌ Error creating test user ${user['name']}: $e');
          continue;
        }
      }

      debugPrint('🎉 Test data generation completed!');
    } catch (e) {
      debugPrint('❌ Error generating test data: $e');
      rethrow;
    }
  }

  // Helper method to check connection
  Future<bool> isConnected() async {
    try {
      await _supabase.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ Connection check failed: $e');
      return false;
    }
  }
}