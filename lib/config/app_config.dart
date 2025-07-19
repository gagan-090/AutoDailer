class AppConfig {
  static const String appName = 'TeleCRM';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  
  // Dialer configuration
  static const int callTimeout = 30; // seconds
  static const int dialerDelay = 2; // seconds between calls
  
  // Lead status options
  static const List<String> leadStatuses = [
    'new',
    'contacted',
    'interested',
    'not_interested',
    'callback',
    'wrong_number',
    'not_reachable',
    'converted'
  ];
  
  // Call disposition options
  static const List<String> callDispositions = [
    'interested',
    'not_interested',
    'callback',
    'wrong_number',
    'not_reachable',
    'busy',
    'voicemail',
    'follow_up'
  ];
  
  // Notification configuration
  static const String notificationChannelId = 'telecrm_channel';
  static const String notificationChannelName = 'TeleCRM Notifications';
}