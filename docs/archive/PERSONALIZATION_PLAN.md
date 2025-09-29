# Streaker AI Personalization Plan

## Current State Analysis
The app currently has basic context passing to GROK but lacks comprehensive personalization. The available data includes:

### User Profile Data
- Name, age, height, weight
- Fitness goal (weight loss, muscle gain, maintenance, endurance)
- Activity level (sedentary to extremely active)
- Current streak count

### Health Metrics (from HealthKit)
- Steps count
- Calories burned
- Heart rate (resting and active)
- Sleep duration and quality
- Water intake
- Body measurements

### Nutrition Data
- Daily calorie intake & goal
- Macros (protein, carbs, fat) intake & goals
- Meal history
- Food preferences

### Workout Data
- Exercise history
- Workout frequency
- Performance metrics

## Proposed Solution: Enhanced Context System

### Option 1: Dynamic System Prompt (RECOMMENDED)
**Pros:**
- Most flexible and maintainable
- Adjusts based on available data
- Easy to update without code changes
- Provides rich context to GROK

**Implementation:**
1. Create a `UserContextBuilder` class that aggregates all user data
2. Generate a dynamic system prompt with user's complete profile
3. Include recent trends and patterns
4. Add time-based context (morning/evening, weekday/weekend)

### Option 2: Structured Context Messages
**Pros:**
- Clear separation of concerns
- Easy to debug
- Can be cached

**Cons:**
- May hit token limits
- Less natural conversation flow

### Option 3: Fine-tuned Model
**Pros:**
- Best personalization
- Faster responses

**Cons:**
- Requires model training
- Not feasible with GROK API
- High maintenance

## Recommended Implementation Steps

### 1. Enhanced Context Builder
```dart
class UserContextBuilder {
  // Gather all available user data
  Map<String, dynamic> buildComprehensiveContext() {
    return {
      'profile': {...},
      'healthMetrics': {...},
      'nutritionData': {...},
      'workoutHistory': {...},
      'preferences': {...},
      'recentActivity': {...},
      'goals': {...},
      'challenges': {...}
    };
  }
}
```

### 2. Dynamic System Prompt Generation
```dart
String generatePersonalizedSystemPrompt(Map<String, dynamic> context) {
  return '''
  You are Streaker, a highly personalized AI fitness coach for ${context['name']}.
  
  User Profile:
  - Age: ${context['age']}, Height: ${context['height']}cm, Weight: ${context['weight']}kg
  - Goal: ${context['goal']} with ${context['activityLevel']} activity level
  - Current streak: ${context['streak']} days
  
  Recent Health Metrics:
  - Average daily steps: ${context['avgSteps']}
  - Resting heart rate: ${context['restingHR']} bpm
  - Sleep average: ${context['avgSleep']} hours
  - Water intake: ${context['waterIntake']}L daily
  
  Nutrition Pattern:
  - Daily calorie goal: ${context['calorieGoal']} (currently at ${context['calorieProgress']}%)
  - Protein goal: ${context['proteinGoal']}g
  - Preferred meal times: ${context['mealPattern']}
  
  Workout Routine:
  - Frequency: ${context['workoutFrequency']}
  - Preferred exercises: ${context['preferredExercises']}
  - Recent performance: ${context['recentPerformance']}
  
  Behavioral Insights:
  - Best performance time: ${context['optimalTime']}
  - Motivation triggers: ${context['motivationFactors']}
  - Common challenges: ${context['challenges']}
  
  IMPORTANT INSTRUCTIONS:
  1. Always reference the user's specific data when giving advice
  2. Acknowledge their current streak and progress
  3. Tailor recommendations to their goal and activity level
  4. Consider their recent metrics when suggesting changes
  5. Be aware of their schedule and preferences
  6. Celebrate achievements based on their personal milestones
  7. Address them by name occasionally for personal touch
  8. Adjust intensity of recommendations based on their experience level
  ''';
}
```

### 3. Context Update Frequency
- **Real-time**: User profile, current day metrics
- **Hourly**: Steps, calories, water intake
- **Daily**: Sleep, weight, workout completion
- **Weekly**: Progress trends, goal adjustments

### 4. Privacy & Performance Considerations
- Cache context for 5 minutes to reduce API calls
- Only send relevant context based on query type
- Implement context size limits (max 2000 tokens)
- Store conversation history locally for continuity

## Implementation Priority
1. **Phase 1**: Basic profile + current day metrics
2. **Phase 2**: Historical trends + patterns
3. **Phase 3**: Behavioral insights + predictions
4. **Phase 4**: Advanced personalization with ML patterns

## Benefits of This Approach
- Highly personalized responses from day 1
- Scalable and maintainable
- Works with existing GROK API
- No additional training required
- Progressive enhancement possible