import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
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
    // Welcome message
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      message: "Hi! I'm your AI fitness coach. I'm here to help you reach your fitness goals! Feel free to ask me about nutrition, workouts, or any fitness-related questions.",
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    
    final profile = userProvider.profile;
    final todayNutrition = nutritionProvider.todayNutrition;
    final streakData = userProvider.streakData;
    
    final lowerMessage = userMessage.toLowerCase();
    
    // Greeting responses
    if (lowerMessage.contains('hi') || lowerMessage.contains('hello') || lowerMessage.contains('hey')) {
      return "Hello! Great to see you today! How can I help you with your fitness journey?";
    }
    
    // Progress-related questions
    if (lowerMessage.contains('progress') || lowerMessage.contains('how am i doing')) {
      final currentStreak = streakData?.currentStreak ?? 0;
      final calories = todayNutrition.totalCalories;
      return "You're doing great! You have a $currentStreak-day streak going and have logged $calories calories today. Keep up the excellent work! 💪";
    }
    
    // Diet and nutrition questions
    if (lowerMessage.contains('diet') || lowerMessage.contains('nutrition') || lowerMessage.contains('eat')) {
      final goal = profile?.goal;
      switch (goal) {
        case FitnessGoal.weightLoss:
          return "For weight loss, focus on:\n\n• Eat in a moderate calorie deficit\n• Prioritize protein (aim for ${nutritionProvider.proteinGoal.round()}g daily)\n• Include plenty of vegetables\n• Stay hydrated\n• Eat whole, unprocessed foods\n\nYou're currently at ${todayNutrition.totalCalories} calories today!";
        case FitnessGoal.muscleGain:
          return "For muscle gain, try these nutrition tips:\n\n• Eat in a slight calorie surplus\n• Get ${nutritionProvider.proteinGoal.round()}g+ protein daily\n• Time protein around workouts\n• Don't forget complex carbs\n• Stay consistent with meals\n\nYour protein today: ${todayNutrition.totalProtein.round()}g";
        default:
          return "Here are some general nutrition tips:\n\n• Focus on whole foods\n• Balance your macronutrients\n• Eat regular meals\n• Stay hydrated\n• Listen to your body\n\nYour current intake: ${todayNutrition.totalCalories} calories, ${todayNutrition.totalProtein.round()}g protein.";
      }
    }
    
    // Exercise questions
    if (lowerMessage.contains('exercise') || lowerMessage.contains('workout') || lowerMessage.contains('train')) {
      final goal = profile?.goal;
      switch (goal) {
        case FitnessGoal.weightLoss:
          return "For weight loss, I recommend:\n\n• 3-4 strength training sessions per week\n• 150+ minutes of moderate cardio\n• Daily walks (10,000+ steps)\n• HIIT workouts 1-2x per week\n• Stay active throughout the day\n\nRemember: nutrition is 70% of weight loss!";
        case FitnessGoal.muscleGain:
          return "For muscle gain, focus on:\n\n• 4-5 strength training sessions per week\n• Progressive overload\n• Compound movements (squats, deadlifts, bench)\n• 8-12 reps for hypertrophy\n• Adequate rest between sessions\n• Don't neglect cardio (2-3x per week)";
        case FitnessGoal.endurance:
          return "For endurance improvement:\n\n• Gradually increase training volume\n• Mix steady-state and interval training\n• Include strength training 2x per week\n• Focus on proper form\n• Allow for recovery days\n• Stay consistent!";
        default:
          return "Here's a balanced workout approach:\n\n• 3-4 strength training sessions\n• 2-3 cardio sessions\n• 1-2 rest days\n• Mix compound and isolation exercises\n• Progressive overload\n• Listen to your body!";
      }
    }
    
    // Motivation questions
    if (lowerMessage.contains('motivat') || lowerMessage.contains('give up') || lowerMessage.contains('discourag')) {
      final currentStreak = streakData?.currentStreak ?? 0;
      return "I believe in you! 🌟 You've already built a $currentStreak-day streak, which shows your dedication.\n\nRemember:\n• Progress isn't always linear\n• Small consistent actions compound\n• You're stronger than you think\n• Every day is a new opportunity\n• Focus on how you feel, not just numbers\n\nYou've got this! Keep pushing forward! 💪";
    }
    
    // Sleep questions
    if (lowerMessage.contains('sleep') || lowerMessage.contains('rest') || lowerMessage.contains('recover')) {
      return "Sleep is crucial for fitness! Here are some tips:\n\n• Aim for 7-9 hours per night\n• Keep a consistent sleep schedule\n• Create a dark, cool environment\n• Avoid screens 1 hour before bed\n• Try magnesium or melatonin\n• No caffeine 6+ hours before bed\n\nGood sleep = better recovery, mood, and results!";
    }
    
    // Water/hydration questions
    if (lowerMessage.contains('water') || lowerMessage.contains('hydrat')) {
      return "Staying hydrated is essential! 💧\n\n• Aim for 8-10 glasses daily\n• Drink more if you're active\n• Start your day with water\n• Carry a water bottle\n• Eat water-rich foods\n• Monitor urine color (pale yellow = good)\n\nProper hydration improves energy, recovery, and performance!";
    }
    
    // Generic motivational responses
    final motivationalResponses = [
      "That's a great question! Fitness is a journey, and every step counts. What specific area would you like to focus on?",
      "I'm here to help you succeed! Your consistency with tracking shows you're serious about your goals. Keep it up!",
      "Remember, sustainable progress is better than quick fixes. You're building habits that will last a lifetime!",
      "Every expert was once a beginner. You're doing amazing by taking control of your health!",
      "Small daily improvements lead to stunning yearly results. Keep pushing forward!"
    ];
    
    return motivationalResponses[DateTime.now().millisecond % motivationalResponses.length];
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
                gradient: const LinearGradient(
                  colors: [AppTheme.accentOrange, Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Fitness Coach',
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
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentOrange, Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: AppTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        _TypingIndicator(),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
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
                const SizedBox(width: 12),
                
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentOrange, Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isTyping ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: AppTheme.textPrimary,
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
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBackground,
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
            const SizedBox(height: 16),
            
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
                color: AppTheme.accentOrange,
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
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentOrange, Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppTheme.textPrimary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
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
                        ? AppTheme.accentOrange
                        : AppTheme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                      topRight: message.isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: message.isUser 
                        ? null 
                        : Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser 
                          ? AppTheme.textPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.textSecondary,
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
                color: AppTheme.textSecondary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}