import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationTest {
  /// Test notification functionality
  static Future<void> runNotificationTests() async {
    debugPrint('🧪 Testing Notification System...');
    debugPrint('=' * 50);

    // Test 1: Check if notifications are supported
    await _testNotificationSupport();

    // Test 2: Show test notification
    await _testImmediateNotification();

    // Test 3: Test scheduling (5 seconds from now)
    await _testScheduledNotification();

    // Test 4: Check pending notifications
    await _testPendingNotifications();

    debugPrint('=' * 50);
    debugPrint('🏁 Notification tests completed!');
  }

  /// Test if notifications are supported
  static Future<void> _testNotificationSupport() async {
    debugPrint('📱 Test 1: Checking notification support...');

    try {
      final pending = await NotificationService.getPendingNotifications();
      debugPrint('✅ Notification system is working');
      debugPrint('📊 Pending notifications: ${pending.length}');
    } catch (e) {
      debugPrint('❌ Notification system error: $e');
    }
  }

  /// Test immediate notification
  static Future<void> _testImmediateNotification() async {
    debugPrint('🔔 Test 2: Sending test notification...');

    try {
      await NotificationService.showTestNotification();
      debugPrint('✅ Test notification sent successfully');
      debugPrint('💡 Check your device for the notification');
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
    }
  }

  /// Test scheduled notification (5 seconds from now)
  static Future<void> _testScheduledNotification() async {
    debugPrint('⏰ Test 3: Testing scheduled notification...');

    try {
      final success = await NotificationService.scheduleDailyReminder();

      if (success) {
        debugPrint('✅ Scheduled notification for 9:00 PM');
        debugPrint('⏱️ Daily reminder is now active');
      } else {
        debugPrint('❌ Failed to schedule notification');
      }
    } catch (e) {
      debugPrint('❌ Scheduling error: $e');
    }
  }

  /// Test pending notifications
  static Future<void> _testPendingNotifications() async {
    debugPrint('📋 Test 4: Checking pending notifications...');

    try {
      final pending = await NotificationService.getPendingNotifications();
      debugPrint('📊 Total pending notifications: ${pending.length}');

      for (int i = 0; i < pending.length; i++) {
        final notification = pending[i];
        debugPrint(
          '  ${i + 1}. ID: ${notification.id}, Title: ${notification.title}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications: $e');
    }
  }

  /// Quick test for immediate notification
  static Future<void> quickTest() async {
    debugPrint('⚡ Quick notification test...');
    await NotificationService.showTestNotification();
    debugPrint('✅ Test notification sent!');
  }

  /// Test daily reminder setup
  static Future<void> testDailyReminder() async {
    debugPrint('📅 Testing daily reminder setup...');

    final success = await NotificationService.scheduleDailyReminder();

    if (success) {
      debugPrint('✅ Daily reminder set for 9:00 PM');
      debugPrint(
        '💡 Check your device settings for the scheduled notification',
      );
    } else {
      debugPrint('❌ Failed to set daily reminder');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    debugPrint('🗑️ Cancelling all notifications...');
    await NotificationService.cancelNotifications();
    debugPrint('✅ All notifications cancelled');
  }

  /// Get notification status
  static Future<void> getStatus() async {
    debugPrint('📊 Notification Status Report...');
    debugPrint('=' * 30);

    final pending = await NotificationService.getPendingNotifications();

    debugPrint('⏰ Fixed Reminder Time: 9:00 PM');
    debugPrint('📋 Pending Notifications: ${pending.length}');

    if (pending.isNotEmpty) {
      debugPrint('📝 Scheduled notifications:');
      for (final notification in pending) {
        debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    }
  }
}
