import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_notification_service.dart';

class FriendRequestResult {
  final bool success;
  final String message;

  FriendRequestResult({required this.success, required this.message});
}

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppNotificationService _notificationService = AppNotificationService();

  Future<String?> _currentUserId() async {
    return _auth.currentUser?.uid;
  }

  /// Send a friend request to [receiverId]. Prevents duplicates and self-requests.
  /// Returns a result object with success status and error message
  Future<FriendRequestResult> sendFriendRequest({
    required String receiverId,
  }) async {
    try {
      final senderId = await _currentUserId();
      if (senderId == null) {
        debugPrint('sendFriendRequest error: User not authenticated');
        return FriendRequestResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      if (senderId == receiverId) {
        debugPrint('sendFriendRequest error: Cannot send request to self');
        return FriendRequestResult(
          success: false,
          message: 'Cannot send friend request to yourself',
        );
      }

      debugPrint(
        'Checking for existing requests between $senderId and $receiverId',
      );

      // Check for existing request in both directions
      final existingAsSender = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .get();

      final existingAsReceiver = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .get();

      if (existingAsSender.docs.isNotEmpty ||
          existingAsReceiver.docs.isNotEmpty) {
        debugPrint('sendFriendRequest: Request already exists');
        return FriendRequestResult(
          success: false,
          message: 'Friend request already exists',
        );
      }

      debugPrint('Creating new friend request...');
      await _firestore.collection('friendRequests').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get sender's name for notification
      final senderProfile = await _firestore
          .collection('users')
          .doc(senderId)
          .collection('profile')
          .doc('info')
          .get();

      final senderName = senderProfile.data()?['name'] ?? 'Someone';

      // Create notification for receiver
      await _notificationService.createFriendRequestNotification(
        receiverId: receiverId,
        senderName: senderName,
        senderId: senderId,
      );

      debugPrint('Friend request sent successfully');
      return FriendRequestResult(
        success: true,
        message: 'Friend request sent successfully',
      );
    } catch (e) {
      debugPrint('sendFriendRequest error: $e');
      String errorMessage = 'Failed to send friend request';
      if (e.toString().contains('permission-denied')) {
        errorMessage =
            'Permission denied. Please check your account permissions.';
      } else if (e.toString().contains('unavailable')) {
        errorMessage = 'Network unavailable. Please check your connection.';
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('deadline-exceeded')) {
        errorMessage = 'Request timed out. Please try again.';
      }
      return FriendRequestResult(success: false, message: errorMessage);
    }
  }

  /// Stream pending incoming requests for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> incomingPendingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream pending sent requests for current user
  Stream<QuerySnapshot<Map<String, dynamic>>> sentPendingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get count of incoming pending requests
  Stream<int> incomingRequestsCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get count of sent pending requests
  Stream<int> sentRequestsCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Accept a request and add friend to both users' friends lists
  Future<void> acceptRequest(String requestId) async {
    final currentUserId = await _currentUserId();
    if (currentUserId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('friendRequests').doc(requestId);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final senderId = data['senderId'] as String;
    final receiverId = data['receiverId'] as String;

    // Only allow receiver to accept
    if (receiverId != currentUserId) {
      throw Exception('Only the receiver can accept this request');
    }

    try {
      debugPrint(
        'Accepting request: $requestId, sender: $senderId, receiver: $receiverId, currentUser: $currentUserId',
      );

      // First, add sender to receiver's friends list (current user - this should work)
      debugPrint('Adding sender to receiver\'s friends list...');
      final receiverProfile = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('profile')
          .doc('info');

      await receiverProfile.set({
        'friends': FieldValue.arrayUnion([senderId]),
      }, SetOptions(merge: true));
      debugPrint('Sender added to receiver\'s friends list successfully');

      // Then, add receiver to sender's friends list (other user - this might need special handling)
      debugPrint('Adding receiver to sender\'s friends list...');
      final senderProfile = _firestore
          .collection('users')
          .doc(senderId)
          .collection('profile')
          .doc('info');

      await senderProfile.set({
        'friends': FieldValue.arrayUnion([receiverId]),
      }, SetOptions(merge: true));
      debugPrint('Receiver added to sender\'s friends list successfully');

      // Get accepter's name for notification
      final accepterProfile = await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('profile')
          .doc('info')
          .get();

      final accepterName = accepterProfile.data()?['name'] ?? 'Someone';

      // Create notification for sender
      await _notificationService.createFriendRequestAcceptedNotification(
        senderId: senderId,
        accepterName: accepterName,
      );

      // Finally, delete the original request
      debugPrint('Deleting original request...');
      await docRef.delete();
      debugPrint('Original request deleted successfully');

      debugPrint(
        'Friend request accepted successfully - both users added to each other\'s friends lists',
      );
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline removes the friend request document
  Future<void> declineRequest(String requestId) async {
    try {
      // Get request details before deleting
      final docRef = _firestore.collection('friendRequests').doc(requestId);
      final snap = await docRef.get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String;
        final receiverId = data['receiverId'] as String;

        // Get decliner's name for notification
        final declinerProfile = await _firestore
            .collection('users')
            .doc(receiverId)
            .collection('profile')
            .doc('info')
            .get();

        final declinerName = declinerProfile.data()?['name'] ?? 'Someone';

        // Create notification for sender
        await _notificationService.createFriendRequestDeclinedNotification(
          senderId: senderId,
          declinerName: declinerName,
        );
      }

      // Delete the request
      await docRef.delete();
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      rethrow;
    }
  }

  /// Utility: query userIds who are already friends with current user
  Future<List<String>> getFriendUserIds() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .get();
    if (!snap.exists) return [];
    final data = snap.data() as Map<String, dynamic>;
    final List<dynamic>? friends = data['friends'] as List<dynamic>?;
    return friends?.map((e) => e.toString()).toList() ?? [];
  }
}
