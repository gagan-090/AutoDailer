// lib/services/notification_service.dart - STUB VERSION (No External Dependencies)
class NotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    print('NotificationService: Initialized (stub version)');
    _initialized = true;
  }

  // Show immediate notification (stub)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('Notification: $title - $body');
    // In a real app, this would show actual notifications
    // For now, we just log to console
  }

  // Simple follow-up notification (stub)
  static Future<void> scheduleFollowUpNotification({
    required int id,
    required String leadName,
    required DateTime scheduledTime,
    String? remarks,
  }) async {
    print('Follow-up scheduled for $leadName at $scheduledTime');
    // This is a placeholder - we'll implement real notifications later
  }

  // Cancel notification (stub)
  static Future<void> cancelNotification(int id) async {
    print('Cancelled notification: $id');
  }

  // Cancel all notifications (stub)
  static Future<void> cancelAllNotifications() async {
    print('Cancelled all notifications');
  }

  // Show call disposition reminder (stub)
  static Future<void> showCallDispositionReminder({
    required String leadName,
    required String phone,
  }) async {
    print('Call disposition reminder for $leadName ($phone)');
  }

  // Show daily target reminder (stub)
  static Future<void> showDailyTargetReminder({
    required int targetCalls,
    required int actualCalls,
  }) async {
    final remaining = targetCalls - actualCalls;
    if (remaining > 0) {
      print('Daily target reminder: $remaining calls remaining');
    }
  }

  // Show overdue follow-ups notification (stub)
  static Future<void> showOverdueFollowUpsNotification(int count) async {
    if (count > 0) {
      print('Overdue follow-ups: $count');
    }
  }
}