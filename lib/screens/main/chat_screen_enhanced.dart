import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class ChatScreenEnhanced extends StatefulWidget {
  const ChatScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<ChatScreenEnhanced> createState() => _ChatScreenEnhancedState();
}

class _ChatScreenEnhancedState extends State<ChatScreenEnhanced> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GrokService _grokService = GrokService();
  bool _isTyping = false;
  bool _showWelcomeScreen = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? presetMessage]) async {
    final messageText = presetMessage ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Hide welcome screen when first message is sent
    if (_showWelcomeScreen) {
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

  Widget _buildWelcomeScreen() {
    final userProvider = Provider.of<UserProvider>(context);
    final profile = userProvider.profile;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Debug: Print profile data
    print('Profile data: ${profile?.name}');
    print('Profile exists: ${profile != null}');
    
    // Get the actual user name with multiple fallback options
    String userName = 'there';
    
    if (profile?.name != null && profile!.name.trim().isNotEmpty) {
      // Get first name if it's a full name, capitalize first letter
      final fullName = profile.name.trim();
      userName = fullName.split(' ').first;
      // Capitalize first letter
      if (userName.isNotEmpty) {
        userName = userName[0].toUpperCase() + userName.substring(1).toLowerCase();
      }
    } else {
      // For demo purposes, let's set a default name
      // In production, you'd load this from user preferences or prompt for it
      userName = 'Vicky'; // You can change this to your preferred name
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  AppTheme.darkBackground,
                  AppTheme.darkCardBackground,
                ]
              : [
                  AppTheme.backgroundLight,
                  AppTheme.cardBackgroundLight,
                ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          'Streaker AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode 
                                ? AppTheme.textPrimaryDark 
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Your fitness assistant',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content - fit everything in viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Greeting - more compact
                    Text(
                      'Hi, $userName!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode 
                            ? AppTheme.textPrimaryDark 
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How can I help you?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode 
                            ? AppTheme.textPrimaryDark 
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your fitness assistant is ready',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick prompts - more compact
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildQuickPromptChip(
                          icon: Icons.fitness_center,
                          label: 'Workout for today',
                          onTap: () => _sendMessage('What workout should I do today?'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.restaurant_menu,
                          label: 'Healthy recipes',
                          onTap: () => _sendMessage('Suggest some healthy recipes for me'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.auto_awesome,
                          label: 'Daily motivation',
                          onTap: () => _sendMessage('Give me some fitness motivation for today'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.newspaper,
                          label: 'Fitness news',
                          onTap: () => _sendMessage('What\'s the latest in fitness and health?'),
                        ),
                        _buildQuickPromptChip(
                          icon: Icons.summarize,
                          label: 'Daily summary',
                          onTap: () => _sendMessage('Give me a summary of my fitness progress today'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Popular topics - horizontal scroller
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header without "See all"
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Popular topics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode 
                                    ? AppTheme.textPrimaryDark 
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Horizontal scrolling topic cards
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTopicCard(
                                    icon: Icons.fitness_center,
                                    title: 'Gym Workout',
                                    subtitle: 'Equipment-based exercises',
                                    onTap: () => _sendMessage('Create a gym workout plan for me'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildTopicCard(
                                    icon: Icons.home,
                                    title: 'Home Workout',
                                    subtitle: 'No equipment needed',
                                    onTap: () => _sendMessage('Create a home workout routine for me'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildTopicCard(
                                    icon: Icons.self_improvement,
                                    title: 'Yoga',
                                    subtitle: 'Flexibility & mindfulness',
                                    onTap: () => _sendMessage('Suggest yoga poses for beginners'),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildTopicCard(
                                    icon: Icons.directions_run,
                                    title: 'Outdoor',
                                    subtitle: 'Running & ground exercises',
                                    onTap: () => _sendMessage('Plan an outdoor workout session'),
                                  ),
                                  const SizedBox(width: 20), // Extra padding at end
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? AppTheme.darkCardBackground 
                    : AppTheme.backgroundLight,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode 
                        ? AppTheme.dividerDark 
                        : AppTheme.dividerLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: isDarkMode
                            ? AppTheme.darkBackground
                            : AppTheme.cardBackgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
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
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
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
      ),
    );
  }

  Widget _buildQuickPromptChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? AppTheme.darkCardBackground 
              : AppTheme.cardBackgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode 
                ? AppTheme.dividerDark 
                : AppTheme.dividerLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppTheme.primaryAccent,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode 
                    ? AppTheme.textPrimaryDark 
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140, // Fixed width for horizontal scrolling
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? AppTheme.darkCardBackground 
              : AppTheme.cardBackgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode 
                ? AppTheme.dividerDark 
                : AppTheme.dividerLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode 
                    ? AppTheme.textPrimaryDark 
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode 
                    ? AppTheme.textSecondaryDark 
                    : AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode 
            ? AppTheme.darkCardBackground 
            : AppTheme.backgroundLight,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
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
                    'Streaker AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode 
                          ? AppTheme.textPrimaryDark 
                          : AppTheme.textPrimary,
                    ),
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
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _showWelcomeScreen = true;
              });
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode 
                  ? AppTheme.textPrimaryDark 
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: SvgPicture.asset(
                        'assets/images/streaker_logo.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streaker AI',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _TypingIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? AppTheme.darkCardBackground 
                  : AppTheme.backgroundLight,
              border: Border(
                top: BorderSide(
                  color: isDarkMode 
                      ? AppTheme.dividerDark 
                      : AppTheme.dividerLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: isDarkMode
                          ? AppTheme.darkBackground
                          : AppTheme.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
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
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isTyping ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
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

  Future<String?> _loadUserNameFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try different keys that might store the user name
      return prefs.getString('user_name') ?? 
             prefs.getString('userName') ?? 
             prefs.getString('name');
    } catch (e) {
      print('Error loading user name from prefs: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showWelcomeScreen ? _buildWelcomeScreen() : _buildChatInterface();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (message.isUser) {
      // User message - simple right-aligned bubble
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // AI message - ChatGPT style
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and name row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: SvgPicture.asset(
                      'assets/images/streaker_logo.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Streaker AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? AppTheme.textSecondaryDark.withOpacity(0.6)
                        : AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Message content without container
            _buildFormattedAIResponse(message.message, isDarkMode),
          ],
        ),
      );
    }
  }

  Widget _buildFormattedAIResponse(String message, bool isDarkMode) {
    final primaryTextColor = isDarkMode 
        ? AppTheme.textPrimaryDark 
        : AppTheme.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? AppTheme.textSecondaryDark 
        : AppTheme.textSecondary;

    // Clean up the message to remove any formatting artifacts
    message = message.replaceAll('\\n', '\n');
    message = message.replaceAll('\\"', '"');
    message = message.replaceAll("\\'", "'");
    
    return Container(
      padding: const EdgeInsets.only(left: 44), // Indent to align with avatar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseAndFormatMessage(message, primaryTextColor, secondaryTextColor, isDarkMode),
      ),
    );
  }

  List<Widget> _parseAndFormatMessage(String message, Color primaryColor, Color secondaryColor, bool isDarkMode) {
    final widgets = <Widget>[];
    final lines = message.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Headers (## Title or # Title or **Title**)
      if (line.startsWith('#') || (line.startsWith('**') && line.endsWith('**') && !line.contains(' '))) {
        String title;
        FontWeight fontWeight;
        double fontSize;
        if (line.startsWith('###')) {
          title = line.substring(3).trim();
          fontSize = 16;
          fontWeight = FontWeight.w600;
        } else if (line.startsWith('##')) {
          title = line.substring(2).trim();
          fontSize = 18;
          fontWeight = FontWeight.w700;
        } else if (line.startsWith('#')) {
          title = line.substring(1).trim();
          fontSize = 20;
          fontWeight = FontWeight.w700;
        } else {
          title = line.substring(2, line.length - 2).trim();
          fontSize = 16;
          fontWeight = FontWeight.w600;
        }
        
        // Add emoji support for headers
        if (title.contains('🥗') || title.contains('💪') || title.contains('🏃') || 
            title.contains('🧘') || title.contains('📊') || title.contains('✅')) {
          widgets.add(Padding(
            padding: EdgeInsets.only(bottom: 12.0, top: i > 0 ? 20.0 : 0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: primaryColor,
                height: 1.3,
              ),
            ),
          ));
        } else {
          widgets.add(Padding(
            padding: EdgeInsets.only(bottom: 12.0, top: i > 0 ? 20.0 : 0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: primaryColor,
                height: 1.3,
              ),
            ),
          ));
        }
      }
      // Bullet points (• or - or *)
      else if (line.trimLeft().startsWith('•') || line.trimLeft().startsWith('-') || line.trimLeft().startsWith('*')) {
        final trimmedLine = line.trimLeft();
        final bulletText = trimmedLine.substring(1).trim();
        final indent = line.length - trimmedLine.length;
        
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 8.0, left: indent > 0 ? 20.0 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontSize: 15,
                  color: primaryColor,
                  height: 1.5,
                ),
              ),
              Expanded(
                child: _buildRichText(bulletText, primaryColor, secondaryColor),
              ),
            ],
          ),
        ));
      }
      // Numbers (1. 2. 3.)
      else if (RegExp(r'^\s*\d+\.').hasMatch(line)) {
        final match = RegExp(r'^(\s*)(\d+)\.\s*(.*)').firstMatch(line);
        if (match != null) {
          final indent = match.group(1)?.length ?? 0;
          final number = match.group(2) ?? '';
          final text = match.group(3) ?? '';
          
          widgets.add(Padding(
            padding: EdgeInsets.only(bottom: 6.0, left: indent > 0 ? 24.0 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  child: Text(
                    '$number.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor.withOpacity(0.8),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichText(text, primaryColor, secondaryColor),
                ),
              ],
            ),
          ));
        }
      }
      // Code blocks (```code```)
      else if (line.startsWith('```')) {
        // Start of multiline code block - collect all lines until closing ```
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        
        if (codeLines.isNotEmpty) {
          widgets.add(Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              codeLines.join('\n'),
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                color: primaryColor,
                height: 1.5,
              ),
            ),
          ));
        }
      }
      // Quote blocks (> text)
      else if (line.startsWith('>')) {
        final quoteText = line.substring(1).trim();
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: secondaryColor.withOpacity(0.4),
                width: 4,
              ),
            ),
          ),
          child: _buildRichText(quoteText, secondaryColor, secondaryColor),
        ));
      }
      // Horizontal line (--- or ***)
      else if (line.trim() == '---' || line.trim() == '***' || line.trim() == '___') {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                secondaryColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ));
      }
      // Regular text
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: _buildRichText(line, primaryColor, secondaryColor),
        ));
      }
    }
    
    return widgets.isEmpty 
        ? [Text(
            message,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: primaryColor,
            ),
          )]
        : widgets;
  }

  Widget _buildRichText(String text, Color primaryColor, Color secondaryColor) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*|`(.*?)`');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: primaryColor),
        ));
      }

      // Add formatted text
      if (match.group(1) != null) {
        // Bold text **text**
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ));
      } else if (match.group(2) != null) {
        // Italic text *text*
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: primaryColor,
          ),
        ));
      } else if (match.group(3) != null) {
        // Code text `text`
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: secondaryColor.withOpacity(0.1),
            color: AppTheme.primaryAccent,
            fontSize: 13,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: primaryColor),
      ));
    }

    return spans.isEmpty
        ? Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: primaryColor,
            ),
          )
        : RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: primaryColor,
              ),
              children: spans,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                color: (isDarkMode 
                    ? AppTheme.textSecondaryDark 
                    : AppTheme.textSecondary).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}