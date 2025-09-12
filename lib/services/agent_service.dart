import 'dart:convert';
import 'dart:math';
import '../models/conversation_context.dart';
import '../models/user_model.dart';

class AgentService {
  static final AgentService _instance = AgentService._internal();
  factory AgentService() => _instance;
  AgentService._internal();

  // Question templates organized by category
  static const Map<String, List<Map<String, dynamic>>> _questionTemplates = {
    'profile_gaps': [
      {
        'id': 'target_weight_missing',
        'question': 'I see you haven\'t set a target weight yet. What weight are you aiming for?',
        'condition': 'targetWeight == null',
        'priority': 8,
        'canBeSkipped': true,
        'skipReason': 'Will use BMI recommendations if skipped'
      },
      {
        'id': 'activity_level_vague',
        'question': 'You mentioned being "moderately active" - could you be more specific? How many days per week do you currently exercise?',
        'condition': 'activityLevel == "Moderately Active" && detailed_schedule == null',
        'priority': 7,
        'canBeSkipped': true,
        'skipReason': 'Will use general recommendations if skipped'
      },
      {
        'id': 'dietary_preferences',
        'question': 'Do you follow any specific diet or have food restrictions? (vegetarian, keto, allergies, etc.)',
        'condition': 'dietary_preferences == null',
        'priority': 6,
        'canBeSkipped': true,
        'skipReason': 'Will provide general nutrition advice if skipped'
      },
    ],
    'goal_clarification': [
      {
        'id': 'weight_loss_timeline',
        'question': 'Great that you want to lose weight! What\'s your ideal timeline - are you looking for gradual sustainable loss or have a specific deadline in mind?',
        'condition': 'fitnessGoal == "Lose Weight" && timeline == null',
        'priority': 7,
        'canBeSkipped': true,
        'skipReason': 'Will recommend healthy 1-2 lbs/week if skipped'
      },
      {
        'id': 'muscle_gain_focus',
        'question': 'For building muscle, are you more focused on overall size, specific muscle groups, or functional strength?',
        'condition': 'fitnessGoal == "Gain Muscle" && focus_area == null',
        'priority': 6,
        'canBeSkipped': true,
        'skipReason': 'Will provide balanced full-body approach if skipped'
      },
    ],
    'challenge_identification': [
      {
        'id': 'biggest_obstacle',
        'question': 'What\'s been your biggest challenge in staying consistent with fitness? Time, motivation, energy, or something else?',
        'condition': 'challenges == null',
        'priority': 8,
        'canBeSkipped': false,
        'skipReason': null // This is important for personalization
      },
      {
        'id': 'past_failures',
        'question': 'Have you tried fitness programs before? What worked well and what didn\'t?',
        'condition': 'past_experience == null && experienceLevel != "Beginner"',
        'priority': 6,
        'canBeSkipped': true,
        'skipReason': 'Will use experience level to guide recommendations if skipped'
      },
    ],
    'preference_discovery': [
      {
        'id': 'workout_preference',
        'question': 'Do you prefer working out at home, gym, outdoors, or a mix? This helps me tailor your program.',
        'condition': 'workout_location_preference == null',
        'priority': 7,
        'canBeSkipped': true,
        'skipReason': 'Will provide flexible options for all locations if skipped'
      },
      {
        'id': 'time_availability',
        'question': 'How much time can you realistically commit to working out per session? Be honest - consistency beats perfection!',
        'condition': 'available_time == null',
        'priority': 9,
        'canBeSkipped': false,
        'skipReason': null // Critical for creating realistic programs
      },
    ],
    'motivational_support': [
      {
        'id': 'motivation_check',
        'question': 'On a scale of 1-10, how motivated are you feeling about your fitness journey right now?',
        'condition': 'recent_motivation == null',
        'priority': 5,
        'canBeSkipped': true,
        'skipReason': 'Will provide general motivation if skipped'
      },
      {
        'id': 'support_system',
        'question': 'Do you have friends or family supporting your fitness goals, or are you going it alone?',
        'condition': 'support_system == null',
        'priority': 4,
        'canBeSkipped': true,
        'skipReason': 'Will focus on self-motivation strategies if skipped'
      },
    ],
  };

  // Generate context-aware questions based on user profile and conversation history
  List<AgentQuestion> generateQuestions({
    required UserProfile userProfile,
    required ConversationContext context,
    int maxQuestions = 3,
  }) {
    List<AgentQuestion> potentialQuestions = [];
    
    // Analyze profile gaps and generate appropriate questions
    potentialQuestions.addAll(_generateProfileGapQuestions(userProfile, context));
    potentialQuestions.addAll(_generateGoalClarificationQuestions(userProfile, context));
    potentialQuestions.addAll(_generateChallengeQuestions(userProfile, context));
    potentialQuestions.addAll(_generatePreferenceQuestions(userProfile, context));
    
    // Add motivational questions if user seems disengaged
    if (_shouldAskMotivationalQuestions(context)) {
      potentialQuestions.addAll(_generateMotivationalQuestions(userProfile, context));
    }

    // Filter out already asked questions
    potentialQuestions = potentialQuestions
        .where((q) => !context.hasAskedQuestion(q.id))
        .toList();

    // Sort by priority (descending) and return top questions
    potentialQuestions.sort((a, b) => b.priority.compareTo(a.priority));
    
    return potentialQuestions.take(maxQuestions).toList();
  }

