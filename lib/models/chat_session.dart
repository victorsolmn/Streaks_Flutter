import 'dart:convert';

class ChatSession {
  final String id;
  final String userId;
  final DateTime sessionDate;
  final int sessionNumber;
  final String sessionTitle;
  final String sessionSummary;
  final List<String> topicsDiscussed;
  final String? userGoalsDiscussed;
  final String? recommendationsGiven;
  final String? userSentiment;
  final int messageCount;
  final int? durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    required this.sessionDate,
    required this.sessionNumber,
    required this.sessionTitle,
    required this.sessionSummary,
    required this.topicsDiscussed,
    this.userGoalsDiscussed,
    this.recommendationsGiven,
    this.userSentiment,
    required this.messageCount,
    this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      userId: json['user_id'],
      sessionDate: DateTime.parse(json['session_date']),
      sessionNumber: json['session_number'],
      sessionTitle: json['session_title'] ?? 'Chat Session',
      sessionSummary: json['session_summary'],
      topicsDiscussed: List<String>.from(json['topics_discussed'] ?? []),
      userGoalsDiscussed: json['user_goals_discussed'],
      recommendationsGiven: json['recommendations_given'],
      userSentiment: json['user_sentiment'],
      messageCount: json['message_count'] ?? 0,
      durationMinutes: json['duration_minutes'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_date': sessionDate.toIso8601String().split('T')[0],
      'session_number': sessionNumber,
      'session_title': sessionTitle,
      'session_summary': sessionSummary,
      'topics_discussed': topicsDiscussed,
      'user_goals_discussed': userGoalsDiscussed,
      'recommendations_given': recommendationsGiven,
      'user_sentiment': userSentiment,
      'message_count': messageCount,
      'duration_minutes': durationMinutes,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[sessionDate.month - 1]} ${sessionDate.day}, ${sessionDate.year}';
  }

  String get formattedTime {
    final hour = startedAt.hour;
    final minute = startedAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get durationText {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 1) return 'Less than a minute';
    if (durationMinutes! < 60) return '${durationMinutes} min';
    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;
    return '${hours}h ${mins}m';
  }

  String get sentimentEmoji {
    switch (userSentiment) {
      case 'positive':
        return '😊';
      case 'negative':
        return '😟';
      case 'mixed':
        return '🤔';
      default:
        return '😐';
    }
  }

  bool get isCompleted => endedAt != null;

  // Check if session is from today
  bool get isToday {
    final now = DateTime.now();
    return sessionDate.year == now.year &&
           sessionDate.month == now.month &&
           sessionDate.day == now.day;
  }

  // Check if session is from yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return sessionDate.year == yesterday.year &&
           sessionDate.month == yesterday.month &&
           sessionDate.day == yesterday.day;
  }

  // Get relative date string
  String get relativeDateString {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';

    final daysDiff = DateTime.now().difference(sessionDate).inDays;
    if (daysDiff < 7) {
      return '$daysDiff days ago';
    } else if (daysDiff < 30) {
      final weeks = daysDiff ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return formattedDate;
    }
  }
}