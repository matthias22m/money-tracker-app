import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/friend_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_profile.dart';

class RequestsInboxScreen extends StatefulWidget {
  const RequestsInboxScreen({super.key});

  @override
  State<RequestsInboxScreen> createState() => _RequestsInboxScreenState();
}

class _RequestsInboxScreenState extends State<RequestsInboxScreen>
    with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox),
                  const SizedBox(width: 8),
                  const Text('Incoming'),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: _friendService.incomingRequestsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  const Text('Sent'),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: _friendService.sentRequestsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomingRequests(), _buildSentRequests()],
      ),
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No Incoming Requests',
            subtitle: 'You don\'t have any pending friend requests',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final senderId = data['senderId'] as String;

            return _buildIncomingRequestCard(context, d.id, senderId, data);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: docs.length,
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _friendService.sentPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            title: 'No Sent Requests',
            subtitle: 'You haven\'t sent any friend requests yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();
            final receiverId = data['receiverId'] as String;

            return _buildSentRequestCard(context, d.id, receiverId, data);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: docs.length,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              icon,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
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

  Widget _buildIncomingRequestCard(
    BuildContext context,
    String requestId,
    String senderId,
    Map<String, dynamic> data,
  ) {
    return FutureBuilder<UserProfile?>(
      future: _getUserProfile(context, senderId),
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

  Widget _buildSentRequestCard(
    BuildContext context,
    String requestId,
    String receiverId,
    Map<String, dynamic> data,
  ) {
    return FutureBuilder<UserProfile?>(
      future: _getUserProfile(context, receiverId),
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
              subtitle: const Text('Loading receiver information'),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Pending',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserProfile?> _getUserProfile(
    BuildContext context,
    String userId,
  ) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      final doc = await firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
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
