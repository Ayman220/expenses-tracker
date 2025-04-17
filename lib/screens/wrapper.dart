import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/screens/authentication/authenticate.dart';
import 'package:expense_tracker/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() => authController.user.value == null
        ? const Authenticate()
        : const Home());
  }
}
