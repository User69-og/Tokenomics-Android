import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app_preferences.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
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
    final enabled = await AppPreferences.getNotificationsEnabled();
    if (!enabled) return;
    
    await initialize();
    
    // Request permission on Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    final now = DateTime.now();
    if (resetTime.isBefore(now)) return;
    
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
        
    await _notificationsPlugin.zonedSchedule(
      id: accountName.hashCode + 1,
      title: 'Limit Reset',
      body: '$aiProvider ($accountName) - Limit reset',
      scheduledDate: tz.TZDateTime.from(resetTime, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<String?> sendTestNotification() async {
    try {
      await initialize();
      
      // Request permission on Android 13+
      final granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (granted == false) {
        return "Notification permission denied.";
      }

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
        id: 9999,
        title: 'Test Notification',
        body: 'If you see this, token limit alerts are working!',
        notificationDetails: platformChannelSpecifics,
      );
      return null; // Success
    } catch (e) {
      print("Notification Error: $e");
      return e.toString();
    }
  }
}
