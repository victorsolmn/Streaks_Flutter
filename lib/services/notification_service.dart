import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  StreamController<RemoteMessage>? _messageStreamController;
  Stream<RemoteMessage>? _messageStream;

  Stream<RemoteMessage> get messageStream {
    _messageStreamController ??= StreamController<RemoteMessage>.broadcast();
    _messageStream ??= _messageStreamController!.stream;
    return _messageStream!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up Firebase messaging
    await _setupFirebaseMessaging();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'streaks_notifications',
      'Streaks Reminders',
      description: 'Notifications for streak reminders and achievements',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: Send token to your server if needed
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    
    // Show local notification when app is in foreground
    _showLocalNotification(message);
    
    // Add to stream for listeners
    _messageStreamController?.add(message);
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    
    // Navigate based on notification data
    if (message.data.containsKey('route')) {
      // TODO: Navigate to specific screen
      final route = message.data['route'];
      debugPrint('Navigate to: $route');
    }
    
    // Add to stream for listeners
    _messageStreamController?.add(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'streaks_notifications',
      'Streaks Reminders',
      channelDescription: 'Notifications for streak reminders and achievements',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // TODO: Handle navigation based on payload
  }

  // Schedule local notifications
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required int id,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'streaks_notifications',
      'Streaks Reminders',
      channelDescription: 'Daily reminders to maintain your streak',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily notification
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Predefined notifications
  Future<void> scheduleStreakReminder() async {
    await scheduleDailyReminder(
      hour: 20,
      minute: 0,
      title: '🔥 Keep Your Streak Alive!',
      body: 'Don\'t forget to log your meals and activities today',
      id: 1,
    );
  }

  Future<void> scheduleMorningMotivation() async {
    await scheduleDailyReminder(
      hour: 8,
      minute: 0,
      title: '🌅 Good Morning!',
      body: 'Start your day right with a healthy breakfast',
      id: 2,
    );
  }

  Future<void> scheduleWaterReminder() async {
    // Schedule multiple water reminders throughout the day
    final times = [
      {'hour': 9, 'minute': 0, 'id': 10},
      {'hour': 12, 'minute': 0, 'id': 11},
      {'hour': 15, 'minute': 0, 'id': 12},
      {'hour': 18, 'minute': 0, 'id': 13},
    ];

    for (final time in times) {
      await scheduleDailyReminder(
        hour: time['hour'] as int,
        minute: time['minute'] as int,
        title: '💧 Hydration Reminder',
        body: 'Time to drink some water!',
        id: time['id'] as int,
      );
    }
  }

  Future<void> scheduleLunchReminder() async {
    await scheduleDailyReminder(
      hour: 12,
      minute: 30,
      title: '🍽️ Lunch Time',
      body: 'Remember to log your lunch and stay on track',
      id: 3,
    );
  }

  Future<void> scheduleWorkoutReminder() async {
    await scheduleDailyReminder(
      hour: 17,
      minute: 0,
      title: '💪 Workout Time',
      body: 'Ready for your daily exercise?',
      id: 4,
    );
  }

  // Show immediate notifications
  Future<void> showStreakAchievement(int days) async {
    final androidDetails = AndroidNotificationDetails(
      'streaks_notifications',
      'Streaks Reminders',
      channelDescription: 'Achievement notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String title = '🎉 Achievement Unlocked!';
    String body = '';

    if (days == 7) {
      body = 'You\'ve maintained a 7-day streak! Keep it up!';
    } else if (days == 30) {
      body = 'Incredible! 30-day streak achieved! 🏆';
    } else if (days == 100) {
      body = 'Legendary! 100-day streak! You\'re unstoppable! 💪';
    } else {
      body = 'You\'re on a $days-day streak! Amazing progress!';
    }

    await _localNotifications.show(
      999, // Special ID for achievements
      title,
      body,
      details,
    );
  }

  Future<void> showGoalReached(String goalType) async {
    final androidDetails = AndroidNotificationDetails(
      'streaks_notifications',
      'Streaks Reminders',
      channelDescription: 'Goal completion notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      998,
      '✅ Goal Reached!',
      'You\'ve hit your $goalType goal for today!',
      details,
    );
  }

  // Get FCM token for server
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topics for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  void dispose() {
    _messageStreamController?.close();
  }
}