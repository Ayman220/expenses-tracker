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

  @override
  void onInit() {
    super.onInit();
    _authService.user.listen((userData) {
      user.value = userData;
    });
  }

Future<UserCredential?> signInWithEmailAndPassword(
  String email,
  String password,
) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      showErrorMessage('Error', 'No user found with that email.');
    } else if (e.code == 'wrong-password') {
      showErrorMessage('Error', 'Incorrect password. Please try again.');
    } else if (e.code == 'invalid-email') {
      showErrorMessage('Error', 'Please enter a valid email address.');
    } else if (e.code == 'user-disabled') {
      showErrorMessage('Error', 'This account has been disabled.');
    } else if (e.code == 'too-many-requests') {
      showErrorMessage('Error', 'Too many failed attempts. Please try again later.');
    } else {
      showErrorMessage('Error', e.message ?? 'Something went wrong! please try again later'); // Generic message
    }
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
          await _databaseService.createUser(
            name,
            email,
            userCredential.user!.uid,
          );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showErrorMessage('Error', 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showErrorMessage('Error', 'The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        showErrorMessage('Error', 'The email address is not valid.');
      } else {
        showErrorMessage('Error', 'An unexpected error occurred: ${e.message}');
      }
      return null;
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error.... occurred: ${e.toString()}',
      );
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (e) {
      showErrorMessage('Error', 'Failed to sign out: ${e.message}');
    } catch (e) {
      showErrorMessage(
        'Error',
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}