  List<AgentQuestion> _generateProfileGapQuestions(UserProfile profile, ConversationContext context) {
    List<AgentQuestion> questions = [];
    
    // Check for missing target weight
    if (profile.targetWeight == null) {
      questions.add(AgentQuestion(
        id: 'target_weight_missing',
        question: 'I see you haven\'t set a target weight yet. What weight are you aiming for, or would you prefer to focus on how you feel rather than the scale?',
        type: QuestionType.profileGap,
        priority: 8,
        expectedAnswerTypes: ['number', 'text'],
        canBeSkipped: true,
        skipReason: 'I\'ll use healthy BMI recommendations based on your height',
      ));
    }

    // Check for vague activity level
    if (profile.activityLevel == 'Moderately Active' && !context.hasAskedQuestion('activity_details')) {
      questions.add(AgentQuestion(
        id: 'activity_details',
        question: 'You mentioned being "moderately active" - could you be more specific? How many days per week do you currently exercise and what do you typically do?',
        type: QuestionType.profileGap,
        priority: 7,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll create a flexible program that can adapt to your actual activity level',
      ));
    }

    // Check for dietary information
    if (!context.hasAskedQuestion('dietary_info')) {
      questions.add(AgentQuestion(
        id: 'dietary_info',
        question: 'Do you follow any specific diet or have food restrictions I should know about? (vegetarian, keto, allergies, cultural preferences, etc.)',
        type: QuestionType.profileGap,
        priority: 6,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll provide general healthy eating recommendations',
      ));
    }

    return questions;
  }

  List<AgentQuestion> _generateGoalClarificationQuestions(UserProfile profile, ConversationContext context) {
    List<AgentQuestion> questions = [];
    
    if (profile.fitnessGoal == 'Lose Weight' && !context.hasAskedQuestion('weight_loss_approach')) {
      questions.add(AgentQuestion(
        id: 'weight_loss_approach',
        question: 'For your weight loss goal, are you looking for steady, sustainable progress or do you have a specific deadline in mind? What\'s driving this goal for you?',
        type: QuestionType.goalClarification,
        priority: 7,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll recommend healthy 1-2 lbs per week approach',
      ));
    }

    if (profile.fitnessGoal == 'Gain Muscle' && !context.hasAskedQuestion('muscle_focus')) {
      questions.add(AgentQuestion(
        id: 'muscle_focus',
        question: 'For building muscle, are you more interested in overall size, specific muscle groups, or functional strength for daily activities?',
        type: QuestionType.goalClarification,
        priority: 6,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll create a balanced full-body muscle building program',
      ));
    }

    return questions;
  }

  List<AgentQuestion> _generateChallengeQuestions(UserProfile profile, ConversationContext context) {
    List<AgentQuestion> questions = [];
    
    if (!context.hasAskedQuestion('main_challenge')) {
      questions.add(AgentQuestion(
        id: 'main_challenge',
        question: 'What\'s been your biggest challenge in staying consistent with fitness? Is it time, motivation, energy levels, or something else entirely?',
        type: QuestionType.challengeIdentification,
        priority: 8,
        expectedAnswerTypes: ['text'],
        canBeSkipped: false, // This is crucial for personalization
      ));
    }

    if (profile.experienceLevel != 'Beginner' && !context.hasAskedQuestion('past_experience')) {
      questions.add(AgentQuestion(
        id: 'past_experience',
        question: 'Since you have some fitness experience, what has worked well for you in the past, and what hasn\'t been sustainable?',
        type: QuestionType.challengeIdentification,
        priority: 6,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll use your experience level to guide recommendations',
      ));
    }

    return questions;
  }

  List<AgentQuestion> _generatePreferenceQuestions(UserProfile profile, ConversationContext context) {
    List<AgentQuestion> questions = [];
    
    if (!context.hasAskedQuestion('workout_location')) {
      questions.add(AgentQuestion(
        id: 'workout_location',
        question: 'Do you prefer working out at home, at a gym, outdoors, or a mix of locations? This will help me tailor your program perfectly.',
        type: QuestionType.preferenceDiscovery,
        priority: 7,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll provide flexible options that work for any location',
      ));
    }

    if (!context.hasAskedQuestion('time_availability')) {
      questions.add(AgentQuestion(
        id: 'time_availability',
        question: 'How much time can you realistically commit to working out per session? Be honest with me - I\'d rather create a 20-minute routine you\'ll actually do than a 60-minute one you\'ll skip!',
        type: QuestionType.preferenceDiscovery,
        priority: 9,
        expectedAnswerTypes: ['number', 'text'],
        canBeSkipped: false, // Critical for realistic planning
      ));
    }

    return questions;
  }

