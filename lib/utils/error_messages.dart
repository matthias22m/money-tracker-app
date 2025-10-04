import 'package:flutter/material.dart';

class ErrorMessages {
  // Common error patterns and their human-readable messages
  static const Map<String, String> _errorPatterns = {
    // Authentication errors
    'email-already-in-use':
        'This email is already registered. Please try signing in instead.',
    'user-not-found':
        'No account found with this email address. Please check your email or create a new account.',
    'wrong-password':
        'Incorrect password. Please try again or reset your password.',
    'invalid-email': 'Please enter a valid email address.',
    'user-disabled':
        'This account has been disabled. Please contact support for assistance.',
    'weak-password':
        'Password is too weak. Please choose a stronger password with at least 6 characters.',
    'too-many-requests':
        'Too many failed attempts. Please wait a moment and try again.',
    'operation-not-allowed':
        'This sign-in method is not enabled. Please contact support.',
    'invalid-credential':
        'Invalid login credentials. Please check your email and password.',
    'credential-already-in-use':
        'This account is already linked to another user.',
    'requires-recent-login': 'Please sign in again to complete this action.',

    // Network errors
    'network-request-failed':
        'Network connection failed. Please check your internet connection and try again.',
    'timeout': 'Request timed out. Please check your connection and try again.',
    'unavailable':
        'Service is temporarily unavailable. Please try again later.',
    'deadline-exceeded': 'Request timed out. Please try again.',

    // Firebase/Firestore errors
    'permission-denied': 'You don\'t have permission to perform this action.',
    'unauthenticated': 'Please sign in to continue.',
    'not-found': 'The requested resource was not found.',
    'already-exists': 'This item already exists.',
    'failed-precondition': 'The operation failed due to a precondition.',
    'aborted': 'The operation was aborted. Please try again.',
    'out-of-range': 'The value is out of range.',
    'unimplemented': 'This feature is not yet implemented.',
    'internal': 'An internal error occurred. Please try again later.',
    'data-loss': 'Data was lost during the operation. Please try again.',
  };

  /// Get a human-readable error message from an exception
  static String getHumanReadableError(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final errorString = error.toString().toLowerCase();

    // Check for specific error patterns
    for (final pattern in _errorPatterns.keys) {
      if (errorString.contains(pattern)) {
        return _errorPatterns[pattern]!;
      }
    }

    // Check for common Firebase error codes
    if (errorString.contains('firebase')) {
      if (errorString.contains('auth/')) {
        final authError = errorString.split('auth/').last.split(']').first;
        return _getAuthErrorMessage(authError);
      }
      if (errorString.contains('firestore/')) {
        final firestoreError = errorString
            .split('firestore/')
            .last
            .split(']')
            .first;
        return _getFirestoreErrorMessage(firestoreError);
      }
    }

    // Check for network-related errors
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Check for timeout errors
    if (errorString.contains('timeout') || errorString.contains('deadline')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Get specific authentication error messages
  static String _getAuthErrorMessage(String authError) {
    switch (authError) {
      case 'email-already-in-use':
        return 'This email is already registered. Please try signing in instead.';
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'credential-already-in-use':
        return 'This account is already linked to another user.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication failed. Please check your credentials and try again.';
    }
  }

  /// Get specific Firestore error messages
  static String _getFirestoreErrorMessage(String firestoreError) {
    switch (firestoreError) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'failed-precondition':
        return 'The operation failed due to a precondition.';
      case 'aborted':
        return 'The operation was aborted. Please try again.';
      case 'out-of-range':
        return 'The value is out of range.';
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'data-loss':
        return 'Data was lost during the operation. Please try again.';
      default:
        return 'Database operation failed. Please try again.';
    }
  }

  /// Show a user-friendly error snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getHumanReadableError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
