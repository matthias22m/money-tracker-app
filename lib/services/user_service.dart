import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a username is available (not taken)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Validate username format
      if (!_isValidUsername(normalizedUsername)) {
        return false;
      }

      final doc = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get();

      return !doc.exists;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  /// Generate a random available username and (optionally) reserve it
  /// If [base] is provided, it will be used as a prefix.
  Future<String?> generateAvailableUsername({
    String? base,
    bool reserve = false,
    required String forUserId,
  }) async {
    final normalizedBase = (base ?? '').toLowerCase().trim();

    // Pools
    final adjectives = [
      'swift',
      'calm',
      'brave',
      'bright',
      'bold',
      'clever',
      'eager',
      'gentle',
      'happy',
      'kind',
      'lucky',
      'mighty',
      'noble',
      'quick',
      'quiet',
      'rapid',
      'sharp',
      'smart',
      'solid',
      'spry',
    ];
    final nouns = [
      'falcon',
      'otter',
      'tiger',
      'lynx',
      'eagle',
      'panda',
      'wolf',
      'fox',
      'raven',
      'lion',
      'bear',
      'shark',
      'whale',
      'koala',
      'yak',
      'horse',
      'owl',
      'hawk',
      'orca',
      'crane',
    ];

    final rand = Random();

    // Try base first if provided
    final List<String> candidates = [];
    if (normalizedBase.isNotEmpty) {
      candidates.addAll([
        normalizedBase,
        '${normalizedBase}${rand.nextInt(899) + 100}',
        '${normalizedBase}_${rand.nextInt(899) + 100}',
      ]);
    }

    // Then try random adjective+noun combos with numbers
    for (int i = 0; i < 25; i++) {
      final candidate =
          '${adjectives[rand.nextInt(adjectives.length)]}'
          '_${nouns[rand.nextInt(nouns.length)]}${rand.nextInt(9999).toString().padLeft(3, '0')}';
      candidates.add(candidate);
    }

    for (final candidate in candidates) {
      if (_isValidUsername(candidate) && await isUsernameAvailable(candidate)) {
        if (reserve) {
          final ok = await reserveUsername(candidate, forUserId);
          if (!ok) {
            continue; // race, try next
          }
        }
        return candidate;
      }
    }

    return null; // no available username found
  }

  /// Get user ID by username
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      final doc = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get();

      if (doc.exists) {
        return doc.data()?['userId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user ID by username: $e');
      rethrow; // Let FirebaseService handle retry
    }
  }

  /// Reserve a username for a user (create username document)
  Future<bool> reserveUsername(String username, String userId) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Validate username format
      if (!_isValidUsername(normalizedUsername)) {
        return false;
      }

      // Check if username is already taken
      if (!await isUsernameAvailable(normalizedUsername)) {
        return false;
      }

      // Create the username document
      await _firestore.collection('usernames').doc(normalizedUsername).set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Username reserved: $normalizedUsername for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error reserving username: $e');
      return false;
    }
  }

  /// Release a username (delete username document)
  Future<bool> releaseUsername(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      await _firestore.collection('usernames').doc(normalizedUsername).delete();

      debugPrint('✅ Username released: $normalizedUsername');
      return true;
    } catch (e) {
      debugPrint('❌ Error releasing username: $e');
      return false;
    }
  }

  /// Update username (release old, reserve new)
  Future<bool> updateUsername(
    String oldUsername,
    String newUsername,
    String userId,
  ) async {
    try {
      final normalizedOldUsername = oldUsername.toLowerCase().trim();
      final normalizedNewUsername = newUsername.toLowerCase().trim();

      // If usernames are the same, no update needed
      if (normalizedOldUsername == normalizedNewUsername) {
        return true;
      }

      // Validate new username format
      if (!_isValidUsername(normalizedNewUsername)) {
        return false;
      }

      // Check if new username is available
      if (!await isUsernameAvailable(normalizedNewUsername)) {
        return false;
      }

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Delete old username document
      if (normalizedOldUsername.isNotEmpty) {
        batch.delete(
          _firestore.collection('usernames').doc(normalizedOldUsername),
        );
      }

      // Create new username document
      batch.set(_firestore.collection('usernames').doc(normalizedNewUsername), {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint(
        '✅ Username updated from $normalizedOldUsername to $normalizedNewUsername',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error updating username: $e');
      return false;
    }
  }

  /// Validate username format
  bool _isValidUsername(String username) {
    if (username.isEmpty || username.length < 3 || username.length > 20) {
      return false;
    }

    // Username can only contain letters, numbers, underscores, and hyphens
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(username)) {
      return false;
    }

    // Username cannot start or end with underscore or hyphen
    if (username.startsWith('_') ||
        username.startsWith('-') ||
        username.endsWith('_') ||
        username.endsWith('-')) {
      return false;
    }

    // Username cannot contain consecutive underscores or hyphens
    if (username.contains('__') ||
        username.contains('--') ||
        username.contains('_-') ||
        username.contains('-_')) {
      return false;
    }

    return true;
  }

  /// Get username validation error message
  String? getUsernameValidationError(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.length > 20) {
      return 'Username must be no more than 20 characters long';
    }

    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    if (username.startsWith('_') ||
        username.startsWith('-') ||
        username.endsWith('_') ||
        username.endsWith('-')) {
      return 'Username cannot start or end with underscore or hyphen';
    }

    if (username.contains('__') ||
        username.contains('--') ||
        username.contains('_-') ||
        username.contains('-_')) {
      return 'Username cannot contain consecutive underscores or hyphens';
    }

    return null;
  }
}
