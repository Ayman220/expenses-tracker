import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  app_user.User? _userFromFirebaseUser(User? user) {
    return user != null ? app_user.User(uid: user.uid, name: "") : null;
  }

  // auth change user stream
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in with email/password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  // register with email/password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      // Get the user from FirebaseAuth by uid
      final user = _auth.currentUser;

      // If no user is signed in or the UID does not match, return null
      if (user == null) {
        showErrorMessage("Error", "User not found.");
        return;
      }

      // Check if the email is verified
      if (!user.emailVerified) {
        // Send the email verification again
        await user.sendEmailVerification();
      } else {
        showErrorMessage("Error", "The email is already verified.");
      }
    } catch (_) {}
  }

  // logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      return;
    }
  }
}
