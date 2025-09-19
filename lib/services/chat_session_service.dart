import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_session.dart';
import '../config/api_config.dart';
import 'grok_service.dart';

class ChatSessionService {
  static final ChatSessionService _instance = ChatSessionService._internal();
  factory ChatSessionService() => _instance;
  ChatSessionService._internal();

  final _supabase = Supabase.instance.client;
  final _grokService = GrokService();

  ChatSession? _currentSession;
  List<ChatMessage> _currentMessages = [];
  DateTime? _sessionStartTime;

  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get currentMessages => _currentMessages;

  // Start a new chat session
  Future<ChatSession> startNewSession(String userId) async {
    try {
      _sessionStartTime = DateTime.now();
      _currentMessages = [];

      // Get session number for today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final sessionNumber = await _getNextSessionNumber(userId, today);

      // Create new session in database with placeholder summary
      final response = await _supabase
          .from('chat_sessions')
          .insert({
            'user_id': userId,
            'session_date': today,
            'session_number': sessionNumber,
            'session_title': 'New Chat Session',
            'session_summary': 'Session in progress...',
            'topics_discussed': [],
            'message_count': 0,
            'started_at': _sessionStartTime!.toIso8601String(),
          })
          .select()
          .single();

      _currentSession = ChatSession.fromJson(response);
      return _currentSession!;
    } catch (e) {
      print('Error starting new session: $e');
      throw Exception('Failed to start new session');
    }
  }

  // Add message to current session (local only, not stored in DB)
  void addMessage(ChatMessage message) {
    _currentMessages.add(message);
  }

  // End current session and generate summary
  Future<void> endSession() async {
    if (_currentSession == null || _currentMessages.isEmpty) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime ?? endTime).inMinutes;

      // Generate session summary using Grok
      final summary = await _generateSessionSummary();

      // Extract topics and recommendations
      final analysisResult = await _analyzeSession();

      // Update session in database with summary
      await _supabase
          .from('chat_sessions')
          .update({
            'session_summary': summary['summary'],
            'session_title': summary['title'],
            'topics_discussed': analysisResult['topics'],
            'user_goals_discussed': analysisResult['goals'],
            'recommendations_given': analysisResult['recommendations'],
            'user_sentiment': analysisResult['sentiment'],
            'message_count': _currentMessages.length,
            'duration_minutes': duration,
            'ended_at': endTime.toIso8601String(),
            'updated_at': endTime.toIso8601String(),
          })
          .eq('id', _currentSession!.id);

