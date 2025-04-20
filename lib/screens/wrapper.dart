import 'package:expense_tracker/components/custom_loader.dart';
import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/screens/authentication/authenticate.dart';
import 'package:expense_tracker/screens/authentication/verify_email.dart';
import 'package:expense_tracker/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (authController.isLoading.value) {
        return const Scaffold(body: Center(child: Loader()));
      }

      final customUser = authController.user.value;
      final firebaseUser = authController.firebaseUser;

      if (customUser == null || firebaseUser == null) {
        return const Authenticate();
      }

      if (!firebaseUser.emailVerified) {
        return const VerifyEmailScreen();
      }

      return const Home();
    });
  }
}
