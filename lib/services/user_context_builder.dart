import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_metric_model.dart';

class UserContextBuilder {
  static Map<String, dynamic> buildComprehensiveContext(BuildContext buildContext) {
    final userProvider = Provider.of<UserProvider>(buildContext, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(buildContext, listen: false);
    final healthProvider = Provider.of<HealthProvider>(buildContext, listen: false);
    
    final profile = userProvider.profile;
    final streakData = userProvider.streakData;
    final todayNutrition = nutritionProvider.todayNutrition;
    final weeklyNutrition = <DailyNutrition>[]; // Weekly nutrition to be implemented
    final healthMetrics = healthProvider.metrics;
    
    // Build comprehensive context
    final context = <String, dynamic>{};
    
    // User Profile Information
    if (profile != null) {
      context['name'] = profile.name;
      context['age'] = profile.age;
      context['height'] = profile.height;
      context['weight'] = profile.weight;
      context['bmi'] = _calculateBMI(profile.height, profile.weight);
      context['goal'] = _formatGoal(profile.goal?.toString());
      context['activityLevel'] = _formatActivityLevel(profile.activityLevel?.toString());
      context['experienceLevel'] = _determineExperienceLevel(profile.activityLevel?.toString());
    }
    
    // Streak and Consistency Data
    if (streakData != null) {
      context['currentStreak'] = streakData.currentStreak;
      context['longestStreak'] = streakData.longestStreak;
      context['totalDaysLogged'] = streakData.activityDates.length;
      context['consistency'] = _calculateConsistency(streakData);
    }
    
    // Today's Nutrition
    context['todayCalories'] = todayNutrition.totalCalories.round();
    context['todayProtein'] = todayNutrition.totalProtein.round();
    context['todayCarbs'] = todayNutrition.totalCarbs.round();
    context['todayFat'] = todayNutrition.totalFat.round();
    context['todayWater'] = 0; // Water tracking to be implemented
    
    // Nutrition Goals
    context['calorieGoal'] = nutritionProvider.calorieGoal.round();
    context['proteinGoal'] = nutritionProvider.proteinGoal.round();
    context['carbGoal'] = nutritionProvider.carbGoal.round();
    context['fatGoal'] = nutritionProvider.fatGoal.round();
    context['waterGoal'] = 8; // Default 8 glasses
    
    // Nutrition Progress
    context['calorieProgress'] = ((todayNutrition.totalCalories / nutritionProvider.calorieGoal) * 100).round();
    context['proteinProgress'] = ((todayNutrition.totalProtein / nutritionProvider.proteinGoal) * 100).round();
    context['carbProgress'] = ((todayNutrition.totalCarbs / nutritionProvider.carbGoal) * 100).round();
    context['fatProgress'] = ((todayNutrition.totalFat / nutritionProvider.fatGoal) * 100).round();
    context['waterProgress'] = 0; // Water tracking to be implemented
    
    // Weekly Nutrition Averages
    if (weeklyNutrition.isNotEmpty) {
      double avgCalories = 0;
      double avgProtein = 0;
      double avgCarbs = 0;
      double avgFat = 0;
      
      for (var day in weeklyNutrition) {
        avgCalories += day.totalCalories;
        avgProtein += day.totalProtein;
        avgCarbs += day.totalCarbs;
        avgFat += day.totalFat;
      }
      
      int days = weeklyNutrition.length;
      context['weeklyAvgCalories'] = (avgCalories / days).round();
      context['weeklyAvgProtein'] = (avgProtein / days).round();
      context['weeklyAvgCarbs'] = (avgCarbs / days).round();
      context['weeklyAvgFat'] = (avgFat / days).round();
    }
    
    // Health Metrics
    if (healthMetrics.isNotEmpty) {
      // Steps
      if (healthMetrics.containsKey(MetricType.steps)) {
        final stepsData = healthMetrics[MetricType.steps];
        context['todaySteps'] = stepsData?.currentValue?.round() ?? 0;
        context['avgSteps'] = stepsData?.currentValue?.round() ?? 0; // Using current as average for now
        context['stepsGoal'] = 10000; // Default goal
        context['stepsProgress'] = ((stepsData?.currentValue ?? 0) / 10000 * 100).round();
      }
      
      // Heart Rate
      if (healthMetrics.containsKey(MetricType.restingHeartRate)) {
        final hrData = healthMetrics[MetricType.restingHeartRate];
        context['restingHeartRate'] = hrData?.currentValue?.round() ?? 0;
        context['avgHeartRate'] = hrData?.currentValue?.round() ?? 0; // Using current as average
      }
      
      // Sleep
      if (healthMetrics.containsKey(MetricType.sleep)) {
        final sleepData = healthMetrics[MetricType.sleep];
        context['lastNightSleep'] = (sleepData?.currentValue ?? 0).toStringAsFixed(1);
        context['avgSleep'] = (sleepData?.currentValue ?? 0).toStringAsFixed(1);
        context['sleepGoal'] = 8; // Default 8 hours
      }
      
      // Calories Burned
      if (healthMetrics.containsKey(MetricType.caloriesIntake)) {
        final calorieData = healthMetrics[MetricType.caloriesIntake];
        context['caloriesBurned'] = calorieData?.currentValue?.round() ?? 0;
      }
    }
    
    // Time-based Context
    final now = DateTime.now();
    context['currentHour'] = now.hour;
    context['dayOfWeek'] = _getDayOfWeek(now.weekday);
    context['timeOfDay'] = _getTimeOfDay(now.hour);
    context['isWeekend'] = now.weekday == 6 || now.weekday == 7;
    
    // Meal timing context
    context['mealTime'] = _getMealTime(now.hour);
    context['shouldHydrate'] = _shouldRemindHydration(0, now.hour); // Water tracking to be implemented
    
    // Performance Insights
    context['nutritionAdherence'] = _calculateNutritionAdherence(
      todayNutrition.totalCalories.toDouble(),
      nutritionProvider.calorieGoal.toDouble(),
    );
    
    // Motivational Context
    context['needsMotivation'] = _needsMotivation(streakData?.currentStreak ?? 0);
    context['recentMilestone'] = _getRecentMilestone(streakData);
    
    return context;
  }
  
  static String generatePersonalizedSystemPrompt(Map<String, dynamic> context) {
    final name = context['name'] ?? 'there';
    final age = context['age'] ?? 'unknown';
    final goal = context['goal'] ?? 'general fitness';
    final activityLevel = context['activityLevel'] ?? 'moderate';
    final experienceLevel = context['experienceLevel'] ?? 'intermediate';
    final currentStreak = context['currentStreak'] ?? 0;
    final consistency = context['consistency'] ?? 0;
    
    // Build dynamic system prompt
    String systemPrompt = '''
You are Streaker, a highly personalized AI fitness coach specifically tailored for $name.

USER PROFILE:
- Name: $name
- Age: $age years old
- Physical Stats: Height ${context['height']}cm, Weight ${context['weight']}kg, BMI ${context['bmi']}
- Primary Goal: $goal
- Activity Level: $activityLevel
- Experience Level: $experienceLevel
- Current Streak: $currentStreak days (Longest: ${context['longestStreak'] ?? 0} days)
- Consistency Rate: $consistency%

CURRENT HEALTH METRICS:
- Today's Steps: ${context['todaySteps'] ?? 0} / ${context['stepsGoal'] ?? 10000} goal (${context['stepsProgress'] ?? 0}% complete)
- Average Daily Steps: ${context['avgSteps'] ?? 0}
- Resting Heart Rate: ${context['restingHeartRate'] ?? 'not tracked'} bpm
- Last Night's Sleep: ${context['lastNightSleep'] ?? 'not tracked'} hours
- Average Sleep: ${context['avgSleep'] ?? 'not tracked'} hours

TODAY'S NUTRITION STATUS (${context['timeOfDay']} - ${context['mealTime']}):
- Calories: ${context['todayCalories']} / ${context['calorieGoal']} kcal (${context['calorieProgress']}%)
- Protein: ${context['todayProtein']}g / ${context['proteinGoal']}g (${context['proteinProgress']}%)
- Carbs: ${context['todayCarbs']}g / ${context['carbGoal']}g (${context['carbProgress']}%)
- Fat: ${context['todayFat']}g / ${context['fatGoal']}g (${context['fatProgress']}%)
- Water: ${context['todayWater']}L / ${context['waterGoal']}L (${context['waterProgress']}%)

WEEKLY AVERAGES:
- Calories: ${context['weeklyAvgCalories'] ?? 'no data'} kcal/day
- Protein: ${context['weeklyAvgProtein'] ?? 'no data'}g/day
- Adherence Rate: ${context['nutritionAdherence'] ?? 0}%

CONTEXTUAL AWARENESS:
- Current Time: ${context['timeOfDay']} (${context['currentHour']}:00)
- Day: ${context['dayOfWeek']} ${context['isWeekend'] ? '(Weekend)' : '(Weekday)'}
- Meal Period: ${context['mealTime']}
- Hydration Reminder Needed: ${context['shouldHydrate'] ? 'Yes' : 'No'}

PERSONALIZATION INSTRUCTIONS:

1. ALWAYS address the user as $name when appropriate, but not excessively.

2. GOAL-SPECIFIC GUIDANCE:
   ${_getGoalSpecificInstructions(goal)}

3. EXPERIENCE-LEVEL APPROPRIATE:
   ${_getExperienceLevelInstructions(experienceLevel)}

4. TIME-AWARE RESPONSES:
   - Morning: Focus on daily planning, motivation, and breakfast suggestions
   - Afternoon: Check-in on progress, suggest healthy snacks, remind about hydration
   - Evening: Review daily achievements, suggest dinner options, prepare for tomorrow
   - Night: Emphasize recovery, sleep importance, and reflection

5. STREAK & MOTIVATION:
   ${currentStreak > 0 ? '- Acknowledge their $currentStreak day streak positively' : '- Encourage them to start building a streak'}
   ${context['needsMotivation'] ? '- Provide extra motivation and support' : ''}
   ${context['recentMilestone'] != null ? '- Celebrate their recent milestone: ${context['recentMilestone']}' : ''}

6. CURRENT PROGRESS AWARENESS:
   - Calories: ${_getProgressFeedback(context['calorieProgress'] ?? 0, 'calories')}
   - Protein: ${_getProgressFeedback(context['proteinProgress'] ?? 0, 'protein')}
   - Steps: ${_getProgressFeedback(context['stepsProgress'] ?? 0, 'steps')}
   - Water: ${_getProgressFeedback(context['waterProgress'] ?? 0, 'water')}

7. PERSONALIZED RECOMMENDATIONS:
   - Base suggestions on their actual data, not generic advice
   - Reference their specific numbers when giving feedback
   - Adjust intensity based on their current activity level
   - Consider their sleep quality when suggesting workout intensity
   - Factor in their consistency rate when setting expectations

8. COMMUNICATION STYLE:
   - Be encouraging but realistic
   - Celebrate small wins based on their personal progress
   - Use their historical data to show improvements
   - Be understanding on low-performance days
   - Maintain a supportive, friend-like tone while being professional

Remember: You have access to $name's real-time data. Use it to provide highly specific, actionable advice that fits their current situation, not generic fitness tips.

IMPORTANT RESPONSE GUIDELINES:
- Keep responses comprehensive but within 1500 words to ensure complete delivery
- Focus on the most relevant information for the user's query
- If a topic requires extensive detail, offer to elaborate in follow-up messages
- Structure responses with clear sections using headers and bullet points for readability
- Ensure every response is complete and doesn't end abruptly
''';

    return systemPrompt;
  }
  
  // Helper Methods
  static double _calculateBMI(double height, double weight) {
    if (height <= 0 || weight <= 0) return 0;
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }
  
  static String _formatGoal(String? goal) {
    if (goal == null) return 'general fitness';
    switch (goal) {
      case 'FitnessGoal.weightLoss':
        return 'weight loss';
      case 'FitnessGoal.muscleGain':
        return 'muscle gain';
      case 'FitnessGoal.maintenance':
        return 'fitness maintenance';
      case 'FitnessGoal.endurance':
        return 'endurance building';
      default:
        return 'general fitness';
    }
  }
  
  static String _formatActivityLevel(String? level) {
    if (level == null) return 'moderate';
    switch (level) {
      case 'ActivityLevel.sedentary':
        return 'sedentary';
      case 'ActivityLevel.lightlyActive':
        return 'lightly active';
      case 'ActivityLevel.moderatelyActive':
        return 'moderately active';
      case 'ActivityLevel.veryActive':
        return 'very active';
      case 'ActivityLevel.extremelyActive':
        return 'extremely active';
      default:
        return 'moderate';
    }
  }
  
  static String _determineExperienceLevel(String? activityLevel) {
    if (activityLevel == null) return 'intermediate';
    if (activityLevel.contains('sedentary') || activityLevel.contains('lightly')) {
      return 'beginner';
    } else if (activityLevel.contains('extremely') || activityLevel.contains('very')) {
      return 'advanced';
    }
    return 'intermediate';
  }
  
  static int _calculateConsistency(dynamic streakData) {
    if (streakData == null) return 0;
    int totalDays = streakData.activityDates?.length ?? 0;
    if (totalDays == 0) return 0;
    // Calculate based on current streak vs total activity days
    return ((streakData.currentStreak / (streakData.currentStreak + 7)) * 100).round().clamp(0, 100);
  }
  
  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  static String _getTimeOfDay(int hour) {
    if (hour < 6) return 'early morning';
    if (hour < 12) return 'morning';
    if (hour < 15) return 'afternoon';
    if (hour < 18) return 'late afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }
  
  static String _getMealTime(int hour) {
    if (hour >= 6 && hour < 10) return 'breakfast time';
    if (hour >= 10 && hour < 12) return 'mid-morning snack time';
    if (hour >= 12 && hour < 15) return 'lunch time';
    if (hour >= 15 && hour < 17) return 'afternoon snack time';
    if (hour >= 17 && hour < 20) return 'dinner time';
    if (hour >= 20 && hour < 22) return 'evening snack time';
    return 'outside typical meal times';
  }
  
  static bool _shouldRemindHydration(double currentWater, int hour) {
    // Remind if less than expected water intake for the time of day
    double expectedWater = (hour / 24.0) * 2.5; // Assuming 2.5L daily goal
    return currentWater < expectedWater * 0.8; // 80% of expected
  }
  
  static int _calculateNutritionAdherence(double actual, double goal) {
    if (goal <= 0) return 0;
    double ratio = actual / goal;
    // Perfect is 90-110% of goal
    if (ratio >= 0.9 && ratio <= 1.1) return 100;
    // Calculate adherence based on deviation
    double deviation = (ratio - 1.0).abs();
    return (100 - (deviation * 100)).round().clamp(0, 100);
  }
  
  static bool _needsMotivation(int currentStreak) {
    // Need motivation if streak is low or at risk
    return currentStreak < 3 || currentStreak % 7 == 6; // Day before weekly milestone
  }
  
  static String? _getRecentMilestone(dynamic streakData) {
    if (streakData == null) return null;
    int current = streakData.currentStreak ?? 0;
    
    if (current == 7) return '1 week streak!';
    if (current == 14) return '2 week streak!';
    if (current == 30) return '1 month streak!';
    if (current == 60) return '2 month streak!';
    if (current == 90) return '3 month streak!';
    if (current == 100) return '100 day streak!';
    if (current == 365) return '1 year streak!';
    
    return null;
  }
  
  static String _getGoalSpecificInstructions(String goal) {
    switch (goal) {
      case 'weight loss':
        return '''
   - Focus on calorie deficit maintenance
   - Emphasize high-protein, low-calorie foods
   - Suggest cardio and strength training combinations
   - Monitor weekly weight trends
   - Encourage sustainable habits over quick fixes''';
      
      case 'muscle gain':
        return '''
   - Emphasize protein intake optimization
   - Focus on progressive overload in training
   - Suggest calorie surplus when appropriate
   - Prioritize recovery and sleep
   - Recommend compound exercises''';
      
      case 'endurance building':
        return '''
   - Focus on cardiovascular improvements
   - Suggest progressive distance/time increases
   - Emphasize proper fueling strategies
   - Monitor heart rate trends
   - Recommend cross-training activities''';
      
      default:
        return '''
   - Focus on balanced nutrition
   - Encourage consistent activity
   - Promote overall wellness
   - Suggest variety in exercises
   - Maintain healthy habits''';
    }
  }
  
  static String _getExperienceLevelInstructions(String level) {
    switch (level) {
      case 'beginner':
        return '''
   - Use simple, clear explanations
   - Focus on building basic habits
   - Provide detailed form instructions
   - Start with achievable goals
   - Offer more encouragement and guidance''';
      
      case 'advanced':
        return '''
   - Provide detailed, technical information
   - Suggest advanced training techniques
   - Focus on optimization and fine-tuning
   - Discuss periodization and programming
   - Challenge with ambitious but realistic goals''';
      
      default:
        return '''
   - Balance technical and practical advice
   - Suggest progressive challenges
   - Focus on consistency and improvement
   - Provide moderate detail in explanations
   - Encourage stepping out of comfort zone''';
    }
  }
  
  static String _getProgressFeedback(int progress, String metric) {
    if (progress < 25) {
      return 'Needs attention - encourage increasing $metric intake';
    } else if (progress < 50) {
      return 'Below target - suggest ways to boost $metric';
    } else if (progress < 75) {
      return 'Good progress - remind to maintain $metric intake';
    } else if (progress < 90) {
      return 'Nearly there - final push for $metric goal';
    } else if (progress <= 110) {
      return 'On target - excellent $metric management';
    } else {
      return 'Above target - monitor if intentional for $metric';
    }
  }
}