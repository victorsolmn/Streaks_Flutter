import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/health_provider.dart';
import '../../services/grok_service.dart';
import '../../services/user_context_builder.dart';
import '../../utils/app_theme.dart';

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
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GrokService _grokService = GrokService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    // Get user context for personalized welcome
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.profile;
    final streakData = userProvider.streakData;
    
    String welcomeText = "Hi";
    if (profile?.name != null) {
      welcomeText += " ${profile!.name}";
    }
    welcomeText += "! I'm Streaker, your personalized AI fitness coach. ";
    
    if (streakData != null && streakData.currentStreak > 0) {
      welcomeText += "Amazing job on your ${streakData.currentStreak} day streak! 🔥 ";
    }
    
    if (profile?.goal != null) {
      String goal = profile!.goal.toString().split('.').last;
      if (goal == 'weightLoss') {
        welcomeText += "I'm here to help you with your weight loss journey. ";
      } else if (goal == 'muscleGain') {
        welcomeText += "Let's work together on building muscle and strength. ";
      } else if (goal == 'endurance') {
        welcomeText += "I'll help you boost your endurance and stamina. ";
      } else {
        welcomeText += "I'm here to help you maintain your fitness. ";
      }
    } else {
      welcomeText += "I'm here to help you reach your fitness goals! ";
    }
    
    welcomeText += "I have access to all your health metrics, nutrition data, and workout history, so I can provide personalized advice just for you.";
    
    // Welcome message
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      message: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });

    // Add some quick start suggestions
    Future.delayed(const Duration(milliseconds: 500), () {
      final suggestionsMessage = ChatMessage(
        id: 'suggestions_${DateTime.now().millisecondsSinceEpoch}',
        message: "Here are some things you can ask me:\n\n• How can I improve my diet?\n• What exercises should I do?\n• How do I stay motivated?\n• Meal suggestions for my goals\n• Tips for better sleep",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(suggestionsMessage);
      });
      _scrollToBottom();
    });
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

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      message: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Generate AI response
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    
    final aiResponse = await _generateAIResponse(messageText);
    final aiMessage = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      message: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(aiMessage);
      _isTyping = false;
    });

    _scrollToBottom();
  }

  Future<String> _generateAIResponse(String userMessage) async {
    // Build comprehensive user context
    final comprehensiveContext = UserContextBuilder.buildComprehensiveContext(context);
    
    // Generate personalized system prompt
    final personalizedPrompt = UserContextBuilder.generatePersonalizedSystemPrompt(comprehensiveContext);
    
    // Build conversation history (last 10 messages for context)
    final conversationHistory = <Map<String, String>>[];
    final startIndex = _messages.length > 10 ? _messages.length - 10 : 0;
    
    for (int i = startIndex; i < _messages.length; i++) {
      final msg = _messages[i];
      conversationHistory.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.message,
      });
    }
    
    // Call GROK API with personalized context
    try {
      final response = await _grokService.sendMessage(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
        personalizedSystemPrompt: personalizedPrompt,
      );
      
      return response;
    } catch (e) {
      print('Error generating AI response: $e');
      // Fallback to a friendly error message
      return "I'm having trouble connecting right now, but I'm still here to help! Feel free to ask me about nutrition, workouts, or any fitness questions. I'll do my best to assist you! 💪";
    }
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryAccent, Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/images/streaker_logo.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streaker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearChat();
                  break;
                case 'suggestions':
                  _showSuggestions();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suggestions',
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('Quick Questions'),
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryAccent, Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/streaker_logo.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 8),
                        _TypingIndicator(),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask your fitness coach...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 12),
                
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryAccent, Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isTyping ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Clear Chat'),
        content: Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.of(context).pop();
              _initializeChat();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Questions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            
            ...[
              'How can I improve my diet?',
              'What exercises should I do for my goals?',
              'How do I stay motivated?',
              'Tips for better sleep and recovery',
              'How much water should I drink?',
              'How am I progressing?'
            ].map((question) => ListTile(
              leading: Icon(
                Icons.help_outline,
                color: AppTheme.primaryAccent,
              ),
              title: Text(question),
              onTap: () {
                Navigator.of(context).pop();
                _messageController.text = question;
                _sendMessage();
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryAccent, Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SvgPicture.asset(
                'assets/images/streaker_logo.svg',
                colorFilter: ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? AppTheme.primaryAccent
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                      topRight: message.isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: message.isUser 
                        ? null 
                        : Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final delay = index * 0.2;
            final opacity = ((_animation.value + delay) % 1.0 > 0.5) ? 1.0 : 0.3;
            
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(opacity) ?? Colors.grey.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}