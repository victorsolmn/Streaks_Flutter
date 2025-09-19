import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/health_provider.dart';
import '../models/achievement_model.dart';

class AchievementChecker {
  static Future<void> checkAllAchievements(BuildContext context) async {
    try {
      final achievementProvider = context.read<AchievementProvider>();
      final streakProvider = context.read<StreakProvider>();
      final healthProvider = context.read<HealthProvider>();

      await _checkStreakAchievements(streakProvider, achievementProvider);
      await _checkWorkoutAchievements(healthProvider, achievementProvider);
      await _checkSpecialAchievements(streakProvider, healthProvider, achievementProvider);
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  static Future<void> _checkStreakAchievements(
    StreakProvider streakProvider,
    AchievementProvider achievementProvider,
  ) async {
    final currentStreak = streakProvider.currentStreak;

    // Update progress for all streak achievements
    final streakMilestones = {
      'no_excuses': 3,
      'sweat_starter': 7,
      'grind_machine': 14,
      'beast_mode': 21,
      'iron_month': 30,
      'quarter_crusher': 90,
      'half_year': 180,
      'year_one': 365,
      'streak_titan': 500,
      'immortal': 1000,
    };

    for (final entry in streakMilestones.entries) {
      final achievement = achievementProvider.getAchievementById(entry.key);
      if (achievement == null) continue;

      // Update progress
      await achievementProvider.updateProgress(entry.key, currentStreak);

      // Check if should unlock
      if (!achievement.isUnlocked && currentStreak >= entry.value) {
        await achievementProvider.unlockAchievement(entry.key);
        _showUnlockNotification(achievement);
      }
    }
  }

  static Future<void> _checkWorkoutAchievements(
    HealthProvider healthProvider,
    AchievementProvider achievementProvider,
  ) async {
    // Check "Warm-up Warrior" - first workout
    final totalWorkouts = healthProvider.todayWorkouts;
    if (totalWorkouts > 0) {
      final achievement = achievementProvider.getAchievementById('warm_up');
      if (achievement != null && !achievement.isUnlocked) {
        await achievementProvider.unlockAchievement('warm_up');
        _showUnlockNotification(achievement);
      }
    }

    // Note: For weekend and midnight workouts, we'd need to check
    // the actual workout timestamps which would require more integration
    // with the health metrics system
  }

  static Future<void> _checkSpecialAchievements(
    StreakProvider streakProvider,
    HealthProvider healthProvider,
    AchievementProvider achievementProvider,
  ) async {
    // Check "Comeback Kid" - requires tracking streak loss and recovery
    // This would need additional state to track when a streak was lost
    // and when it was recovered

    // For now, we'll check if user has a current streak after having lost one
    final currentStreak = streakProvider.currentStreak;
    final longestStreak = streakProvider.longestStreak;

    if (currentStreak >= 3 && longestStreak > currentStreak) {
      // User had a longer streak before and has now recovered
      final achievement = achievementProvider.getAchievementById('comeback_kid');
      if (achievement != null && !achievement.isUnlocked) {
        await achievementProvider.unlockAchievement('comeback_kid');
        _showUnlockNotification(achievement);
      }
    }

    // Check "Sweatflix & Chill" - weekend workout
    final now = DateTime.now();
    if ((now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) &&
        healthProvider.todayWorkouts > 0) {
      final achievement = achievementProvider.getAchievementById('sweatflix');
      if (achievement != null && !achievement.isUnlocked) {
        await achievementProvider.unlockAchievement('sweatflix');
        _showUnlockNotification(achievement);
      }
    }

    // Check "Gym Goblin" - midnight workout (between 12am-3am)
    if ((now.hour >= 0 && now.hour <= 3) && healthProvider.todayWorkouts > 0) {
      final achievement = achievementProvider.getAchievementById('gym_goblin');
      if (achievement != null && !achievement.isUnlocked) {
        await achievementProvider.unlockAchievement('gym_goblin');
        _showUnlockNotification(achievement);
      }
    }

    // Check "No Days Off Maniac" - 7 consecutive workout days
    // This would require tracking workout history for the past 7 days
    // For now, we'll use a simplified check based on current streak
    if (streakProvider.currentStreak >= 7 && healthProvider.todayWorkouts > 0) {
      final achievement = achievementProvider.getAchievementById('no_days_off');
      if (achievement != null && !achievement.isUnlocked) {
        await achievementProvider.unlockAchievement('no_days_off');
        _showUnlockNotification(achievement);
      }
    }
  }

  static void _showUnlockNotification(Achievement achievement) {
    // This would show a notification or animation
    // For now, just log it
    debugPrint('🏆 Achievement Unlocked: ${achievement.title}');

    // You could integrate with your notification service here:
    // NotificationService.showAchievementUnlock(achievement);
  }

  // Call this when the app opens or resumes
  static Future<void> checkOnAppResume(BuildContext context) async {
    final achievementProvider = context.read<AchievementProvider>();

    // Reload achievements from database
    await achievementProvider.loadAchievements();

    // Check for any new unlocks
    await checkAllAchievements(context);
  }

  // Call this after completing daily goals
  static Future<void> checkAfterGoalCompletion(BuildContext context) async {
    await checkAllAchievements(context);
  }

  // Call this after logging a workout
  static Future<void> checkAfterWorkout(BuildContext context) async {
    final healthProvider = context.read<HealthProvider>();
    final achievementProvider = context.read<AchievementProvider>();

    await _checkWorkoutAchievements(healthProvider, achievementProvider);
    await checkAllAchievements(context);
  }

  // Call this when streak updates
  static Future<void> checkAfterStreakUpdate(BuildContext context) async {
    final streakProvider = context.read<StreakProvider>();
    final achievementProvider = context.read<AchievementProvider>();

    await _checkStreakAchievements(streakProvider, achievementProvider);
  }
}