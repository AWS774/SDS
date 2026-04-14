import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // print('🔔 Initializing NotificationService...');

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
    // print('✅ NotificationService initialized successfully');
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      // print('📱 Notification permission granted: $granted');
    }
  }

  void _onNotificationTap(NotificationResponse notificationResponse) {
    // print('🔔 Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> showTemperatureAlert({
    required double currentTemperature,
    required double maxTemperature,
    int? durationSeconds,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // print(
    //   '🚨 Showing temperature alert: Current=$currentTemperature°C, Max=$maxTemperature°C',
    // );

    try {
      // Trigger vibration
      await _triggerVibration();

      final durationText =
          durationSeconds != null && durationSeconds > 0
              ? _formatDuration(durationSeconds)
              : null;

      // Show notification
      await _showNotification(
        title: '🌡️ Peringatan Suhu Tinggi!',
        body:
            'Suhu saat ini ${currentTemperature.toStringAsFixed(1)}°C melebihi batas maksimal ${maxTemperature.toStringAsFixed(1)}°C${durationText != null ? '\nDurasi di atas setpoint: $durationText' : ''}',
        payload: 'temperature_alert',
      );

      // print('✅ Temperature alert notification sent successfully');
    } catch (e) {
      // print('❌ Error sending temperature alert: $e');
      // Rethrow to allow caller to handle the error
      rethrow;
    }
  }

  String _formatDuration(int totalSeconds) {
    final seconds = totalSeconds.clamp(0, 1 << 31);
    final duration = Duration(seconds: seconds);

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days hari');
    if (hours > 0) parts.add('$hours jam');
    if (minutes > 0) parts.add('$minutes menit');
    if (secs > 0 || parts.isEmpty) parts.add('$secs detik');

    return parts.join(' ');
  }

  Future<void> _triggerVibration() async {
    try {
      // Check if vibration is available
      bool? hasVibrator = await Vibration.hasVibrator();
      // print('📳 Device has vibrator: $hasVibrator');

      if (hasVibrator == true) {
        // Create alarm-like vibration pattern
        // Pattern: [wait, vibrate, wait, vibrate, ...]
        List<int> pattern = [0, 500, 200, 500, 200, 500, 200, 500];

        await Vibration.vibrate(pattern: pattern);
        // print('📳 Vibration triggered with alarm pattern');
      } else {
        // print('⚠️ Device does not support vibration');
      }
    } catch (e) {
      // print('❌ Error triggering vibration: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'temperature_alerts',
            'Temperature Alerts',
            channelDescription:
                'Notifications for temperature threshold alerts',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            // Use default notification sound instead of custom alarm sound
            // sound: RawResourceAndroidNotificationSound('alarm'),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // Use default sound instead of custom sound file
            // sound: 'alarm.wav',
            categoryIdentifier: 'TEMPERATURE_ALERT',
            interruptionLevel: InterruptionLevel.critical,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0, // notification id
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      // print('✅ Notification shown successfully');
    } catch (e) {
      // print('❌ Error showing notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    // print('🔕 All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    // print('🔕 Notification $id cancelled');
  }

  Future<void> showTimeNotificationAlert() async {
    if (!_isInitialized) {
      await initialize();
    }

    // print('🕒 Showing ESP32 time notification alert');

    try {
      // Trigger vibration with 500ms duration as specified
      await _triggerTimeNotificationVibration();

      // Show notification
      await _showNotification(
        title: '⏰ Waktu Penyimpanan',
        body: 'Waktu penyimpanan telah tercapai',
        payload: 'time_notification',
      );

      // print('✅ Time notification alert sent successfully');
    } catch (e) {
      // print('❌ Error sending time notification alert: $e');
    }
  }

  Future<void> _triggerTimeNotificationVibration() async {
    try {
      // Check if vibration is available
      bool? hasVibrator = await Vibration.hasVibrator();

      if (hasVibrator == true) {
        // Simple vibration for 500ms
        await Vibration.vibrate(duration: 500);
        // print('📳 Time notification vibration triggered (500ms)');
      }
    } catch (e) {
      // print('❌ Error triggering time notification vibration: $e');
    }
  }
}
