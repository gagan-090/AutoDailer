// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permission
    await Permission.notification.request();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate to appropriate screen
      print('Notification tapped with payload: $payload');
    }
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'telecrm_channel',
      'TeleCRM Notifications',
      channelDescription: 'Notifications for TeleCRM app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Schedule notification for follow-up
  static Future<void> scheduleFollowUpNotification({
    required int id,
    required String leadName,
    required DateTime scheduledTime,
    String? remarks,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'follow_up_channel',
      'Follow-up Reminders',
      channelDescription: 'Reminders for scheduled follow-ups',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'call_now',
          'Call Now',
        ),
        AndroidNotificationAction(
          'mark_done',
          'Mark Done',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    const title = 'Follow-up Reminder';
    final body = 'Time to follow up with $leadName${remarks != null ? '\n$remarks' : ''}';

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'follow_up:$id',
    );
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Show call disposition reminder
  static Future<void> showCallDispositionReminder({
    required String leadName,
    required String phone,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'Call Completed',
      body: 'Please update disposition for $leadName ($phone)',
      payload: 'call_disposition:$phone',
    );
  }

  // Show daily target reminder
  static Future<void> showDailyTargetReminder({
    required int targetCalls,
    required int actualCalls,
  }) async {
    final remaining = targetCalls - actualCalls;
    if (remaining > 0) {
      await showNotification(
        id: 9999, // Fixed ID for daily reminder
        title: 'Daily Target Reminder',
        body: 'You have $remaining calls remaining to reach your daily target of $targetCalls calls',
        payload: 'daily_target',
      );
    }
  }

  // Show overdue follow-ups notification
  static Future<void> showOverdueFollowUpsNotification(int count) async {
    if (count > 0) {
      await showNotification(
        id: 9998, // Fixed ID for overdue reminder
        title: 'Overdue Follow-ups',
        body: 'You have $count overdue follow-up${count > 1 ? 's' : ''} that need attention',
        payload: 'overdue_followups',
      );
    }
  }
}