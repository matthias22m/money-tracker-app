import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';
import '../../services/friend_service.dart';
import '../../models/user_profile.dart';
import 'add_friends_screen.dart';
import 'requests_inbox_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friends',
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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendsScreen(),
                ),
              );
            },
            tooltip: 'Add Friends',
          ),
          IconButton(
            icon: const Icon(Icons.inbox),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RequestsInboxScreen()),
              );
            },
            tooltip: 'Friend Requests',
          ),
        ],
      ),
      body: _buildFriendsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFriendsScreen()),
          );
        },
        child: const Icon(Icons.person_add),
        tooltip: 'Add Friends',
      ),
    );
  }

  Widget _buildFriendsList() {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    final currentUserId = firebaseService.auth.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Please log in to view your friends'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firebaseService.firestore
          .collection('users')
          .doc(currentUserId)
          .collection('profile')
          .doc('info')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyState();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final friends = data?['friends'] as List<dynamic>? ?? [];
        final friendIds = friends.map((e) => e.toString()).toList();

        if (friendIds.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force refresh by rebuilding the stream
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friendIds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friendId = friendIds[index];
              return _buildFriendCard(friendId);
            },
          ),
        );
      },
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
              Icons.people_outline,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Friends Yet',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start connecting with friends to share\nand track expenses together',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(String friendId) {
    return FutureBuilder<UserProfile?>(
      future: _getUserProfile(friendId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
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
            ),
          );
        }

        final profile = snapshot.data;
        final displayName = profile?.name ?? 'Unknown User';
        final username = profile?.username;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
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
            title: Text(
              displayName,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: username != null
                ? Text(
                    '@$username',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  )
                : null,
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveFriendDialog(friendId, displayName);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Friend'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserProfile?> _getUserProfile(String userId) async {
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

  void _showRemoveFriendDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Friend',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove $friendName from your friends list?',
          style: GoogleFonts.lato(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friendId);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      final currentUserId = firebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Remove from both users' friends lists
      final currentUserProfile = firebaseService.firestore
          .collection('users')
          .doc(currentUserId)
          .collection('profile')
          .doc('info');

      final friendProfile = firebaseService.firestore
          .collection('users')
          .doc(friendId)
          .collection('profile')
          .doc('info');

      // Use a batch to ensure both operations succeed or both fail
      final batch = firebaseService.firestore.batch();

      // Remove friendId from current user's friends list
      batch.update(currentUserProfile, {
        'friends': FieldValue.arrayRemove([friendId]),
      });

      // Remove currentUserId from friend's friends list
      batch.update(friendProfile, {
        'friends': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Friend removed successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
