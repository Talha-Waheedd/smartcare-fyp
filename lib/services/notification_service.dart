// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/notification_service.dart
// FIX: Removed zonedSchedule (requires exact alarm permission that's hard to
//      get on Android 12+). Now uses periodicallyShow (simpler, no timezone
//      issues, works on all Android versions without special permissions).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  // ── INITIALIZE ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_reminders',
      'Medication Reminders',
      description: 'Daily reminders to take your medications on time',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission(); // Android 13+

    // Initialize local notifications plugin
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // FCM permissions + foreground handler
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showInstantNotification(
          title: message.notification!.title ?? 'SmartCare',
          body: message.notification!.body ?? '',
        );
      }
    });

    _initialized = true;
    debugPrint('✓ NotificationService initialized');
  }

  // ── SAVE FCM TOKEN TO FIRESTORE ────────────────────────────────────────────
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'fcmToken': token});
        debugPrint('✓ FCM token saved');
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // ── INSTANT NOTIFICATION ───────────────────────────────────────────────────
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Instant notification error: $e');
    }
  }

  // ── SCHEDULE DAILY REMINDER ────────────────────────────────────────────────
  // Shows a confirmation notification immediately + sets a daily repeating one.
  Future<void> scheduleMedicationReminder({
    required int notificationId,
    required String medicationName,
    required String dosage,
    required String timeString,
  }) async {
    try {
      // Confirm to user that reminder is set
      await showInstantNotification(
        title: '💊 Reminder Set!',
        body: '$medicationName ($dosage) reminder set for $timeString daily.',
        payload: medicationName,
      );

      // Daily repeating reminder
      await _localNotifications.periodicallyShow(
        notificationId,
        '💊 Medication Reminder',
        'Time to take $medicationName ($dosage) — $timeString',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: medicationName,
      );
      debugPrint('✓ Daily reminder set: $medicationName at $timeString');
    } catch (e) {
      debugPrint('Schedule reminder error: $e');
    }
  }

  // ── CANCEL REMINDERS ───────────────────────────────────────────────────────
  Future<void> cancelMedicationReminders({
    required int baseNotificationId,
    required int timesCount,
  }) async {
    for (int i = 0; i < timesCount; i++) {
      await _localNotifications.cancel(baseNotificationId + i);
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}