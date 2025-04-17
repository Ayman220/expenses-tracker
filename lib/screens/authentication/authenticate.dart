import 'package:expense_tracker/screens/authentication/register.dart';
import 'package:expense_tracker/screens/authentication/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Authenticate extends StatelessWidget {
  const Authenticate({super.key});

  @override
  Widget build(BuildContext context) {
    final showSignIn = true.obs;

    return Obx(() => showSignIn.value
        ? SignIn(toggleView: () => showSignIn.toggle())
        : Register(toggleView: () => showSignIn.toggle()));
  }
}