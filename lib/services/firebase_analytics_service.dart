import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver observer;

  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // User Properties
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  Future<void> setUserProperties({
    String? fitnessGoal,
    String? activityLevel,
    int? age,
    String? bmiCategory,
  }) async {
    try {
      if (fitnessGoal != null) {
        await _analytics.setUserProperty(name: 'fitness_goal', value: fitnessGoal);
      }
      if (activityLevel != null) {
        await _analytics.setUserProperty(name: 'activity_level', value: activityLevel);
      }
      if (age != null) {
        await _analytics.setUserProperty(name: 'age_group', value: _getAgeGroup(age));
      }
      if (bmiCategory != null) {
        await _analytics.setUserProperty(name: 'bmi_category', value: bmiCategory);
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  String _getAgeGroup(int age) {
    if (age < 18) return 'under_18';
    if (age < 25) return '18_24';
    if (age < 35) return '25_34';
    if (age < 45) return '35_44';
    if (age < 55) return '45_54';
    if (age < 65) return '55_64';
    return '65_plus';
  }

  // Authentication Events
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
    } catch (e) {
      debugPrint('Error logging logout: $e');
    }
  }

  // Onboarding Events
  Future<void> logOnboardingBegin() async {
    try {
      await _analytics.logTutorialBegin();
    } catch (e) {
      debugPrint('Error logging onboarding begin: $e');
    }
  }

  Future<void> logOnboardingComplete() async {
    try {
      await _analytics.logTutorialComplete();
    } catch (e) {
      debugPrint('Error logging onboarding complete: $e');
    }
  }

  Future<void> logOnboardingStep(int step, String stepName) async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_step',
        parameters: {
          'step_number': step,
          'step_name': stepName,
        },
      );
    } catch (e) {
      debugPrint('Error logging onboarding step: $e');
    }
  }

  // Nutrition Events
  Future<void> logFoodAdded({
    required String foodName,
    required int calories,
    required String mealType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'food_added',
        parameters: {
          'food_name': foodName,
          'calories': calories,
          'meal_type': mealType,
        },
      );
    } catch (e) {
      debugPrint('Error logging food added: $e');
    }
  }

  Future<void> logWaterIntake(int glasses) async {
    try {
      await _analytics.logEvent(
        name: 'water_intake_updated',
        parameters: {
          'glasses': glasses,
        },
      );
    } catch (e) {
      debugPrint('Error logging water intake: $e');
    }
  }

  Future<void> logDailyNutritionGoalMet() async {
    try {
      await _analytics.logEvent(name: 'daily_nutrition_goal_met');
    } catch (e) {
      debugPrint('Error logging nutrition goal met: $e');
    }
  }

  // Streak Events
  Future<void> logStreakAchieved(int days) async {
    try {
      await _analytics.logEvent(
        name: 'streak_achieved',
        parameters: {
          'days': days,
          'is_milestone': _isMilestone(days),
        },
      );
    } catch (e) {
      debugPrint('Error logging streak achieved: $e');
    }
  }

  Future<void> logStreakBroken(int previousStreak) async {
    try {
      await _analytics.logEvent(
        name: 'streak_broken',
        parameters: {
          'previous_streak': previousStreak,
        },
      );
    } catch (e) {
      debugPrint('Error logging streak broken: $e');
    }
  }

  bool _isMilestone(int days) {
    return days == 7 || days == 30 || days == 100 || days == 365;
  }

  // Health Events
  Future<void> logHealthDataSynced(String dataType) async {
    try {
      await _analytics.logEvent(
        name: 'health_data_synced',
        parameters: {
          'data_type': dataType,
        },
      );
    } catch (e) {
      debugPrint('Error logging health data sync: $e');
    }
  }

  Future<void> logWorkoutCompleted({
    required String workoutType,
    required int duration,
    int? caloriesBurned,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'workout_completed',
        parameters: {
          'workout_type': workoutType,
          'duration_minutes': duration,
          if (caloriesBurned != null) 'calories_burned': caloriesBurned,
        },
      );
    } catch (e) {
      debugPrint('Error logging workout: $e');
    }
  }

  // AI Coach Events
  Future<void> logAICoachInteraction({
    required String messageType,
    String? topic,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_coach_interaction',
        parameters: {
          'message_type': messageType,
          if (topic != null) 'topic': topic,
        },
      );
    } catch (e) {
      debugPrint('Error logging AI interaction: $e');
    }
  }

  // App Usage Events
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Error logging app open: $e');
    }
  }

  Future<void> logShare({
    required String contentType,
    required String method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        method: method,
        itemId: 'shared_content',
      );
    } catch (e) {
      debugPrint('Error logging share: $e');
    }
  }

  // Achievement Events
  Future<void> logAchievementUnlocked(String achievementId) async {
    try {
      await _analytics.logUnlockAchievement(id: achievementId);
    } catch (e) {
      debugPrint('Error logging achievement: $e');
    }
  }

  Future<void> logLevelUp(int level) async {
    try {
      await _analytics.logLevelUp(
        level: level,
        character: null,
      );
    } catch (e) {
      debugPrint('Error logging level up: $e');
    }
  }

  // Custom Events
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging custom event: $e');
    }
  }

  // Revenue Events (for future premium features)
  Future<void> logPurchase({
    required double value,
    required String currency,
    required String itemId,
    required String itemName,
  }) async {
    try {
      await _analytics.logPurchase(
        value: value,
        currency: currency,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            quantity: 1,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error logging purchase: $e');
    }
  }
}