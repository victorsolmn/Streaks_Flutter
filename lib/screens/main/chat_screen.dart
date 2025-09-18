import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/health_provider.dart';
import '../../services/grok_service.dart';
import '../../services/chat_session_service.dart';
import '../../services/user_context_builder.dart';
import '../../models/chat_session.dart';
import '../../utils/app_theme.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatSessionService _sessionService = ChatSessionService();
  final GrokService _grokService = GrokService();

  bool _isTyping = false;
  bool _showWelcomeScreen = true;
  bool _showHistoryPanel = false;
  List<ChatSession> _chatHistory = [];
  List<ChatMessage> _messages = []; // Local state for messages
  Timer? _sessionTimer;
  List<String> _currentSuggestions = [];

  // Animation controllers
  late AnimationController _historyAnimationController;
  late Animation<double> _historyAnimation;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupAnimations();
    _startSessionTimer();
  }

  void _setupAnimations() {
    _historyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _historyAnimation = CurvedAnimation(
      parent: _historyAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _startSessionTimer() {
    // Auto-save session every 5 minutes if active
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_sessionService.hasActiveSession && _sessionService.currentMessages.isNotEmpty) {
        _autoSaveSession();
      }
    });
  }

  Future<void> _autoSaveSession() async {
    // This is a placeholder for auto-save functionality
    // In production, you might want to save drafts or partial sessions
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _historyAnimationController.dispose();
    _sessionTimer?.cancel();

    // End session if still active
    if (_sessionService.hasActiveSession) {
      _sessionService.endSession();
    }
    super.dispose();
  }

  void _initializeChat() async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    if (userProvider.userProfile != null) {
      await _loadChatHistory();
      // Sync messages from service if any exist
      if (mounted) {
        setState(() {
          _messages = List.from(_sessionService.currentMessages);
        });
      }
    }
  }

  Future<void> _loadChatHistory() async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;
    if (userId != null) {
      final history = await _sessionService.getUserChatHistory(userId);
      if (mounted) {
        setState(() {
          _chatHistory = history;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleHistoryPanel() {
    if (!mounted) return;
    setState(() {
      _showHistoryPanel = !_showHistoryPanel;
      if (_showHistoryPanel) {
        _historyAnimationController.forward();
        _loadChatHistory(); // Refresh history when opened
      } else {
        _historyAnimationController.reverse();
      }
    });
  }

  Future<void> _startNewChat() async {
    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;
    if (userId == null) return;

    // End current session if exists
    if (_sessionService.hasActiveSession) {
      await _sessionService.endSession();
    }

    // Start new session
    await _sessionService.startNewSession(userId);

    if (mounted) {
      setState(() {
        _showWelcomeScreen = false;
        _showHistoryPanel = false;
        _messages = []; // Clear messages for new session
      });
    }
  }

  Future<void> _sendMessage([String? presetMessage]) async {
    final messageText = presetMessage ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;
    if (userId == null) return;

    // Start session if not already started
    if (!_sessionService.hasActiveSession) {
      await _sessionService.startNewSession(userId);
    }

    // Hide welcome screen when first message is sent
    if (_showWelcomeScreen && mounted) {
      setState(() {
        _showWelcomeScreen = false;
      });
    }

    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      message: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _sessionService.addMessage(userMessage);

    if (mounted) {
      setState(() {
        _messages.add(userMessage); // Update local state
        _isTyping = true;
        _currentSuggestions.clear(); // Clear suggestions when user sends message
      });
    }

    _messageController.clear();
    _scrollToBottom();

    // Generate AI response
    final aiResponse = await _generateAIResponse(messageText);

    final aiMessage = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      message: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );

    _sessionService.addMessage(aiMessage);

    if (mounted) {
      setState(() {
        _messages.add(aiMessage); // Update local state
        _isTyping = false;
        _currentSuggestions = _generateSuggestions(aiResponse); // Generate suggestions
      });
    }

    _scrollToBottom();
  }

  Future<String> _generateAIResponse(String userMessage) async {
    try {
      final userProvider = Provider.of<SupabaseUserProvider>(context, listen: false);

      // Build comprehensive user context
      final comprehensiveContext = UserContextBuilder.buildComprehensiveContext(context);

      // Get recent chat context from database
      String recentContext = '';
      final userId = userProvider.currentUser?.id;
      if (userId != null) {
        try {
          recentContext = await _sessionService.getUserContext(userId);
        } catch (e) {
          print('Warning: Could not load user context: $e');
          // Continue without context rather than failing
        }
      }

      // Generate personalized system prompt with recent context
      final personalizedPrompt = '''
${UserContextBuilder.generatePersonalizedSystemPrompt(comprehensiveContext)}

$recentContext
''';

      // Build conversation history from current session
      final conversationHistory = <Map<String, String>>[];
      // Use local messages instead of service messages for history
      final startIndex = _messages.length > 10 ? _messages.length - 10 : 0;

      for (int i = startIndex; i < _messages.length; i++) {
        final msg = _messages[i];
        conversationHistory.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.message,
        });
      }

      // Call GROK API with personalized context
      final response = await _grokService.sendMessage(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
        personalizedSystemPrompt: personalizedPrompt,
      );

      return response;
    } catch (e) {
      print('Error generating AI response: $e');
      // Return a helpful fallback message instead of crashing
      return "I'm having trouble connecting right now, but I'm still here to help! Feel free to ask me about nutrition, workouts, or any fitness questions. I'll do my best to assist you! 💪\n\nError: ${e.toString().split('\n').first}";
    }
  }

  List<String> _generateSuggestions(String aiResponse) {
    final suggestions = <String>[];
    final lowercaseResponse = aiResponse.toLowerCase();

    // Generate contextual suggestions based on AI response content
    if (lowercaseResponse.contains('workout') || lowercaseResponse.contains('exercise')) {
      suggestions.addAll([
        'Can you create a detailed workout plan?',
        'How do I track my workout progress?',
        'What exercises are best for beginners?',
      ]);
    } else if (lowercaseResponse.contains('nutrition') || lowercaseResponse.contains('diet')) {
      suggestions.addAll([
        'Help me plan my meals for the week',
        'What are good protein sources?',
        'How do I calculate my daily calories?',
      ]);
    } else if (lowercaseResponse.contains('weight') || lowercaseResponse.contains('loss') || lowercaseResponse.contains('gain')) {
      suggestions.addAll([
        'How fast is healthy weight loss?',
        'What should I eat to gain muscle?',
        'How do I track my progress?',
      ]);
    } else {
      // Default suggestions
      suggestions.addAll([
        'Create a workout plan for today',
        'Give me nutrition advice',
        'Help me stay motivated',
      ]);
    }

    // Limit to 3 suggestions and shuffle for variety
    suggestions.shuffle();
    return suggestions.take(3).toList();
  }

  Future<void> _endCurrentSession() async {
    if (!_sessionService.hasActiveSession) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
        ),
      ),
    );

    try {
      await _sessionService.endSession();
      await _loadChatHistory();

      if (mounted) {
        Navigator.pop(context); // Remove loading indicator
        setState(() {
          _showWelcomeScreen = true;
          _messages = []; // Clear messages after saving
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat session saved successfully!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save session: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildWelcomeScreen() {
    final userProvider = Provider.of<SupabaseUserProvider>(context);
    final profile = userProvider.userProfile;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String userName = 'there';
    if (profile?.name != null && profile!.name.trim().isNotEmpty) {
      final fullName = profile.name.trim();
      userName = fullName.split(' ').first;
      if (userName.isNotEmpty) {
        userName = userName[0].toUpperCase() + userName.substring(1).toLowerCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [AppTheme.darkBackground, AppTheme.darkCardBackground]
              : [AppTheme.backgroundLight, AppTheme.cardBackgroundLight],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar with History Button
            _buildAppBar(isDarkMode),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Greeting
                    Text(
                      'Hi, $userName! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to crush your fitness goals?',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick prompts
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildQuickPromptChip(
                          icon: Icons.fitness_center,
                          label: 'Workout Plan',
                          onTap: () => _sendMessage('Create a workout plan for today based on my goals'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.restaurant_menu,
                          label: 'Meal Ideas',
                          onTap: () => _sendMessage('Suggest healthy meal ideas for my goals'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.trending_up,
                          label: 'Progress Check',
                          onTap: () => _sendMessage('Analyze my recent progress and provide insights'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.psychology,
                          label: 'Motivation',
                          onTap: () => _sendMessage('I need some motivation to stay on track'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Popular topics
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Topics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTopicCard(
                                    icon: Icons.fitness_center,
                                    title: 'Strength Training',
                                    description: 'Build muscle and power',
                                    gradient: AppTheme.primaryGradient,
                                    onTap: () => _sendMessage('Tell me about effective strength training techniques'),
                                  ),
                                  _buildTopicCard(
                                    icon: Icons.directions_run,
                                    title: 'Cardio & Endurance',
                                    description: 'Boost your stamina',
                                    gradient: AppTheme.secondaryGradient,
                                    onTap: () => _sendMessage('How can I improve my cardio endurance?'),
                                  ),
                                  _buildTopicCard(
                                    icon: Icons.restaurant,
                                    title: 'Nutrition Tips',
                                    description: 'Fuel your body right',
                                    gradient: AppTheme.accentGradient,
                                    onTap: () => _sendMessage('What nutrition tips do you have for my goals?'),
                                  ),
                                  _buildTopicCard(
                                    icon: Icons.bedtime,
                                    title: 'Recovery',
                                    description: 'Rest and restore',
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                    onTap: () => _sendMessage('How important is recovery and how can I optimize it?'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Input area
            _buildInputArea(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildChatScreen() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use local state messages instead of service messages

    return Container(
      color: isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(isDarkMode),

            // Messages area
            Expanded(
              child: _messages.isEmpty && !_isTyping
                ? Center(
                    child: Text(
                      'Start a conversation...',
                      style: TextStyle(
                        color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0) + (_currentSuggestions.isNotEmpty && !_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }

                      if (index == _messages.length + (_isTyping ? 1 : 0) && _currentSuggestions.isNotEmpty && !_isTyping) {
                        return _buildSuggestions();
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
            ),

            // Session info bar
            if (_sessionService.hasActiveSession)
              _buildSessionInfoBar(isDarkMode),

            // Input area
            _buildInputArea(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              'assets/images/streaker_logo.svg',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streaker AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _sessionService.hasActiveSession
                      ? 'Session ${_sessionService.currentSession?.sessionNumber ?? 1} • ${_messages.length} messages'
                      : 'Your fitness assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // History button
          IconButton(
            icon: Icon(
              _showHistoryPanel ? Icons.close : Icons.history,
              color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
            ),
            onPressed: _toggleHistoryPanel,
            tooltip: 'Chat History',
          ),

          // End session button
          if (_sessionService.hasActiveSession)
            IconButton(
              icon: const Icon(Icons.save_alt, color: AppTheme.primaryAccent),
              onPressed: _endCurrentSession,
              tooltip: 'End & Save Session',
            ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoBar(bool isDarkMode) {
    final duration = _sessionService.sessionDuration;
    final durationText = duration != null
        ? '${duration.inMinutes} min ${duration.inSeconds % 60} sec'
        : '0 min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.darkCardBackground.withOpacity(0.5)
            : AppTheme.cardBackgroundLight.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Session Duration: $durationText',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save & End'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryAccent,
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: _endCurrentSession,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBackground : Theme.of(context).cardColor,
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
                hintText: 'Ask me anything about fitness...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? AppTheme.darkBackground
                    : Theme.of(context).scaffoldBackgroundColor,
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
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isTyping ? null : _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User/AI header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: isUser ? null : AppTheme.primaryGradient,
                    color: isUser ? Colors.grey[600] : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isUser ? Icons.person : Icons.psychology,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isUser ? 'You' : 'Streaker AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Message content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isUser
                ? Text(
                    message.message,
                    style: TextStyle(
                      color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  )
                : MarkdownBody(
                    data: message.message,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 15,
                      ),
                      strong: TextStyle(
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
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
              color: isDarkMode ? AppTheme.darkCardBackground : Theme.of(context).cardColor,
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
                    color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
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

  Widget _buildSuggestions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentSuggestions.map((suggestion) =>
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _sendMessage(suggestion);
                    setState(() {
                      _currentSuggestions.clear(); // Clear suggestions after use
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              )
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppTheme.darkCardBackground
                : AppTheme.cardBackgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _showWelcomeScreen && !_sessionService.hasActiveSession
              ? _buildWelcomeScreen()
              : _buildChatScreen(),

          // History panel overlay
          AnimatedBuilder(
            animation: _historyAnimation,
            builder: (context, child) {
              return _showHistoryPanel
                  ? Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Transform.translate(
                        offset: Offset(
                          MediaQuery.of(context).size.width * 0.85 * (1 - _historyAnimation.value),
                          0,
                        ),
                        child: _buildHistoryPanel(),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: AppTheme.primaryAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${_chatHistory.length} sessions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleHistoryPanel,
                  ),
                ],
              ),
            ),

            // History list
            Expanded(
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: isDarkMode
                                ? AppTheme.textSecondaryDark.withOpacity(0.3)
                                : AppTheme.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No chat history yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation to see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? AppTheme.textSecondaryDark.withOpacity(0.7)
                                  : AppTheme.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final session = _chatHistory[index];
                        return _buildHistoryItem(session);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ChatSession session) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show session details in a dialog
            _showSessionDetails(session);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkCardBackground : AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and sentiment
                Row(
                  children: [
                    Text(
                      session.relativeDateString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (session.userSentiment != null)
                      Text(
                        session.sentimentEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  session.sessionTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Summary
                Text(
                  session.sessionSummary,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Topics
                if (session.topicsDiscussed.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: session.topicsDiscussed.take(3).map((topic) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                    )).toList(),
                  ),

                // Stats
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 12,
                      color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session.messageCount} messages',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (session.durationText.isNotEmpty) ...[
                      Icon(
                        Icons.timer,
                        size: 12,
                        color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.durationText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(ChatSession session) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.sessionTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.formattedDate} at ${session.formattedTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: () async {
                      // Confirm deletion
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Session?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _sessionService.deleteSession(session.id);
                        await _loadChatHistory();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    _buildDetailSection(
                      title: 'Summary',
                      content: session.sessionSummary,
                      icon: Icons.summarize,
                      isDarkMode: isDarkMode,
                    ),

                    // Topics
                    if (session.topicsDiscussed.isNotEmpty)
                      _buildDetailSection(
                        title: 'Topics Discussed',
                        content: session.topicsDiscussed.join(', '),
                        icon: Icons.topic,
                        isDarkMode: isDarkMode,
                      ),

                    // Goals
                    if (session.userGoalsDiscussed != null)
                      _buildDetailSection(
                        title: 'Goals Mentioned',
                        content: session.userGoalsDiscussed!,
                        icon: Icons.flag,
                        isDarkMode: isDarkMode,
                      ),

                    // Recommendations
                    if (session.recommendationsGiven != null)
                      _buildDetailSection(
                        title: 'Recommendations',
                        content: session.recommendationsGiven!,
                        icon: Icons.lightbulb,
                        isDarkMode: isDarkMode,
                      ),

                    // Stats
                    _buildDetailSection(
                      title: 'Session Stats',
                      content: '${session.messageCount} messages • ${session.durationText}',
                      icon: Icons.analytics,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppTheme.darkCardBackground
                  : AppTheme.cardBackgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}