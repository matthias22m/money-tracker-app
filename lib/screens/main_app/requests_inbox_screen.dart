import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/friend_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_profile.dart';

class RequestsInboxScreen extends StatelessWidget {
  RequestsInboxScreen({super.key});

  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _friendService.incomingPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No incoming requests'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final senderId = data['senderId'] as String;

              return _buildRequestCard(context, d.id, senderId, data);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    String requestId,
    String senderId,
    Map<String, dynamic> data,
  ) {
    return FutureBuilder<UserProfile?>(
      future: _getSenderProfile(context, senderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              title: const Text('Loading...'),
              subtitle: const Text('Loading sender information'),
            ),
          );
        }

        final profile = snapshot.data;
        final displayName = profile?.name ?? 'Unknown User';
        final username = profile?.username;
        final timestamp = data['timestamp'] as Timestamp?;
        final timeText = timestamp != null
            ? _formatTimestamp(timestamp)
            : 'Recently';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: profile?.hasProfileImage == true
                      ? NetworkImage(profile!.profileImageUrl!)
                      : null,
                  child: profile?.hasProfileImage != true
                      ? Text(
                          profile?.initials ?? 'U',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (username != null)
                        Text(
                          '@$username',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent $timeText',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _friendService.declineRequest(requestId);
                      },
                      tooltip: 'Decline',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _friendService.acceptRequest(requestId);
                      },
                      tooltip: 'Accept',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserProfile?> _getSenderProfile(
    BuildContext context,
    String senderId,
  ) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      final doc = await firebaseService.firestore
          .collection('users')
          .doc(senderId)
          .collection('profile')
          .doc('info')
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sender profile: $e');
      return null;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
