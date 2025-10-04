import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_notification_service.dart';
import '../../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppNotificationService _notificationService = AppNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: () async {
                    await _notificationService.markAllAsRead();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Marked $unreadCount notifications as read',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.lato(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.lato(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by rebuilding the stream
              setState(() {});
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up!\nNew notifications will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? null
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    notification.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          notification.timeAgo,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        if (notification.type == NotificationType.friendRequest)
                          _buildActionButtons(notification),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppNotification notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red, size: 18),
          onPressed: () => _handleDeclineFriendRequest(notification),
          tooltip: 'Decline',
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(24, 24),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green, size: 18),
          onPressed: () => _handleAcceptFriendRequest(notification),
          tooltip: 'Accept',
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(24, 24),
          ),
        ),
      ],
    );
  }

  Color _getNotificationColor(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Theme.of(context).colorScheme.primary;
      case NotificationType.friendRequestAccepted:
        return Colors.green;
      case NotificationType.friendRequestDeclined:
        return Colors.red;
      case NotificationType.expenseReminder:
        return Colors.orange;
      case NotificationType.budgetAlert:
        return Colors.deepOrange;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
        // Navigate to friends screen
        Navigator.pushNamed(context, '/friends');
        break;
      case NotificationType.expenseReminder:
        // Navigate to add expense screen
        Navigator.pushNamed(context, '/add-expense');
        break;
      case NotificationType.budgetAlert:
        // Navigate to budget screen
        Navigator.pushNamed(context, '/budget');
        break;
      case NotificationType.system:
        // No specific action
        break;
    }
  }

  void _handleAcceptFriendRequest(AppNotification notification) async {
    // This would need to be implemented with the friend service
    // For now, just mark as read
    await _notificationService.markAsRead(notification.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleDeclineFriendRequest(AppNotification notification) async {
    // This would need to be implemented with the friend service
    // For now, just mark as read
    await _notificationService.markAsRead(notification.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
