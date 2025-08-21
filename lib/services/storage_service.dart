import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _authKey = 'isAuthenticated';
  static const String _onboardingKey = 'hasCompletedOnboarding';
  static const String _userProfileKey = 'userProfile';
  static const String _nutritionPrefix = 'nutrition_';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Authentication
  Future<bool> isAuthenticated() async {
    return _prefs.getBool(_authKey) ?? false;
  }

  Future<void> setAuthenticated(bool value) async {
    await _prefs.setBool(_authKey, value);
  }

  // Onboarding
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  // User Profile
  Future<UserProfile?> getUserProfile() async {
    final String? profileJson = _prefs.getString(_userProfileKey);
    if (profileJson == null) return null;
    
    try {
      final Map<String, dynamic> profileMap = json.decode(profileJson);
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final String profileJson = json.encode(profile.toJson());
    await _prefs.setString(_userProfileKey, profileJson);
  }

  // Nutrition Data
  Future<DayNutritionData?> getNutritionData(String date) async {
    final String key = '$_nutritionPrefix$date';
    final String? nutritionJson = _prefs.getString(key);
    if (nutritionJson == null) return null;
    
    try {
      final Map<String, dynamic> nutritionMap = json.decode(nutritionJson);
      return DayNutritionData.fromJson(nutritionMap);
    } catch (e) {
      print('Error loading nutrition data for $date: $e');
      return null;
    }
  }

  Future<void> saveNutritionData(DayNutritionData data) async {
    final String key = '$_nutritionPrefix${data.date}';
    final String nutritionJson = json.encode(data.toJson());
    await _prefs.setString(key, nutritionJson);
  }

  // Streak calculation
  Future<int> calculateCurrentStreak() async {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final date = currentDate.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final nutritionData = await getNutritionData(dateStr);
      
      if (nutritionData != null && nutritionData.consumed.calories > 0) {
        streak++;
      } else if (i > 0) {
        // Break streak only if it's not today
        break;
      }
    }
    
    return streak;
  }

  Future<int> calculateLongestStreak() async {
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final date = currentDate.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final nutritionData = await getNutritionData(dateStr);
      
      if (nutritionData != null && nutritionData.consumed.calories > 0) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Clear old nutrition data (keep last 30 days)
  Future<void> cleanupOldData() async {
    final DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final Set<String> keys = _prefs.getKeys();
    
    for (String key in keys) {
      if (key.startsWith(_nutritionPrefix)) {
        final String dateStr = key.substring(_nutritionPrefix.length);
        try {
          final DateTime date = DateTime.parse(dateStr);
          if (date.isBefore(cutoffDate)) {
            await _prefs.remove(key);
          }
        } catch (e) {
          // Invalid date format, skip
        }
      }
    }
  }
}