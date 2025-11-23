import 'package:firebase_auth/firebase_auth.dart';

String mapFirebaseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No account found for that email. Please sign up.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'invalid-credential':
      return 'The email or password you entered is incorrect.';
    case 'email-already-in-use':
      return 'This email is already registered. Please sign in.';
    case 'weak-password':
      return 'The password is too weak. Please use at least 6 characters.';
    case 'user-disabled':
      return 'This user account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled. Please contact support.';
    case 'requires-recent-login':
      return 'This action requires a recent login. Please sign out and sign in again.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}
