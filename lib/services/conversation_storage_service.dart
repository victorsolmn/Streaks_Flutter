import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_context.dart';

class ConversationStorageService {
  static final ConversationStorageService _instance = ConversationStorageService._internal();
  factory ConversationStorageService() => _instance;
  ConversationStorageService._internal();

  static const String _contextKey = 'conversation_context';

  // Save conversation context locally (for now, can be extended to Supabase later)
  Future<void> saveContext(ConversationContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = jsonEncode(context.toJson());
      await prefs.setString('${_contextKey}_${context.userId}', contextJson);
    } catch (e) {
      print('Error saving conversation context: $e');
    }
  }

  // Load conversation context
  Future<ConversationContext?> loadContext(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString('${_contextKey}_$userId');
      
      if (contextJson != null) {
        final contextData = jsonDecode(contextJson);
        return ConversationContext.fromJson(contextData);
      }
    } catch (e) {
      print('Error loading conversation context: $e');
    }
    
    return null;
  }

  // Clear conversation context (for reset/logout)
  Future<void> clearContext(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_contextKey}_$userId');
    } catch (e) {
      print('Error clearing conversation context: $e');
    }
  }

  // Get conversation summary for display
  Future<Map<String, dynamic>?> getConversationSummary(String userId) async {
    final context = await loadContext(userId);
    if (context == null) return null;

    return {
      'questionsAsked': context.askedQuestions.length,
      'stage': context.conversationStage,
      'lastInteraction': context.lastInteraction.toIso8601String(),
      'recentTopics': context.recentTopics.take(3).toList(),
      'responseCount': context.userResponses.length,
    };
  }

  // TODO: Future Supabase integration methods
  /*
  Future<void> syncContextToSupabase(ConversationContext context) async {
    // Implementation for syncing to Supabase
    // This will be added when Supabase conversation_context table is created
  }

  Future<ConversationContext?> loadContextFromSupabase(String userId) async {
    // Implementation for loading from Supabase
    return null;
  }
  */
}