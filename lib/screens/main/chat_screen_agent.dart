import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/health_provider.dart';
import '../../services/grok_service.dart';
import '../../services/agent_service.dart';
import '../../services/conversation_storage_service.dart';
import '../../models/conversation_context.dart';
import '../../utils/app_theme.dart';

class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final AgentQuestion? question; // If this is an agent question
  final bool canBeSkipped;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.question,
    this.canBeSkipped = false,
  });
}

class ChatScreenAgent extends StatefulWidget {
  const ChatScreenAgent({Key? key}) : super(key: key);

  @override
  State<ChatScreenAgent> createState() => _ChatScreenAgentState();
}

class _ChatScreenAgentState extends State<ChatScreenAgent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GrokService _grokService = GrokService();
  final AgentService _agentService = AgentService();
  final ConversationStorageService _storageService = ConversationStorageService();
  
  bool _isTyping = false;
  ConversationContext? _conversationContext;
  AgentQuestion? _currentQuestion;
  bool _agentMode = true; // Start in agent mode

  @override
  void initState() {
    super.initState();
    _initializeAgentChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAgentChat() async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    
    // Initialize conversation context
    if (userProvider.userProfile != null) {
      // Try to load existing conversation context
      _conversationContext = await _storageService.loadContext(userProvider.userProfile!.email);
      
      // If no existing context, create new one
      if (_conversationContext == null) {
        _conversationContext = ConversationContext.empty(userProvider.userProfile!.email);
        
        // Generate agent introduction for new users
        final introMessage = _agentService.generateIntroMessage(userProvider.userProfile!);
        
        final welcomeMessage = ChatMessage(
          id: 'agent_intro_${DateTime.now().millisecondsSinceEpoch}',
          message: introMessage,
          isUser: false,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _messages.add(welcomeMessage);
        });

        // Save the initial context
        await _storageService.saveContext(_conversationContext!);
      } else {
        // Returning user - show a brief welcome back message
        final welcomeBackMessage = ChatMessage(
          id: 'welcome_back_${DateTime.now().millisecondsSinceEpoch}',
          message: "Welcome back! I remember our previous conversations. What would you like to work on today? 💪",
          isUser: false,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _messages.add(welcomeBackMessage);
        });
      }

      // After a brief pause, ask if agent should ask questions or wait
      Future.delayed(const Duration(milliseconds: 1500), () {
        _checkIfShouldAskQuestion();
      });
    }
  }

  void _checkIfShouldAskQuestion() async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    
    if (userProvider.userProfile != null && _conversationContext != null) {
      final shouldAsk = _agentService.shouldProactivelyAsk(
        context: _conversationContext!,
        userProfile: userProvider.userProfile!,
      );

      if (shouldAsk) {
        final questions = _agentService.generateQuestions(
          userProfile: userProvider.userProfile!,
          context: _conversationContext!,
          maxQuestions: 1,
        );

        if (questions.isNotEmpty) {
          _askAgentQuestion(questions.first);
        }
      }
    }
  }

  void _askAgentQuestion(AgentQuestion question) {
    final questionMessage = ChatMessage(
      id: 'agent_question_${DateTime.now().millisecondsSinceEpoch}',
      message: question.question,
      isUser: false,
      timestamp: DateTime.now(),
      question: question,
      canBeSkipped: question.canBeSkipped,
    );

    setState(() {
      _messages.add(questionMessage);
      _currentQuestion = question;
    });

    _scrollToBottom();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Add user message to chat
    final userChatMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      message: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userChatMessage);
      _isTyping = true;
    });

    _scrollToBottom();

    // Process the message with agent context
    await _processMessageWithAgent(userMessage);
  }

  Future<void> _processMessageWithAgent(String userMessage) async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    
    if (userProvider.userProfile == null) {
      setState(() {
        _isTyping = false;
      });
      return;
    }

    try {
      // Update conversation context with user response
      if (_currentQuestion != null) {
        _conversationContext = _conversationContext!.addInteraction(
          topic: _currentQuestion!.type.toString(),
          questionKey: _currentQuestion!.id,
          response: userMessage,
        );
      } else {
        _conversationContext = _conversationContext!.addInteraction(
          response: userMessage,
        );
      }

      // Save updated context
      await _storageService.saveContext(_conversationContext!);

      // Build conversation history for context
      final conversationHistory = _buildConversationHistory();

      // Get AI response using enhanced agent method
      final aiResponse = await _grokService.sendAgentMessage(
        userMessage: userMessage,
        userProfile: userProvider.userProfile!,
        context: _conversationContext!,
        conversationHistory: conversationHistory,
        currentQuestion: _currentQuestion,
      );

      // Add AI response to chat
      final aiChatMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiChatMessage);
        _isTyping = false;
        _currentQuestion = null; // Clear current question after response
      });

      _scrollToBottom();

      // Generate follow-up question if appropriate
      _considerFollowUpQuestion(userMessage);

    } catch (e) {
      print('Error in agent conversation: $e');
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _considerFollowUpQuestion(String userMessage) async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    
    if (userProvider.userProfile == null || _conversationContext == null) return;

    // Wait a bit before asking follow-up
    await Future.delayed(const Duration(milliseconds: 2000));

    // Generate follow-up question if there was a previous question
    if (_currentQuestion != null) {
      final followUp = _agentService.generateFollowUpQuestion(
        originalQuestion: _currentQuestion!,
        userResponse: userMessage,
        userProfile: userProvider.userProfile!,
        context: _conversationContext!,
      );

      if (followUp != null) {
        _askAgentQuestion(followUp);
      }
    }

    // Or ask a new question if agent thinks it's appropriate
    else {
      final questions = _agentService.generateQuestions(
        userProfile: userProvider.userProfile!,
        context: _conversationContext!,
        maxQuestions: 1,
      );

      if (questions.isNotEmpty) {
        // Wait a bit more before asking a new question
        await Future.delayed(const Duration(milliseconds: 3000));
        _askAgentQuestion(questions.first);
      }
    }
  }

  void _skipCurrentQuestion() {
    if (_currentQuestion == null) return;

    final skipResponse = _agentService.generateSkipResponse(_currentQuestion!);
    
    final skipMessage = ChatMessage(
      id: 'agent_skip_${DateTime.now().millisecondsSinceEpoch}',
      message: skipResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(skipMessage);
      _currentQuestion = null;
    });

    _scrollToBottom();
  }

  void _toggleAgentMode() {
    setState(() {
      _agentMode = !_agentMode;
      _currentQuestion = null;
    });

    final modeMessage = ChatMessage(
      id: 'mode_change_${DateTime.now().millisecondsSinceEpoch}',
      message: _agentMode 
        ? "I'm back in coach mode! I'll ask thoughtful questions to help you better. Feel free to skip any you don't want to answer."
        : "No problem! I'm in free-chat mode now. Ask me anything about fitness and I'll help without asking questions back.",
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(modeMessage);
    });

    _scrollToBottom();
  }

  List<Map<String, String>> _buildConversationHistory() {
    // Get last 6 messages for context (3 exchanges)
    final recentMessages = _messages
        .where((msg) => !msg.message.contains("I'm back in coach mode") && 
                       !msg.message.contains("No problem! I'm in free-chat mode"))
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed;

    return recentMessages.map((msg) => {
      'role': msg.isUser ? 'user' : 'assistant',
      'content': msg.message,
    }).toList();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primaryAccent,
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streaker AI Coach',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _agentMode ? 'Smart Question Mode' : 'Free Chat Mode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_agentMode ? Icons.chat : Icons.quiz),
            tooltip: _agentMode ? 'Switch to Free Chat' : 'Switch to Coach Mode',
            onPressed: _toggleAgentMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Skip button for current question
          if (_currentQuestion?.canBeSkipped == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: _skipCurrentQuestion,
                icon: const Icon(Icons.skip_next),
                label: Text('Skip this question'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryAccent,
                  side: BorderSide(color: AppTheme.primaryAccent),
                ),
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _agentMode 
                        ? 'Answer the question or ask me anything...'
                        : 'Ask me anything about fitness...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  backgroundColor: AppTheme.primaryAccent,
                  mini: true,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primaryAccent,
              ),
              child: const Icon(
                Icons.psychology,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryAccent : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (message.canBeSkipped && !isUser) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 You can skip this question anytime',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[300],
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.primaryAccent,
            ),
            child: const Icon(
              Icons.psychology,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}