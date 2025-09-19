import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/achievement_model.dart';
import '../services/supabase_service.dart';

class AchievementProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  SharedPreferences? _prefs;

  List<Achievement> _achievements = [];
  List<UserAchievement> _userAchievements = [];
  List<AchievementProgress> _achievementProgress = [];
  List<Achievement> _recentUnlocks = [];

  bool _isLoading = false;
  String? _error;

  RealtimeChannel? _achievementChannel;

  // Getters
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements => _achievements.where((a) => !a.isUnlocked).toList();
  List<Achievement> get recentUnlocks => _recentUnlocks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get overallProgress {
    if (_achievements.isEmpty) return 0.0;
    return unlockedAchievements.length / _achievements.length;
  }

  int get totalAchievements => _achievements.length;
  int get totalUnlocked => unlockedAchievements.length;

  AchievementProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadAchievements();
    _setupRealtimeSubscription();
  }

  Future<void> loadAchievements() async {
    try {
      _setLoading(true);
      _error = null;

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _setError('User not authenticated');
        return;
      }

      // Load all achievements from master table
      final achievementsResponse = await _supabaseService.client
          .from('achievements')
          .select()
          .order('sort_order');

      // Load user's unlocked achievements
      final userAchievementsResponse = await _supabaseService.client
          .from('user_achievements')
          .select()
          .eq('user_id', userId);

      // Load achievement progress
      final progressResponse = await _supabaseService.client
          .from('achievement_progress')
          .select()
          .eq('user_id', userId);

      // Parse responses
      _userAchievements = (userAchievementsResponse as List)
          .map((json) => UserAchievement.fromJson(json))
          .toList();

      _achievementProgress = (progressResponse as List)
          .map((json) => AchievementProgress.fromJson(json))
          .toList();

      // Combine data to create complete Achievement objects
      _achievements = (achievementsResponse as List).map((achievementJson) {
        // Check if user has unlocked this achievement
        final userAchievement = _userAchievements.firstWhere(
          (ua) => ua.achievementId == achievementJson['id'],
          orElse: () => UserAchievement(
            id: '',
            userId: userId,
            achievementId: achievementJson['id'],
            unlockedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Get progress for this achievement
        final progress = _achievementProgress.firstWhere(
          (ap) => ap.achievementId == achievementJson['id'],
          orElse: () => AchievementProgress(
            id: '',
            userId: userId,
            achievementId: achievementJson['id'],
            currentValue: 0,
            targetValue: achievementJson['requirement_value'] ?? 0,
            lastUpdated: DateTime.now(),
          ),
        );

        return Achievement.fromJson(
          achievementJson,
          isUnlocked: userAchievement.id.isNotEmpty,
          unlockedAt: userAchievement.id.isNotEmpty ? userAchievement.unlockedAt : null,
          currentProgress: progress.currentValue,
          notified: userAchievement.notified,
        );
      }).toList();

      // Sort achievements by sort_order
      _achievements.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Get recent unlocks (last 3)
      _recentUnlocks = unlockedAchievements
          .where((a) => a.unlockedAt != null)
          .toList()
        ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!))
        ..take(3).toList();

      // Cache achievements locally
      await _saveToLocal();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      _setError('Failed to load achievements');
      // Try to load from local cache
      await _loadFromLocal();
      _setLoading(false);
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // Check if already unlocked
      final achievement = getAchievementById(achievementId);
      if (achievement == null || achievement.isUnlocked) return;

      // Insert into user_achievements
      await _supabaseService.client
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievementId,
            'unlocked_at': DateTime.now().toIso8601String(),
            'notified': false,
          });

      // Update local state
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _achievements[index] = _achievements[index].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        notifyListeners();
      }

      // Save to local cache
      await _saveToLocal();
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  Future<void> updateProgress(String achievementId, int currentValue) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      final achievement = getAchievementById(achievementId);
      if (achievement == null || achievement.isUnlocked) return;

      // Update progress in database
      await _supabaseService.client
          .from('achievement_progress')
          .upsert({
            'user_id': userId,
            'achievement_id': achievementId,
            'current_value': currentValue,
            'target_value': achievement.requirementValue,
            'last_updated': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,achievement_id');

      // Update local state
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _achievements[index] = _achievements[index].copyWith(
          currentProgress: currentValue,
        );
        notifyListeners();
      }

      // Check if achievement should be unlocked
      if (currentValue >= achievement.requirementValue) {
        await unlockAchievement(achievementId);
      }
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }

  Achievement? getAchievementById(String id) {
    try {
      return _achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  void _setupRealtimeSubscription() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // Subscribe to user achievement updates
    _achievementChannel = _supabaseService.client
        .channel('user_achievements_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_achievements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('New achievement unlocked: ${payload.newRecord}');
            // Reload achievements to get the latest state
            loadAchievements();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'achievement_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Achievement progress updated: ${payload.newRecord}');
            // Update progress locally
            final progressData = payload.newRecord as Map<String, dynamic>;
            final achievementId = progressData['achievement_id'];
            final currentValue = progressData['current_value'];

            final index = _achievements.indexWhere((a) => a.id == achievementId);
            if (index != -1) {
              _achievements[index] = _achievements[index].copyWith(
                currentProgress: currentValue,
              );
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> _saveToLocal() async {
    if (_prefs == null) return;

    try {
      final achievementsJson = _achievements.map((a) => a.toJson()).toList();
      await _prefs!.setString('cached_achievements', jsonEncode(achievementsJson));
    } catch (e) {
      debugPrint('Error saving achievements to local storage: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    if (_prefs == null) return;

    try {
      final cachedData = _prefs!.getString('cached_achievements');
      if (cachedData != null) {
        final List<dynamic> achievementsJson = jsonDecode(cachedData);
        _achievements = achievementsJson.map((json) => Achievement.fromJson(
          json,
          isUnlocked: json['is_unlocked'] ?? false,
          unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
          currentProgress: json['current_progress'] ?? 0,
          notified: json['notified'] ?? false,
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading achievements from local storage: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _achievementChannel?.unsubscribe();
    super.dispose();
  }
}