import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart';

class AppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of notifications for current user
  Stream<List<AppNotification>> getNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50 notifications
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get count of unread notifications
  Stream<int> getUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedUserId,
    String? relatedData,
  }) async {
    debugPrint('AppNotificationService: Creating notification');
    debugPrint('User ID: $userId');
    debugPrint('Type: ${type.name}');
    debugPrint('Title: $title');
    debugPrint('Message: $message');

    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'relatedUserId': relatedUserId,
        'relatedData': relatedData,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        'AppNotificationService: Notification created with ID: ${docRef.id}',
      );
    } catch (e) {
      debugPrint('AppNotificationService: Error creating notification: $e');
      rethrow;
    }
  }

  /// Create friend request notification
  Future<void> createFriendRequestNotification({
    required String receiverId,
    required String senderName,
    required String senderId,
  }) async {
    debugPrint('AppNotificationService: Creating friend request notification');
    debugPrint('Receiver ID: $receiverId');
    debugPrint('Sender Name: $senderName');
    debugPrint('Sender ID: $senderId');

    try {
      await createNotification(
        userId: receiverId,
        type: NotificationType.friendRequest,
        title: 'New Friend Request',
        message: '$senderName sent you a friend request',
        relatedUserId: senderId,
      );
      debugPrint(
        'AppNotificationService: Friend request notification created successfully',
      );
    } catch (e) {
      debugPrint(
        'AppNotificationService: Error creating friend request notification: $e',
      );
      rethrow;
    }
  }

  /// Create friend request accepted notification
  Future<void> createFriendRequestAcceptedNotification({
    required String senderId,
    required String accepterName,
  }) async {
    await createNotification(
      userId: senderId,
      type: NotificationType.friendRequestAccepted,
      title: 'Friend Request Accepted',
      message: '$accepterName accepted your friend request',
      relatedUserId: senderId,
    );
  }

  /// Create friend request declined notification
  Future<void> createFriendRequestDeclinedNotification({
    required String senderId,
    required String declinerName,
  }) async {
    await createNotification(
      userId: senderId,
      type: NotificationType.friendRequestDeclined,
      title: 'Friend Request Declined',
      message: '$declinerName declined your friend request',
      relatedUserId: senderId,
    );
  }

  /// Create expense reminder notification
  Future<void> createExpenseReminderNotification({
    required String userId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.expenseReminder,
      title: 'Daily Expense Reminder',
      message: 'Don\'t forget to log your daily expenses!',
    );
  }

  /// Create budget alert notification
  Future<void> createBudgetAlertNotification({
    required String userId,
    required String budgetName,
    required double spentAmount,
    required double budgetAmount,
  }) async {
    final percentage = (spentAmount / budgetAmount * 100).round();
    await createNotification(
      userId: userId,
      type: NotificationType.budgetAlert,
      title: 'Budget Alert',
      message: 'You\'ve spent $percentage% of your $budgetName budget',
      relatedData:
          '{"budgetName": "$budgetName", "spentAmount": $spentAmount, "budgetAmount": $budgetAmount}',
    );
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }
}
