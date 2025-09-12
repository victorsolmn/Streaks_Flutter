class ConversationContext {
  final String userId;
  final List<String> recentTopics;
  final Map<String, dynamic> userPreferences;
  final List<String> askedQuestions;
  final Map<String, String> userResponses;
  final DateTime lastInteraction;
  final String conversationStage; // 'getting_to_know', 'established', 'expert'
  final List<String> identifiedGaps; // Areas where we need more info
  final Map<String, double> topicInterest; // User interest scores by topic

  ConversationContext({
    required this.userId,
    this.recentTopics = const [],
    this.userPreferences = const {},
    this.askedQuestions = const [],
    this.userResponses = const {},
    required this.lastInteraction,
    this.conversationStage = 'getting_to_know',
    this.identifiedGaps = const [],
    this.topicInterest = const {},
  });

  factory ConversationContext.empty(String userId) {
    return ConversationContext(
      userId: userId,
      lastInteraction: DateTime.now(),
    );
  }

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      userId: json['userId'] ?? '',
      recentTopics: List<String>.from(json['recentTopics'] ?? []),
      userPreferences: Map<String, dynamic>.from(json['userPreferences'] ?? {}),
      askedQuestions: List<String>.from(json['askedQuestions'] ?? []),
      userResponses: Map<String, String>.from(json['userResponses'] ?? {}),
      lastInteraction: DateTime.parse(json['lastInteraction'] ?? DateTime.now().toIso8601String()),
      conversationStage: json['conversationStage'] ?? 'getting_to_know',
      identifiedGaps: List<String>.from(json['identifiedGaps'] ?? []),
      topicInterest: Map<String, double>.from(json['topicInterest'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'recentTopics': recentTopics,
      'userPreferences': userPreferences,
      'askedQuestions': askedQuestions,
      'userResponses': userResponses,
      'lastInteraction': lastInteraction.toIso8601String(),
      'conversationStage': conversationStage,
      'identifiedGaps': identifiedGaps,
      'topicInterest': topicInterest,
    };
  }

  ConversationContext copyWith({
    List<String>? recentTopics,
    Map<String, dynamic>? userPreferences,
    List<String>? askedQuestions,
    Map<String, String>? userResponses,
    DateTime? lastInteraction,
    String? conversationStage,
    List<String>? identifiedGaps,
    Map<String, double>? topicInterest,
  }) {
    return ConversationContext(
      userId: userId,
      recentTopics: recentTopics ?? this.recentTopics,
      userPreferences: userPreferences ?? this.userPreferences,
      askedQuestions: askedQuestions ?? this.askedQuestions,
      userResponses: userResponses ?? this.userResponses,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      conversationStage: conversationStage ?? this.conversationStage,
      identifiedGaps: identifiedGaps ?? this.identifiedGaps,
      topicInterest: topicInterest ?? this.topicInterest,
    );
  }

  // Helper methods
  bool hasAskedQuestion(String questionKey) {
    return askedQuestions.contains(questionKey);
  }

  String? getResponseFor(String questionKey) {
    return userResponses[questionKey];
  }

  bool isTopicOfInterest(String topic, {double threshold = 0.5}) {
    return (topicInterest[topic] ?? 0.0) > threshold;
  }

  // Add a new interaction
  ConversationContext addInteraction({
    String? topic,
    String? questionKey,
    String? response,
    Map<String, dynamic>? preferences,
  }) {
    final newRecentTopics = List<String>.from(recentTopics);
    if (topic != null && !newRecentTopics.contains(topic)) {
      newRecentTopics.add(topic);
      if (newRecentTopics.length > 10) { // Keep only last 10 topics
        newRecentTopics.removeAt(0);
      }
    }

    final newAskedQuestions = List<String>.from(askedQuestions);
    if (questionKey != null && !newAskedQuestions.contains(questionKey)) {
      newAskedQuestions.add(questionKey);
    }

    final newUserResponses = Map<String, String>.from(userResponses);
    if (questionKey != null && response != null) {
      newUserResponses[questionKey] = response;
    }

    final newUserPreferences = Map<String, dynamic>.from(userPreferences);
    if (preferences != null) {
      newUserPreferences.addAll(preferences);
    }

    return copyWith(
      recentTopics: newRecentTopics,
      askedQuestions: newAskedQuestions,
      userResponses: newUserResponses,
      userPreferences: newUserPreferences,
      lastInteraction: DateTime.now(),
    );
  }
}

// Question types and priorities
enum QuestionType {
  profileGap,     // Missing profile information
  goalClarification, // Clarify or refine goals
  challengeIdentification, // Identify obstacles
  preferenceDiscovery, // Learn preferences
  progressCheck, // Check on progress
  motivationalSupport, // Provide encouragement
}

class AgentQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final int priority; // 1-10, higher is more important
  final List<String> expectedAnswerTypes; // 'text', 'number', 'choice', etc.
  final Map<String, dynamic>? metadata;
  final bool canBeSkipped;
  final String? skipReason; // Why this can be skipped

  AgentQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.priority = 5,
    this.expectedAnswerTypes = const ['text'],
    this.metadata,
    this.canBeSkipped = true,
    this.skipReason,
  });

  factory AgentQuestion.fromJson(Map<String, dynamic> json) {
    return AgentQuestion(
      id: json['id'],
      question: json['question'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => QuestionType.profileGap,
      ),
      priority: json['priority'] ?? 5,
      expectedAnswerTypes: List<String>.from(json['expectedAnswerTypes'] ?? ['text']),
      metadata: json['metadata'],
      canBeSkipped: json['canBeSkipped'] ?? true,
      skipReason: json['skipReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.toString(),
      'priority': priority,
      'expectedAnswerTypes': expectedAnswerTypes,
      'metadata': metadata,
      'canBeSkipped': canBeSkipped,
      'skipReason': skipReason,
    };
  }
}