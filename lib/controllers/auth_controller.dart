import 'package:expense_tracker/models/user.dart' as app_user;
import 'package:expense_tracker/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final Rx<app_user.User?> user = Rx<app_user.User?>(null);

  @override
  void onInit() {
    super.onInit();
    _authService.user.listen((userData) {
      user.value = userData;
    });
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _authService.registerWithEmailAndPassword(email, password);
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
} 