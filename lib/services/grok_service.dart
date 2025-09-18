import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

class GrokService {
  static const String _baseUrl = ApiConfig.grokApiUrl;
  static const String _apiKey = ApiConfig.grokApiKey;
  
  // Concise system prompt for ChatGPT-style responses
  static const String _systemPrompt = '''
You are Streaker AI, a fitness coach providing concise, well-structured responses.

**RESPONSE FORMAT (STRICT):**
- Start with a brief title/heading
- Use bullet points for key information
- Keep responses under 150 words
- Include 2-3 actionable suggestions at the end
- Use emojis sparingly (💪 🎯 ✅)

**YOUR EXPERTISE:**
Workouts, nutrition, recovery, habit formation, motivation

**COMMUNICATION RULES:**
1. Be concise and scannable
2. Focus on immediate actionable advice
3. Use proper markdown formatting:
   - # for main titles
   - ## for subheadings
   - • for bullet points
   - **bold** for emphasis
4. End with "What would you like to focus on next?"

**SAFETY:** Always recommend consulting professionals for injuries or medical concerns.''';

  static final GrokService _instance = GrokService._internal();
  factory GrokService() => _instance;
  GrokService._internal();

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? userContext,
    String? personalizedSystemPrompt,
  }) async {
    print('🤖 GROK API: Starting API call for message: "${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}..."');

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

      print('🤖 GROK API: Making request to $_baseUrl');
      print('🤖 GROK API: Message count: ${messages.length}');

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

      print('🤖 GROK API: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('🤖 GROK API: SUCCESS - Received AI response: "${content.substring(0, content.length > 100 ? 100 : content.length)}..."');
        return content.trim();
      } else if (response.statusCode == 401) {
        print('🤖 GROK API: AUTH ERROR - Invalid API key');
        return 'API key not configured. Please add your GROK API key to use the AI coach feature.';
      } else if (response.statusCode == 429) {
        print('🤖 GROK API: RATE LIMIT - Too many requests');
        return 'I\'m a bit overwhelmed right now. Please try again in a moment! 😊';
      } else {
        print('🤖 GROK API ERROR: ${response.statusCode} - ${response.body}');
        print('🤖 GROK API: Using fallback response due to API error');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('🤖 GROK API EXCEPTION: $e');
      print('🤖 GROK API: Using fallback response due to exception');
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


  String _getFallbackResponse(String userMessage) {
    print('🤖 GROK API: Generating FALLBACK response for: "$userMessage"');
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