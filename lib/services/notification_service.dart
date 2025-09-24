import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1001;
  static const int _fixedHour = 21; // 9 PM
  static const int _fixedMinute = 0; // 9:00 PM

  /// Initialize the notification service
  static Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Set local timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      debugPrint('🌍 Current timezone: $timeZoneName');

      // Android initialization settings
      const androidInitializationSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );

      // iOS initialization settings
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ Notification plugin initialized');

      // Request permissions for Android 13+
      await _requestPermissions();

      // Test immediate notification to verify system works
      await _testImmediateNotification();
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  /// Test immediate notification to verify system works
  static Future<void> _testImmediateNotification() async {
    try {
      await _notifications.show(
        888, // Test ID
        'Notification System Test',
        'If you see this, notifications are working!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('🧪 Test notification sent during initialization');
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Request notification permission for Android 13+
      final bool? notificationGranted = await androidPlugin
          .requestNotificationsPermission();
      debugPrint('📱 Notification permission granted: $notificationGranted');

      // Request exact alarm permission for Android 12+
      final bool? exactAlarmGranted = await androidPlugin
          .requestExactAlarmsPermission();
      debugPrint('⏰ Exact alarm permission granted: $exactAlarmGranted');
    }

    // Request iOS permissions
    if (Platform.isIOS) {
      final bool? iosResult = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('📱 iOS notification permission granted: $iosResult');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final bool? result = await androidPlugin.areNotificationsEnabled();
        return result ?? false;
      }
    }
    return false;
  }

  /// Check if exact alarms are allowed
  static Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final bool? result = await androidPlugin
            .canScheduleExactNotifications();
        return result ?? false;
      }
    }
    return true; // iOS doesn't have this restriction
  }

  /// Request to ignore battery optimizations (Android)
  static Future<void> _requestIgnoreBatteryOptimizations() async {
    if (Platform.isAndroid) {
      try {
        // Note: Battery optimization exemption is typically handled by the system
        // The user needs to manually disable battery optimization in device settings
        debugPrint(
          '🔋 Battery optimization: User needs to disable in device settings',
        );
        debugPrint(
          '📱 Path: Settings > Apps > Penni > Battery > Don\'t optimize',
        );
      } catch (e) {
        debugPrint('⚠️ Could not request battery optimization exemption: $e');
      }
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Navigate to add expense screen when notification is tapped
    // This will be handled by the main app navigation
  }

  /// Schedule daily reminder at fixed time (9 PM)
  static Future<bool> scheduleDailyReminder() async {
    return await scheduleCustomReminder(hour: _fixedHour, minute: _fixedMinute);
  }

  /// Schedule daily reminder at custom time
  static Future<bool> scheduleCustomReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      debugPrint('🔄 Starting reminder scheduling process...');
      debugPrint(
        '⏰ Target time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );

      // Cancel any existing reminder
      await cancelNotifications();
      debugPrint('🗑️ Cancelled existing notifications');

      // Get the next instance of the specified time
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      final now = DateTime.now();
      final timeUntilNotification = scheduledTime.difference(now);

      debugPrint('📅 Current time: $now');
      debugPrint('📅 Scheduled time: $scheduledTime');
      debugPrint(
        '⏱️ Time until notification: ${timeUntilNotification.inMinutes} minutes',
      );

      // Android notification details with enhanced reliability
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Expense Reminder',
        channelDescription: 'Reminds you to track your daily expenses',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: Color(0xFF4A55A2), // Primary color from theme
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        fullScreenIntent: true, // Show even when device is locked
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: false,
        channelShowBadge: true,
        ticker: 'Time to track your expenses!',
        styleInformation: BigTextStyleInformation(
          'Don\'t forget to log your daily expenses and stay on top of your budget.',
          contentTitle: 'Time to Track Your Expenses! 💰',
          summaryText: 'Daily Expense Reminder',
        ),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      // Combined notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the daily recurring notification at custom time
      await _notifications.zonedSchedule(
        _notificationId,
        'Time to Track Your Expenses! 💰',
        'Don\'t forget to log your daily expenses and stay on top of your budget.',
        scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Temporarily remove matchDateTimeComponents to test
        payload: 'add_expense', // Navigation payload
      );

      debugPrint('✅ Daily reminder scheduled successfully!');
      debugPrint('📱 Notification ID: $_notificationId');

      // Verify the notification was scheduled
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      debugPrint(
        '📋 Total pending notifications: ${pendingNotifications.length}',
      );

      // Request to ignore battery optimizations for better reliability
      await _requestIgnoreBatteryOptimizations();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to schedule daily reminder: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      return false;
    }
  }

  /// Calculate the next instance of the specified time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final local = tz.local;
    final now = tz.TZDateTime.now(local);

    print('🕐 Current time: $now');
    debugPrint('🕐 Current time: $now');
    print(
      '🎯 Target time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
    debugPrint(
      '🎯 Target time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );

    // Create the scheduled date for today
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    print('📅 Today\'s scheduled time: $scheduledDate');
    debugPrint('📅 Today\'s scheduled time: $scheduledDate');

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('⏭️ Time passed today, scheduling for tomorrow: $scheduledDate');
      debugPrint(
        '⏭️ Time passed today, scheduling for tomorrow: $scheduledDate',
      );
    } else {
      print('✅ Time is in the future today: $scheduledDate');
      debugPrint('✅ Time is in the future today: $scheduledDate');
    }

    final timeUntil = scheduledDate.difference(now);
    print(
      '⏱️ Time until notification: ${timeUntil.inMinutes} minutes (${timeUntil.inHours} hours)',
    );
    debugPrint(
      '⏱️ Time until notification: ${timeUntil.inMinutes} minutes (${timeUntil.inHours} hours)',
    );

    print('📤 Returning scheduled time: $scheduledDate');
    debugPrint('📤 Returning scheduled time: $scheduledDate');

    return scheduledDate;
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelNotifications() async {
    try {
      await _notifications.cancel(_notificationId);
      await _notifications.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule a test notification for 2 minutes from now
  static Future<bool> scheduleTestNotification() async {
    try {
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 2));
      final scheduledTime = tz.TZDateTime.from(testTime, tz.local);

      debugPrint('🧪 Scheduling test notification for 2 minutes from now');
      debugPrint('📅 Test time: $scheduledTime');

      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        777, // Test notification ID
        'Test Reminder 🧪',
        'This is a test notification scheduled for 2 minutes from now!',
        scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_reminder',
      );

      debugPrint('✅ Test notification scheduled successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to schedule test notification: $e');
      return false;
    }
  }

  /// Schedule a test notification using the same logic as daily reminders
  static Future<bool> scheduleTimeBasedTest() async {
    try {
      print('🧪 Starting time-based test...');
      debugPrint('🧪 Starting time-based test...');

      final now = DateTime.now();
      // Schedule for 3 minutes from now using the same time calculation logic
      final testHour = now.hour;
      final testMinute = now.minute + 3;

      // Handle minute overflow
      final adjustedMinute = testMinute >= 60 ? testMinute - 60 : testMinute;
      final adjustedHour = testMinute >= 60 ? (testHour + 1) % 24 : testHour;

      print(
        '🧪 Testing time-based scheduling for ${adjustedHour.toString().padLeft(2, '0')}:${adjustedMinute.toString().padLeft(2, '0')}',
      );
      debugPrint(
        '🧪 Testing time-based scheduling for ${adjustedHour.toString().padLeft(2, '0')}:${adjustedMinute.toString().padLeft(2, '0')}',
      );

      // Use the same scheduling logic as daily reminders
      print('⏰ Calculating scheduled time...');
      debugPrint('⏰ Calculating scheduled time...');
      final scheduledTime = _nextInstanceOfTime(adjustedHour, adjustedMinute);
      print('📅 Scheduled time calculated: $scheduledTime');
      debugPrint('📅 Scheduled time calculated: $scheduledTime');

      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('📱 Scheduling notification...');
      debugPrint('📱 Scheduling notification...');

      await _notifications.zonedSchedule(
        666, // Different test notification ID
        'Time-Based Test ⏰',
        'This tests the same logic as daily reminders!',
        scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Remove matchDateTimeComponents to test if this is the issue
        payload: 'time_based_test',
      );

      print('✅ Time-based test notification scheduled successfully!');
      debugPrint('✅ Time-based test notification scheduled successfully!');

      // Verify it was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications after scheduling: ${pending.length}');
      debugPrint(
        '📋 Pending notifications after scheduling: ${pending.length}',
      );

      return true;
    } catch (e) {
      print('❌ Failed to schedule time-based test notification: $e');
      debugPrint('❌ Failed to schedule time-based test notification: $e');
      return false;
    }
  }

  /// Test notification (for debugging)
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      color: Color(0xFF4A55A2),
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Test notification!',
      styleInformation: BigTextStyleInformation(
        'This is a test notification to verify the system is working correctly!',
        contentTitle: 'Test Notification 🧪',
        summaryText: 'Notification System Test',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      sound: 'default',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      'Test Notification 🧪',
      'This is a test notification from Penni!',
      notificationDetails,
      payload: 'test_notification',
    );

    debugPrint('🧪 Test notification sent');
  }
}