      // Clear current session
      _currentSession = null;
      _currentMessages = [];
      _sessionStartTime = null;
    } catch (e) {
      print('Error ending session: $e');
      throw Exception('Failed to end session');
    }
  }

  // Generate a one-liner summary of the session
  Future<Map<String, String>> _generateSessionSummary() async {
    if (_currentMessages.isEmpty) {
      return {
        'summary': 'Brief chat session with no specific topics discussed.',
        'title': 'Quick Chat'
      };
    }

    // Build conversation text
    final conversationText = _currentMessages
        .map((msg) => '${msg.isUser ? "User" : "AI"}: ${msg.message}')
        .join('\n');

    // Use Grok to generate summary
    final summaryPrompt = '''
Based on the following fitness coaching conversation, provide a concise analysis in JSON format:
{
  "summary": "One-liner summary of what was discussed (max 100 characters)",
  "title": "Short title for the session (max 30 characters)"
}

Conversation:
$conversationText

Respond ONLY with the JSON object, no additional text.''';

    try {
      final response = await _grokService.sendMessage(
        userMessage: summaryPrompt,
        personalizedSystemPrompt: 'You are a conversation analyzer. Provide only JSON responses as requested.',
      );

      // Parse JSON response
      final jsonResponse = jsonDecode(response);
      return {
        'summary': jsonResponse['summary'] ?? 'General fitness discussion',
        'title': jsonResponse['title'] ?? 'Chat Session'
      };
    } catch (e) {
      print('Error generating summary: $e');
      return {
        'summary': 'Fitness coaching session',
        'title': 'Chat Session'
      };
    }
  }

  // Analyze session for topics, goals, recommendations
  Future<Map<String, dynamic>> _analyzeSession() async {
    if (_currentMessages.isEmpty) {
      return {
        'topics': [],
        'goals': null,
        'recommendations': null,
        'sentiment': 'neutral'
      };
    }

    // Build conversation text
    final conversationText = _currentMessages
        .map((msg) => '${msg.isUser ? "User" : "AI"}: ${msg.message}')
        .join('\n');

    // Use Grok to analyze the session
    final analysisPrompt = '''
Analyze this fitness coaching conversation and provide a JSON response with:
{
  "topics": ["topic1", "topic2", "topic3"],  // Main topics discussed (max 5)
  "goals": "Any specific goals mentioned by the user (or null)",
  "recommendations": "Key recommendations given (or null)",
  "sentiment": "positive|neutral|negative|mixed"  // User's overall sentiment
}

Conversation:
$conversationText

Respond ONLY with the JSON object.''';

    try {
      final response = await _grokService.sendMessage(
        userMessage: analysisPrompt,
        personalizedSystemPrompt: 'You are a conversation analyzer. Provide only JSON responses as requested.',
      );

      // Parse JSON response
      final jsonResponse = jsonDecode(response);
      return {
        'topics': List<String>.from(jsonResponse['topics'] ?? []),
        'goals': jsonResponse['goals'],
        'recommendations': jsonResponse['recommendations'],
        'sentiment': jsonResponse['sentiment'] ?? 'neutral'
      };
    } catch (e) {
      print('Error analyzing session: $e');
      return {
        'topics': ['fitness', 'health'],
        'goals': null,
        'recommendations': null,
        'sentiment': 'neutral'
      };
    }
  }

  // Get user's chat history (summaries only)
  Future<List<ChatSession>> getUserChatHistory(String userId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('session_date', ascending: false)
          .order('session_number', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  // Get user's recent context for AI
  Future<String> getUserContext(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_user_chat_context', params: {'p_user_id': userId});

      if (response == null || (response as List).isEmpty) {
        return '';
      }

      // Build context string from recent sessions
      final sessions = response as List;
      final contextParts = <String>[];

      for (final session in sessions) {
        final date = session['session_date'];
        final summary = session['session_summary'];
        final topics = (session['topics_discussed'] as List?)?.join(', ') ?? '';

        contextParts.add('[$date] $summary${topics.isNotEmpty ? " (Topics: $topics)" : ""}');
      }

      return 'Recent conversation context:\n${contextParts.join('\n')}';
    } catch (e) {
      print('Error getting user context: $e');
      return '';
    }
  }

  // Search chat history
  Future<List<ChatSession>> searchChatHistory(String userId, String query) async {
    try {
      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .or('session_summary.ilike.%$query%,session_title.ilike.%$query%')
          .order('session_date', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => ChatSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching chat history: $e');
      return [];
    }
  }

  // Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase
          .from('chat_sessions')
          .delete()
          .eq('id', sessionId);
    } catch (e) {
      print('Error deleting session: $e');
      throw Exception('Failed to delete session');
    }
  }

  // Get next session number for a date
  Future<int> _getNextSessionNumber(String userId, String date) async {
    try {
      final response = await _supabase
          .rpc('get_next_session_number', params: {
            'p_user_id': userId,
            'p_date': date,
          });

      return response as int? ?? 1;
    } catch (e) {
      print('Error getting next session number: $e');
      return 1;
    }
  }

  // Clear all local data
  void clearLocalData() {
    _currentSession = null;
    _currentMessages = [];
    _sessionStartTime = null;
  }

  // Check if there's an active session
  bool get hasActiveSession => _currentSession != null;

  // Get session duration
  Duration? get sessionDuration {
    if (_sessionStartTime == null) return null;
    return DateTime.now().difference(_sessionStartTime!);
  }
}

// Chat Message Model (for local storage during session)
class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    message: json['message'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}