  List<AgentQuestion> _generateMotivationalQuestions(UserProfile profile, ConversationContext context) {
    List<AgentQuestion> questions = [];
    
    if (!context.hasAskedQuestion('current_motivation')) {
      questions.add(AgentQuestion(
        id: 'current_motivation',
        question: 'How are you feeling about your fitness journey right now? Excited, overwhelmed, determined, or maybe a mix of emotions?',
        type: QuestionType.motivationalSupport,
        priority: 5,
        expectedAnswerTypes: ['text'],
        canBeSkipped: true,
        skipReason: 'I\'ll provide general encouragement and motivation',
      ));
    }

    return questions;
  }

  bool _shouldAskMotivationalQuestions(ConversationContext context) {
    // Ask motivational questions if:
    // - User hasn't interacted in a while
    // - User has answered negatively to previous questions
    // - It's been more than a few interactions without checking motivation
    
    final daysSinceLastInteraction = DateTime.now().difference(context.lastInteraction).inDays;
    return daysSinceLastInteraction > 3 || context.askedQuestions.length > 5;
  }

  // Generate a natural, context-aware follow-up question based on user's response
  AgentQuestion? generateFollowUpQuestion({
    required AgentQuestion originalQuestion,
    required String userResponse,
    required UserProfile userProfile,
    required ConversationContext context,
  }) {
    // Analyze response and generate appropriate follow-up
    final response = userResponse.toLowerCase();
    
    switch (originalQuestion.id) {
      case 'main_challenge':
        if (response.contains('time')) {
          return AgentQuestion(
            id: 'time_challenge_details',
            question: 'I hear you on the time challenge! What does your typical day look like? Are mornings, lunch breaks, or evenings more realistic for you?',
            type: QuestionType.challengeIdentification,
            priority: 8,
            canBeSkipped: true,
            skipReason: 'I\'ll suggest flexible timing options',
          );
        } else if (response.contains('motivation')) {
          return AgentQuestion(
            id: 'motivation_trigger',
            question: 'Motivation can be tricky! What usually gets you excited about working out, and what tends to kill that motivation?',
            type: QuestionType.motivationalSupport,
            priority: 7,
            canBeSkipped: true,
            skipReason: 'I\'ll provide general motivation strategies',
          );
        }
        break;
        
      case 'target_weight_missing':
        if (response.contains('feel') || response.contains('clothes') || response.contains('energy')) {
          return AgentQuestion(
            id: 'non_scale_goals',
            question: 'I love that you\'re focusing on how you feel! What specific changes are you hoping to notice - more energy, better sleep, clothes fitting differently, or something else?',
            type: QuestionType.goalClarification,
            priority: 6,
            canBeSkipped: true,
            skipReason: 'I\'ll focus on overall health and wellness improvements',
          );
        }
        break;
    }
    
    return null; // No follow-up needed
  }

  // Determine if the agent should proactively ask a question or wait for user input
  bool shouldProactivelyAsk({
    required ConversationContext context,
    required UserProfile userProfile,
  }) {
    // Be proactive if:
    // - User is new (less than 3 interactions)
    // - Haven't asked a question in the last 2 messages
    // - User seems engaged (responding well to previous questions)
    
    final isNewUser = context.askedQuestions.length < 3;
    final recentQuestionsCount = context.recentTopics
        .where((topic) => topic.contains('question'))
        .length;
    
    return isNewUser || recentQuestionsCount < 2;
  }

  // Create a skip-friendly response when user chooses to skip a question
  String generateSkipResponse(AgentQuestion question) {
    final skipReason = question.skipReason ?? 'No problem, we can always come back to this later!';
    
    return 'No worries at all! $skipReason Let\'s focus on what you\'d like to know instead. What fitness topic can I help you with today?';
  }

  // Generate an agent introduction message
  String generateIntroMessage(UserProfile userProfile) {
    final name = userProfile.name.isNotEmpty ? userProfile.name : 'there';
    final goal = userProfile.fitnessGoal ?? 'your fitness goals';
    
    return '''Hey $name! 👋 I'm your AI fitness coach, and I'm here to help you achieve $goal in a way that actually works for your life.

I'd love to get to know you better so I can give you the most personalized advice possible. I might ask a few questions - but feel free to skip any you don't want to answer right now. You're in control!

What would you like to focus on today? Or should I ask you a quick question to get us started?''';
  }
}