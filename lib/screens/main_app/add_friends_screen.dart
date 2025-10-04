import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_service.dart';
import '../../services/friend_service.dart';
import '../../models/user_profile.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final _controller = TextEditingController();
  String? _foundUserId;
  UserProfile? _foundUserProfile;
  bool _isSearching = false;
  bool _sending = false;
  final FriendService _friendService = FriendService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _foundUserId = null;
      _foundUserProfile = null;
    });
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      String? userId;

      if (query.contains('@')) {
        // Email search not yet implemented; prioritize username search per milestone
      }

      userId ??= await firebaseService.getUserIdByUsername(query);

      // If user found, get their profile
      UserProfile? userProfile;
      if (userId != null) {
        final doc = await firebaseService.firestore
            .collection('users')
            .doc(userId)
            .collection('profile')
            .doc('info')
            .get();

        if (doc.exists) {
          userProfile = UserProfile.fromFirestore(doc);
        }
      }

      setState(() {
        _foundUserId = userId;
        _foundUserProfile = userProfile;
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Search failed';
        if (e.toString().contains('unavailable')) {
          errorMessage =
              'Network unavailable. Please check your connection and try again.';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('deadline-exceeded')) {
          errorMessage = 'Search timed out. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _search,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (_foundUserId == null) return;
    setState(() => _sending = true);

    try {
      final result = await _friendService.sendFriendRequest(
        receiverId: _foundUserId!,
      );

      setState(() => _sending = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          action: !result.success && result.message.contains('try again')
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _sendRequest,
                )
              : null,
        ),
      );

      // Clear the search if successful
      if (result.success) {
        _controller.clear();
        setState(() {
          _foundUserId = null;
          _foundUserProfile = null;
        });
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error in _sendRequest: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friends')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search by @username or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _foundUserId = null;
                      _foundUserProfile = null;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _search,
                child: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 24),
            if (_foundUserId != null && _foundUserProfile != null)
              Card(
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
                        backgroundImage: _foundUserProfile!.hasProfileImage
                            ? NetworkImage(_foundUserProfile!.profileImageUrl!)
                            : null,
                        child: !_foundUserProfile!.hasProfileImage
                            ? Text(
                                _foundUserProfile!.initials,
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
                              _foundUserProfile!.name,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (_foundUserProfile!.username != null)
                              Text(
                                '@${_foundUserProfile!.username!}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _sending ? null : _sendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Send Request',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_foundUserId != null && _foundUserProfile == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'User found but profile not available',
                    style: GoogleFonts.lato(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
