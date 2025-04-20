import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:expense_tracker/models/user.dart' as app_user;
import 'package:expense_tracker/services/auth.dart';
import 'package:expense_tracker/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final Rx<app_user.User?> user = Rx<app_user.User?>(null);
  User? get firebaseUser => FirebaseAuth.instance.currentUser;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen for changes in the Firebase Authentication state
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        // If the user is signed in, fetch the user data and update
        await firebaseUser.reload();
        user.value = app_user.User(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          emailVerified: firebaseUser.emailVerified,
          balance: 0.0,
        );
      } else {
        // If the user is signed out, set the local user to null
        user.value = null;
      }
      isLoading.value = false;
    });
  }

  Stream<bool> emailVerificationStream({
    Duration checkInterval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      yield user?.emailVerified ?? false;

      if (user?.emailVerified == true) break;
      await Future.delayed(checkInterval);
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
      );
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      await _databaseService.createUser(name, email, userCredential.user!.uid);
      // send email verification
      await userCredential.user?.sendEmailVerification();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return null;
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
      );
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      user.value = null;
    } on FirebaseAuthException catch (e) {
      showErrorMessage('Error', 'Failed to sign out: ${e.message}');
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
    } on FirebaseAuthException catch (e) {
      showErrorMessage('Error', 'Failed to resend link: ${e.message}');
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Utility function to handle common FirebaseAuth exceptions
  void _handleAuthException(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      showErrorMessage('Error', 'The password provided is too weak.');
    } else if (e.code == 'email-already-in-use') {
      showErrorMessage('Error', 'The account already exists for that email.');
    } else if (e.code == 'invalid-email') {
      showErrorMessage('Error', 'The email address is not valid.');
    } else {
      showErrorMessage('Error', 'An unexpected error occurred: ${e.message}');
    }
  }
}
