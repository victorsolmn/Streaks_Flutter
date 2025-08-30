import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/nutrition_model.dart';
import 'dart:convert';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  SupabaseClient get client => _supabase;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    _supabase = Supabase.instance.client;
    _isInitialized = true;
  }

  // Authentication Methods
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

      if (response.user != null) {
        // Create initial profile
        await createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
        );
      }

      return response;
    } catch (e) {
      throw Exception('Sign up failed: $e');
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
      return response;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // User Profile Methods
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'name': name,
      });
    } catch (e) {
      print('Error creating profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Nutrition Methods
  Future<void> saveNutritionEntry({
    required String userId,
    required String date,
    required Map<String, dynamic> nutritionData,
  }) async {
    try {
      await _supabase.from('nutrition_entries').upsert({
        'user_id': userId,
        'date': date,
        'calories': nutritionData['calories'] ?? 0,
        'protein': nutritionData['protein'] ?? 0,
        'carbs': nutritionData['carbs'] ?? 0,
        'fat': nutritionData['fat'] ?? 0,
        'fiber': nutritionData['fiber'] ?? 0,
        'water': nutritionData['water'] ?? 0,
        'food_items': nutritionData['food_items'] ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
    } catch (e) {
      throw Exception('Failed to save nutrition data: $e');
    }
  }

  Future<Map<String, dynamic>?> getNutritionEntry({
    required String userId,
    required String date,
  }) async {
    try {
      final response = await _supabase
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching nutrition: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionHistory({
    required String userId,
    required int days,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('nutrition_entries')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching nutrition history: $e');
      return [];
    }
  }

  // Health Metrics Methods
  Future<void> saveHealthMetrics({
    required String userId,
    required String date,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      await _supabase.from('health_metrics').upsert({
        'user_id': userId,
        'date': date,
        'steps': metrics['steps'] ?? 0,
        'heart_rate': metrics['heart_rate'],
        'sleep_hours': metrics['sleep_hours'],
        'calories_burned': metrics['calories_burned'],
      }, onConflict: 'user_id,date');
    } catch (e) {
      throw Exception('Failed to save health metrics: $e');
    }
  }

  Future<Map<String, dynamic>?> getHealthMetrics({
    required String userId,
    required String date,
  }) async {
    try {
      final response = await _supabase
          .from('health_metrics')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching health metrics: $e');
      return null;
    }
  }

  // Streak Methods
  Future<void> updateStreak({
    required String userId,
    required int currentStreak,
    int? longestStreak,
  }) async {
    try {
      final updates = {
        'current_streak': currentStreak,
        'last_activity_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (longestStreak != null) {
        updates['longest_streak'] = longestStreak;
      }

      await _supabase
          .from('streaks')
          .upsert({
            'user_id': userId,
            ...updates,
          }, onConflict: 'user_id');
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  Future<Map<String, dynamic>?> getStreak(String userId) async {
    try {
      final response = await _supabase
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching streak: $e');
      return null;
    }
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> subscribeToNutrition(String userId) {
    return _supabase
        .from('nutrition_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> subscribeToHealthMetrics(String userId) {
    return _supabase
        .from('health_metrics')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false);
  }

  // Batch operations
  Future<void> syncOfflineData({
    required String userId,
    required List<Map<String, dynamic>> nutritionEntries,
    required List<Map<String, dynamic>> healthMetrics,
  }) async {
    try {
      // Batch insert nutrition entries
      if (nutritionEntries.isNotEmpty) {
        await _supabase.from('nutrition_entries').upsert(
          nutritionEntries.map((entry) => {
            'user_id': userId,
            ...entry,
          }).toList(),
          onConflict: 'user_id,date',
        );
      }

      // Batch insert health metrics
      if (healthMetrics.isNotEmpty) {
        await _supabase.from('health_metrics').upsert(
          healthMetrics.map((metric) => {
            'user_id': userId,
            ...metric,
          }).toList(),
          onConflict: 'user_id,date',
        );
      }
    } catch (e) {
      throw Exception('Failed to sync offline data: $e');
    }
  }

  // Helper method to check connection
  Future<bool> isConnected() async {
    try {
      await _supabase.from('profiles').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}