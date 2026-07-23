import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
            
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
            defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
    _initialized = true;
  }

  static Future<void> scheduleAlarm(String accountName, String aiProvider, DateTime resetTime) async {
    await initialize();
    
    final now = DateTime.now();
    if (resetTime.isBefore(now)) return;
    
    final duration = resetTime.difference(now);
    
    // Simple Dart timer for active app execution
    Timer(duration, () {
      _showNotification(accountName, aiProvider);
    });
  }

  static Future<void> _showNotification(String accountName, String aiProvider) async {
    await initialize();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'claude_alarms_ready',
      'Claude Accounts Ready',
      channelDescription: 'Alerts when your Claude accounts are ready to use',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _notificationsPlugin.show(
      id: accountName.hashCode + 1,
      title: 'Limit Reset',
      body: '$aiProvider ($accountName) - Limit reset',
      notificationDetails: platformChannelSpecifics,
    );
  }
}
