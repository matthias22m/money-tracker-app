import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

// Import CloudinaryService
import 'cloudinary_service.dart';

// Import our data models
import '../models/transaction.dart' as model;
import '../models/budget.dart';
import '../models/user_profile.dart';

// Import UserService
import 'user_service.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _secureStorage = const FlutterSecureStorage();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final UserService _userService = UserService();

  FirebaseService()
    : _auth = FirebaseAuth.instance,
      _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Credential caching methods
  Future<void> cacheCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: 'cached_email', value: email);
      await _secureStorage.write(key: 'cached_password', value: password);
      debugPrint('Credentials cached successfully');
    } catch (e) {
      debugPrint('Error caching credentials: $e');
    }
  }

  Future<String?> getCachedEmail() async {
    try {
      return await _secureStorage.read(key: 'cached_email');
    } catch (e) {
      debugPrint('Error getting cached email: $e');
      return null;
    }
  }

  Future<String?> getCachedPassword() async {
    try {
      return await _secureStorage.read(key: 'cached_password');
    } catch (e) {
      debugPrint('Error getting cached password: $e');
      return null;
    }
  }

  Future<void> clearCachedCredentials() async {
    try {
      await _secureStorage.delete(key: 'cached_email');
      await _secureStorage.delete(key: 'cached_password');
      debugPrint('Cached credentials cleared');
    } catch (e) {
      debugPrint('Error clearing cached credentials: $e');
    }
  }

  // Email suggestions methods
  Future<void> saveEmailSuggestion(String email) async {
    try {
      final existingSuggestions = await getEmailSuggestions();
      if (!existingSuggestions.contains(email)) {
        existingSuggestions.add(email);
        // Keep only the last 10 email suggestions
        if (existingSuggestions.length > 10) {
          existingSuggestions.removeAt(0);
        }
        await _secureStorage.write(
          key: 'email_suggestions',
          value: existingSuggestions.join(','),
        );
        debugPrint('Email suggestion saved: $email');
      }
    } catch (e) {
      debugPrint('Error saving email suggestion: $e');
    }
  }

  Future<List<String>> getEmailSuggestions() async {
    try {
      final suggestionsString = await _secureStorage.read(
        key: 'email_suggestions',
      );
      if (suggestionsString != null && suggestionsString.isNotEmpty) {
        return suggestionsString
            .split(',')
            .where((email) => email.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting email suggestions: $e');
      return [];
    }
  }

  // Authentication methods
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Get and store Firebase ID token
    await _storeFirebaseToken();

    // Create default profile
    final user = cred.user;
    if (user != null) {
      await createDefaultProfile(user.uid, email, fullName);

      // Auto-generate and reserve username
      try {
        // Use first name from full name for username generation
        final firstName = fullName.split(' ').first.toLowerCase();
        final suggested = await _userService.generateAvailableUsername(
          base: firstName,
          reserve: true,
          forUserId: user.uid,
        );
        if (suggested != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('profile')
              .doc('info')
              .set({
                'username': suggested,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          debugPrint('✅ Username auto-assigned: $suggested');
        } else {
          // Fallback: try with a generic base if email-based generation failed
          debugPrint(
            '⚠️ Failed to generate username with email base, trying generic...',
          );
          final fallbackSuggested = await _userService
              .generateAvailableUsername(
                base: 'user',
                reserve: true,
                forUserId: user.uid,
              );
          if (fallbackSuggested != null) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('profile')
                .doc('info')
                .set({
                  'username': fallbackSuggested,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            debugPrint('✅ Fallback username assigned: $fallbackSuggested');
          } else {
            debugPrint(
              '❌ Failed to generate any username for user: ${user.uid}',
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Failed to auto-assign username: $e');
        // Try one more time with a completely random username
        try {
          final emergencyUsername = await _userService
              .generateAvailableUsername(
                base: null, // No base, completely random
                reserve: true,
                forUserId: user.uid,
              );
          if (emergencyUsername != null) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('profile')
                .doc('info')
                .set({
                  'username': emergencyUsername,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            debugPrint('✅ Emergency username assigned: $emergencyUsername');
          }
        } catch (emergencyError) {
          debugPrint(
            '❌ Emergency username generation also failed: $emergencyError',
          );
        }
      }
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    // Get and store Firebase ID token
    await _storeFirebaseToken();
  }

  // Store Firebase ID token securely
  Future<void> _storeFirebaseToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);

        await _secureStorage.write(key: 'auth_token', value: token);
      }
    } catch (e) {
      debugPrint('❌ Failed to store Firebase token: $e');
    }
  }

  // Refresh Firebase token
  Future<void> refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true); // Force refresh
        await _secureStorage.write(key: 'auth_token', value: token);
        debugPrint('🔄 Firebase token refreshed');
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh Firebase token: $e');
    }
  }

  // Get current Firebase token
  Future<String?> getCurrentToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('❌ Failed to get Firebase token: $e');
    }
    return null;
  }

  // Password reset method
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('📧 Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Failed to send password reset email: $e');
      rethrow;
    }
  }

  // Sign out and clear tokens
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _secureStorage.delete(key: 'auth_token');
      debugPrint('🔓 User signed out, tokens cleared');
    } catch (e) {
      debugPrint('❌ Failed to sign out: $e');
    }
  }

  // Method to get a real-time stream of transactions for the current user
  Stream<List<model.Transaction>> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Reference to the user's transactions collection
    final transactionsCollection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true); // Order by date descending

    // Stream a list of Transaction objects
    return transactionsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => model.Transaction.fromFirestore(doc))
          .toList();
    });
  }

  // Method to add a new transaction
  Future<void> addTransaction(model.Transaction transaction) async {
    final user = _auth.currentUser;
    debugPrint('User: $user');
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add(transaction.toFirestore());
  }

  // Method to delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // Method to update a transaction
  Future<void> updateTransaction(
    String transactionId,
    model.Transaction transaction,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transactionId)
        .update(transaction.toFirestore());
  }

  // Helper method to add a test transaction (for demonstration)
  Future<void> addTestTransaction() async {
    final testTransaction = model.Transaction(
      id: '', // Will be auto-generated by Firestore
      title: 'Test Transaction',
      amount: 25.50,
      date: DateTime.now(),
      category: 'Food',
      isExpense: true,
    );
    await addTransaction(testTransaction);
  }

  // Budget Management Methods

  // Get budget for a specific month and year
  Future<Budget?> getBudget(int year, int month) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc('${year}_$month')
          .get();

      if (doc.exists) {
        return Budget.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting budget: $e');
      rethrow;
    }
  }

  // Set budget for a specific month and year
  Future<void> setBudget(double amount, int year, int month) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();
      final budget = Budget(
        id: '${year}_$month',
        amount: amount,
        year: year,
        month: month,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc('${year}_$month')
          .set(budget.toMap());

      debugPrint('Budget set successfully');
    } catch (e) {
      debugPrint('Error setting budget: $e');
      rethrow;
    }
  }

  // Get current month's budget
  Future<Budget?> getCurrentBudget() async {
    final now = DateTime.now();
    return await getBudget(now.year, now.month);
  }

  // Set current month's budget
  Future<void> setCurrentBudget(double amount) async {
    final now = DateTime.now();
    return await setBudget(amount, now.year, now.month);
  }

  // Get stream of current month's budget
  Stream<Budget?> getCurrentBudgetStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc('${now.year}_${now.month}')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return Budget.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Get stream of all budgets for history
  Stream<List<Budget>> getBudgetHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Budget.fromMap(doc.data()))
              .toList();
        });
  }

  // Calculate total expenses for current month
  Future<double> getCurrentMonthExpenses() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('isExpense', isEqualTo: true)
          .get();

      double totalExpenses = 0.0;
      for (var doc in querySnapshot.docs) {
        totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
      }

      return totalExpenses;
    } catch (e) {
      debugPrint('Error getting current month expenses: $e');
      rethrow;
    }
  }

  // Get stream of current month expenses
  Stream<double> getCurrentMonthExpensesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .where('isExpense', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          double totalExpenses = 0.0;
          for (var doc in snapshot.docs) {
            totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
          }
          return totalExpenses;
        });
  }

  // Get previous month's expenses
  Future<double> getPreviousMonthExpenses() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();
      final previousMonth = now.month == 1 ? 12 : now.month - 1;
      final previousYear = now.month == 1 ? now.year - 1 : now.year;

      final startOfPreviousMonth = DateTime(previousYear, previousMonth, 1);
      final endOfPreviousMonth = DateTime(
        previousYear,
        previousMonth + 1,
        0,
        23,
        59,
        59,
      );

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPreviousMonth),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfPreviousMonth),
          )
          .where('isExpense', isEqualTo: true)
          .get();

      double totalExpenses = 0.0;
      for (var doc in querySnapshot.docs) {
        totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
      }

      return totalExpenses;
    } catch (e) {
      debugPrint('Error getting previous month expenses: $e');
      rethrow;
    }
  }

  // Get stream combining current and previous month expenses for comparison
  Stream<Map<String, double>> getMonthlyComparisonStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();

    // Current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Previous month
    final previousMonth = now.month == 1 ? 12 : now.month - 1;
    final previousYear = now.month == 1 ? now.year - 1 : now.year;
    final startOfPreviousMonth = DateTime(previousYear, previousMonth, 1);
    final endOfPreviousMonth = DateTime(
      previousYear,
      previousMonth + 1,
      0,
      23,
      59,
      59,
    );

    // Get current month expenses
    final currentMonthStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .where('isExpense', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          double totalExpenses = 0.0;
          for (var doc in snapshot.docs) {
            totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
          }
          return totalExpenses;
        });

    // Get previous month expenses
    final previousMonthStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPreviousMonth),
        )
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfPreviousMonth),
        )
        .where('isExpense', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          double totalExpenses = 0.0;
          for (var doc in snapshot.docs) {
            totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
          }
          return totalExpenses;
        });

    // Combine both streams using async generator
    await for (final currentMonth in currentMonthStream) {
      await for (final previousMonth in previousMonthStream.take(1)) {
        yield {'current': currentMonth, 'previous': previousMonth};
      }
    }
  }

  // Profile Management Methods

  /// Get the current user's profile stream
  Stream<UserProfile?> getProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('info')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserProfile.fromFirestore(snapshot);
          }
          return null;
        });
  }

  /// Add or update user profile
  Future<void> addOrUpdateProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .set(profile.toFirestore(), SetOptions(merge: true));

      debugPrint('✅ Profile saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save profile: $e');
      rethrow;
    }
  }

  /// Upload profile image to Cloudinary
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check if Cloudinary is configured
      if (!CloudinaryService.isConfigured()) {
        throw Exception(
          'Cloudinary not configured. Please set up your Cloudinary credentials.',
        );
      }

      debugPrint('📤 Uploading profile image to Cloudinary...');

      // Upload to Cloudinary with user-specific folder
      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder: 'profile_images/${user.uid}',
      );

      debugPrint(
        '✅ Profile image uploaded successfully to Cloudinary: $imageUrl',
      );
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Failed to upload profile image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Delete profile image from Cloudinary
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        debugPrint('⚠️ No image URL provided for deletion');
        return;
      }

      debugPrint('🗑️ Deleting profile image: $imageUrl');

      // Check if it's a Cloudinary URL
      if (imageUrl.contains('cloudinary.com')) {
        await _cloudinaryService.deleteImage(imageUrl);
        debugPrint('✅ Profile image deleted from Cloudinary');
      } else {
        debugPrint('⚠️ Non-Cloudinary URL detected - deletion not supported');
        debugPrint('🔍 URL: $imageUrl');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete profile image: $e');
      // Don't rethrow for deletion failures - it's not critical
      debugPrint('⚠️ Continuing without deleting the image file');
    }
  }

  /// Create a default profile for new users
  Future<UserProfile> createDefaultProfile(
    String userId,
    String email,
    String name,
  ) async {
    final now = DateTime.now();
    final defaultProfile = UserProfile(
      id: userId,
      name: name,
      email: email,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('info')
        .set(defaultProfile.toFirestore());

    debugPrint('✅ Default profile created for user: $userId');
    return defaultProfile;
  }

  // Username Management Methods

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    return await _userService.isUsernameAvailable(username);
  }

  /// Get user ID by username with retry logic
  Future<String?> getUserIdByUsername(String username) async {
    return await _retryOperation(
      () => _userService.getUserIdByUsername(username),
    );
  }

  /// Ensure current user has a username, generate one if missing
  Future<String?> ensureUserHasUsername() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already has a username
      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data();
        final existingUsername = data?['username'] as String?;
        if (existingUsername != null && existingUsername.isNotEmpty) {
          debugPrint('✅ User already has username: $existingUsername');
          return existingUsername;
        }
      }

      // Generate a new username
      debugPrint('🔄 User missing username, generating one...');
      final email = user.email ?? '';
      final inferredName = email.split('@').first;

      final suggested = await _userService.generateAvailableUsername(
        base: inferredName.isNotEmpty ? inferredName : 'user',
        reserve: true,
        forUserId: user.uid,
      );

      if (suggested != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('info')
            .set({
              'username': suggested,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        debugPrint('✅ Username assigned to existing user: $suggested');
        return suggested;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error ensuring user has username: $e');
      return null;
    }
  }

  /// Set username for current user
  Future<bool> setUsername(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if username is available
      if (!await _userService.isUsernameAvailable(username)) {
        return false;
      }

      // Reserve the username
      final success = await _userService.reserveUsername(username, user.uid);
      if (!success) {
        return false;
      }

      // Update user profile with username
      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .get();

      if (profileDoc.exists) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('info')
            .update({
              'username': username.toLowerCase().trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      debugPrint('✅ Username set successfully: $username');
      return true;
    } catch (e) {
      debugPrint('❌ Error setting username: $e');
      return false;
    }
  }

  /// Update username for current user
  Future<bool> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current profile to find existing username
      final profileDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .get();

      if (!profileDoc.exists) {
        throw Exception('User profile not found');
      }

      final currentData = profileDoc.data()!;
      final currentUsername = currentData['username'] as String? ?? '';

      // Update username using UserService
      final success = await _userService.updateUsername(
        currentUsername,
        newUsername,
        user.uid,
      );

      if (!success) {
        return false;
      }

      // Update user profile with new username
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .update({
            'username': newUsername.toLowerCase().trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('✅ Username updated successfully: $newUsername');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating username: $e');
      return false;
    }
  }

  /// Get username validation error message
  String? getUsernameValidationError(String username) {
    return _userService.getUsernameValidationError(username);
  }

  /// Retry operation with exponential backoff for transient errors
  Future<T?> _retryOperation<T>(
    Future<T?> Function() operation, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final isRetryableError =
            e.toString().contains('unavailable') ||
            e.toString().contains('deadline-exceeded') ||
            e.toString().contains('internal') ||
            e.toString().contains('timeout');

        if (attempt >= maxRetries || !isRetryableError) {
          debugPrint('❌ Operation failed after $attempt attempts: $e');
          rethrow;
        }

        // Exponential backoff: 500ms, 1s, 2s
        final delayMs = 500 * (1 << (attempt - 1));
        debugPrint(
          '⚠️ Retrying operation in ${delayMs}ms (attempt $attempt/$maxRetries)',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return null;
  }
}
