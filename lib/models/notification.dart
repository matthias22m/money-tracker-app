import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  friendRequestDeclined,
  expenseReminder,
  budgetAlert,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedUserId; // For friend-related notifications
  final String? relatedData; // Additional data (JSON string)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedUserId,
    this.relatedData,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  // Create AppNotification from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      relatedUserId: data['relatedUserId'],
      relatedData: data['relatedData'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert AppNotification to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'relatedUserId': relatedUserId,
      'relatedData': relatedData,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Create a copy of AppNotification with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedUserId,
    String? relatedData,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedData: relatedData ?? this.relatedData,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Get notification icon based on type
  String get icon {
    switch (type) {
      case NotificationType.friendRequest:
        return '👥';
      case NotificationType.friendRequestAccepted:
        return '✅';
      case NotificationType.friendRequestDeclined:
        return '❌';
      case NotificationType.expenseReminder:
        return '💰';
      case NotificationType.budgetAlert:
        return '⚠️';
      case NotificationType.system:
        return '🔔';
    }
  }

  // Get notification color based on type
  String get colorHex {
    switch (type) {
      case NotificationType.friendRequest:
        return '#4A55A2'; // Primary blue
      case NotificationType.friendRequestAccepted:
        return '#4CAF50'; // Green
      case NotificationType.friendRequestDeclined:
        return '#F44336'; // Red
      case NotificationType.expenseReminder:
        return '#FF9800'; // Orange
      case NotificationType.budgetAlert:
        return '#FF5722'; // Deep orange
      case NotificationType.system:
        return '#9E9E9E'; // Grey
    }
  }

  // Format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
