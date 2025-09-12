import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/conversation_context.dart';
import '../models/user_model.dart';

class GrokService {
  static const String _baseUrl = ApiConfig.grokApiUrl;
  static const String _apiKey = ApiConfig.grokApiKey;
  
  // System prompt for fitness assistant
  static const String _systemPrompt = '''
You are an expert AI fitness coach and personal trainer named Coach. Your role is to help users achieve their fitness goals through personalized advice on nutrition, exercise, recovery, and motivation.

Your expertise includes:
- Nutrition planning and macro/calorie tracking
- Workout programming for various goals (weight loss, muscle gain, endurance, strength)
- Exercise form and technique guidance
- Recovery and sleep optimization
- Motivation and habit formation
- Injury prevention and management basics (always recommend seeing professionals for serious issues)

Personality traits:
- Encouraging and supportive, never judgmental
- Evidence-based approach to fitness
- Practical and realistic with recommendations
- Empathetic to struggles and setbacks
- Celebrates small wins and progress
- Uses motivational language without being overly enthusiastic

Guidelines:
1. Always prioritize safety - recommend consulting healthcare providers for medical concerns
2. Provide personalized advice based on user's goals, fitness level, and constraints
3. Give specific, actionable recommendations
4. Use simple language, avoid excessive jargon
5. Be concise but thorough - aim for complete responses within 1500 words maximum
6. Include relevant emojis occasionally to make responses more engaging
7. When discussing nutrition, consider dietary restrictions and preferences
8. For exercises, explain proper form when relevant
9. Acknowledge that fitness is a journey, not a destination
10. Remember user's context from the conversation
11. IMPORTANT: Keep responses comprehensive but focused - if a topic requires extensive detail, offer to provide more information in follow-up messages

Important: 
- Never provide medical advice or diagnose conditions
- Always suggest professional help for injuries or health concerns
- Be inclusive and respectful of all fitness levels and body types
- Focus on sustainable, long-term lifestyle changes over quick fixes
''';

