/// Supabase Schema Enums
/// These enums exactly match the database constraints

class SupabaseEnums {
  // Fitness Goal options from schema constraint
  static const List<String> fitnessGoals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Muscle',
    'Improve Fitness',
    'Build Strength',
  ];

  // Activity Level options from schema constraint
  static const List<String> activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Extra Active',
  ];

  // Experience Level options from schema constraint
  static const List<String> experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  // Workout Consistency options from schema constraint
  // Note: This field has mixed values in the schema
  static const List<String> workoutFrequency = [
    'Daily',
    '5-6 times per week',
    '3-4 times per week',
    '1-2 times per week',
    'Rarely',
    'Never',
  ];

  static const List<String> workoutExperience = [
    '< 1 year',
    '1-2 years',
    '2-3 years',
    '> 3 years',
  ];

  // Constraints for numeric fields
  static const ageMin = 13;
  static const ageMax = 120;

  static const heightMin = 50.0;
  static const heightMax = 300.0;

  static const weightMin = 20.0;
  static const weightMax = 500.0;

  static const targetWeightMin = 20.0;
  static const targetWeightMax = 500.0;

  static const dailyCaloriesMin = 500;
  static const dailyCaloriesMax = 10000;

  static const dailyStepsMin = 0;
  static const dailyStepsMax = 100000;

  static const dailySleepMin = 0.0;
  static const dailySleepMax = 24.0;

  static const dailyWaterMin = 0.0;
  static const dailyWaterMax = 20.0;

  // Helper methods for activity level multipliers
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'Sedentary':
        return 1.2;
      case 'Lightly Active':
        return 1.375;
      case 'Moderately Active':
        return 1.55;
      case 'Very Active':
        return 1.725;
      case 'Extra Active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  // Helper for fitness goal calorie adjustment
  static int getCalorieAdjustment(String fitnessGoal) {
    switch (fitnessGoal) {
      case 'Lose Weight':
        return -500; // 500 calorie deficit
      case 'Maintain Weight':
        return 0;
      case 'Gain Muscle':
        return 300; // 300 calorie surplus
      case 'Improve Fitness':
        return 0;
      case 'Build Strength':
        return 200; // 200 calorie surplus
      default:
        return 0;
    }
  }
}