  static final GrokService _instance = GrokService._internal();
  factory GrokService() => _instance;
  GrokService._internal();

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? userContext,
    String? personalizedSystemPrompt,
  }) async {
    try {
      // Build messages array with system prompt
      final messages = [
        {
          'role': 'system',
          'content': personalizedSystemPrompt ?? _systemPrompt,
        },
      ];

      // Add user context if provided and no personalized prompt
      if (userContext != null && personalizedSystemPrompt == null) {
        final contextMessage = _buildContextMessage(userContext);
        if (contextMessage.isNotEmpty) {
          messages.add({
            'role': 'system',
            'content': contextMessage,
          });
        }
      }

      // Add conversation history if provided
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Make API request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': ApiConfig.grokModel,
          'messages': messages,
          'temperature': ApiConfig.temperature,
          'max_tokens': ApiConfig.maxTokens,
          'top_p': ApiConfig.topP,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else if (response.statusCode == 401) {
        return 'API key not configured. Please add your GROK API key to use the AI coach feature.';
      } else if (response.statusCode == 429) {
        return 'I\'m a bit overwhelmed right now. Please try again in a moment! 😊';
      } else {
        print('GROK API Error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('Error calling GROK API: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  String _buildContextMessage(Map<String, dynamic> userContext) {
    final contextParts = <String>[];

    if (userContext['name'] != null) {
      contextParts.add('User name: ${userContext['name']}');
    }

    if (userContext['age'] != null) {
      contextParts.add('Age: ${userContext['age']} years');
    }

    if (userContext['height'] != null) {
      contextParts.add('Height: ${userContext['height']} cm');
    }

    if (userContext['weight'] != null) {
      contextParts.add('Current weight: ${userContext['weight']} kg');
    }

    if (userContext['goal'] != null) {
      contextParts.add('Fitness goal: ${userContext['goal']}');
    }

    if (userContext['activityLevel'] != null) {
      contextParts.add('Activity level: ${userContext['activityLevel']}');
    }

    if (userContext['currentStreak'] != null) {
      contextParts.add('Current streak: ${userContext['currentStreak']} days');
    }

    if (userContext['todayCalories'] != null) {
      contextParts.add('Today\'s calories: ${userContext['todayCalories']}');
    }

    if (userContext['todayProtein'] != null) {
      contextParts.add('Today\'s protein: ${userContext['todayProtein']}g');
    }

    if (userContext['calorieGoal'] != null) {
      contextParts.add('Daily calorie goal: ${userContext['calorieGoal']}');
    }

    if (userContext['proteinGoal'] != null) {
      contextParts.add('Daily protein goal: ${userContext['proteinGoal']}g');
    }

    if (contextParts.isNotEmpty) {
      return 'User context:\n${contextParts.join('\n')}';
    }

    return '';
  }

  // Enhanced method for context-aware agent conversations
  Future<String> sendAgentMessage({
    required String userMessage,
    required UserProfile userProfile,
    required ConversationContext context,
    List<Map<String, String>>? conversationHistory,
    AgentQuestion? currentQuestion,
  }) async {
    // Build context-aware system prompt
    final agentSystemPrompt = _buildAgentSystemPrompt(userProfile, context, currentQuestion);
    
    // Build enhanced user context
    final enhancedContext = _buildEnhancedContext(userProfile, context);
    
    return await sendMessage(
      userMessage: userMessage,
      conversationHistory: conversationHistory,
      userContext: enhancedContext,
      personalizedSystemPrompt: agentSystemPrompt,
    );
  }

  // Build agent-specific system prompt with context
  String _buildAgentSystemPrompt(UserProfile userProfile, ConversationContext context, AgentQuestion? currentQuestion) {
    final basePrompt = _systemPrompt;
    
    // Add conversation stage awareness
    String stageContext = '';
    switch (context.conversationStage) {
      case 'getting_to_know':
        stageContext = '''
CONVERSATION STAGE: Getting to know the user
- Ask thoughtful questions to understand their needs
- Be encouraging and supportive as they share
- Focus on building rapport and understanding their situation''';
        break;
      case 'established':
        stageContext = '''
CONVERSATION STAGE: Established relationship
- User has shared some information about themselves
- Provide more targeted advice based on what you know
- Can reference previous conversations naturally''';
        break;
      case 'expert':
        stageContext = '''
CONVERSATION STAGE: Expert coaching mode
- User trusts you and has shared detailed information
- Provide advanced, highly personalized recommendations
- Can challenge them appropriately and suggest complex strategies''';
        break;
    }

    // Add current question context if agent is asking a question
    String questionContext = '';
    if (currentQuestion != null) {
      questionContext = '''
CURRENT AGENT QUESTION: "${currentQuestion.question}"
- Type: ${currentQuestion.type}
- Can be skipped: ${currentQuestion.canBeSkipped}
${currentQuestion.skipReason != null ? "- Skip reason: ${currentQuestion.skipReason}" : ""}
- If user wants to skip, be understanding and redirect to their interests''';
    }

    // Add user preferences and patterns
    String preferencesContext = '';
    if (context.userPreferences.isNotEmpty) {
      preferencesContext = '''
USER PREFERENCES LEARNED:
${context.userPreferences.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}''';
    }

    // Add identified gaps
    String gapsContext = '';
    if (context.identifiedGaps.isNotEmpty) {
      gapsContext = '''
AREAS NEEDING MORE INFO:
${context.identifiedGaps.map((gap) => '- $gap').join('\n')}''';
    }

    return '''$basePrompt

$stageContext

USER PROFILE SUMMARY:
- Name: ${userProfile.name}
- Goal: ${userProfile.fitnessGoal ?? 'Not specified'}
- Experience: ${userProfile.experienceLevel ?? 'Not specified'}
- Activity Level: ${userProfile.activityLevel ?? 'Not specified'}
- Age: ${userProfile.age ?? 'Not specified'}
${userProfile.weight != null ? '- Current Weight: ${userProfile.weight}kg' : ''}
${userProfile.targetWeight != null ? '- Target Weight: ${userProfile.targetWeight}kg' : ''}

$preferencesContext

$gapsContext

$questionContext

CONVERSATION HISTORY SUMMARY:
- Questions asked: ${context.askedQuestions.length}
- Recent topics: ${context.recentTopics.take(3).join(', ')}
- Last interaction: ${_formatDaysAgo(context.lastInteraction)}

AGENT BEHAVIOR GUIDELINES:
1. Be conversational and natural, not robotic
2. Reference previous conversations when relevant
3. If user skips questions, be understanding: "No problem! Let's focus on what you want to know."
4. Provide actionable, specific advice based on their profile
5. Ask follow-up questions naturally within your responses
6. Keep responses focused and avoid overwhelming with information
7. Celebrate their progress and acknowledge challenges
8. Always give users control - they can skip anything or change topics anytime''';
  }

  // Build enhanced context with conversation history
  Map<String, dynamic> _buildEnhancedContext(UserProfile userProfile, ConversationContext context) {
    final enhancedContext = <String, dynamic>{
      'name': userProfile.name,
      'age': userProfile.age,
      'height': userProfile.height,
      'weight': userProfile.weight,
      'targetWeight': userProfile.targetWeight,
      'goal': userProfile.fitnessGoal,
      'activityLevel': userProfile.activityLevel,
      'experienceLevel': userProfile.experienceLevel,
      'workoutConsistency': userProfile.workoutConsistency,
    };

    // Add conversation-specific context
    enhancedContext.addAll({
      'conversationStage': context.conversationStage,
      'questionsAsked': context.askedQuestions.length,
      'recentTopics': context.recentTopics,
      'userResponses': context.userResponses,
      'preferences': context.userPreferences,
    });

    return enhancedContext;
  }

  String _formatDaysAgo(DateTime lastInteraction) {
    final now = DateTime.now();
    final difference = now.difference(lastInteraction);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Just now';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Provide helpful fallback responses for common queries
    if (lowerMessage.contains('diet') || lowerMessage.contains('nutrition')) {
      return '''Great question about nutrition! Here are some general tips:

• Focus on whole, unprocessed foods
• Aim for balanced meals with protein, carbs, and healthy fats
• Stay hydrated with 8-10 glasses of water daily
• Eat plenty of vegetables and fruits
• Listen to your body's hunger and fullness cues

For personalized advice, make sure the AI coach is properly configured!''';
    }

    if (lowerMessage.contains('exercise') || lowerMessage.contains('workout')) {
      return '''Here's a balanced workout approach:

• Strength training: 3-4 times per week
• Cardio: 150 minutes moderate or 75 minutes vigorous weekly
• Include both compound and isolation exercises
• Allow for rest and recovery days
• Progress gradually to avoid injury

Remember to warm up before and cool down after workouts!''';
    }

    if (lowerMessage.contains('weight loss') || lowerMessage.contains('lose weight')) {
      return '''For healthy weight loss:

• Create a moderate calorie deficit (500-750 calories/day)
• Focus on nutrient-dense foods
• Combine cardio and strength training
• Aim for 0.5-1 kg loss per week
• Be patient and consistent
• Track your progress

Remember, sustainable changes beat quick fixes!''';
    }

    if (lowerMessage.contains('muscle') || lowerMessage.contains('gain')) {
      return '''To build muscle effectively:

• Eat adequate protein (1.6-2.2g per kg body weight)
• Progressive overload in training
• Focus on compound movements
• Get 7-9 hours of quality sleep
• Allow muscles time to recover
• Stay consistent with your routine

Building muscle takes time - trust the process!''';
    }

    if (lowerMessage.contains('motivat') || lowerMessage.contains('stuck')) {
      return '''I understand fitness journeys have ups and downs! Remember:

• Progress isn't always linear
• Small consistent actions lead to big results
• Focus on how you feel, not just numbers
• Celebrate non-scale victories
• Find activities you enjoy
• You're stronger than you think!

Every day is a new opportunity. Keep going! 💪''';
    }

    // Generic fallback
    return '''I'm here to help with your fitness journey! While I'm having trouble connecting to my full capabilities right now, I can still offer general advice.

What specific area would you like help with?
• Nutrition and diet
• Exercise and workouts
• Weight management
• Building healthy habits
• Staying motivated

Feel free to ask me anything fitness-related!''';
  }
}