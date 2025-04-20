import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:expense_tracker/screens/home/home.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final authController = Get.find<AuthController>();
  final resendCooldown = 0.obs;
  Timer? _timer;

  Future<void> resendVerificationEmail() async {
    try {
      await authController.resendVerificationEmail();
      showSuccessMessage('Email Sent', 'Verification email has been resent.');
    } catch (e) {
      showErrorMessage('Error', 'Failed to send verification email.');
    } finally {
      startCooldown();
    }
  }

  void startCooldown() {
    resendCooldown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: authController.emailVerificationStream(),
      builder: (context, snapshot) {
        final isVerified = snapshot.data ?? false;

        if (isVerified) {
          // Automatically navigate to Home once verified
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAll(() => const Home());
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Verify Email"),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await authController.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'A verification link has been sent to your email address. '
                  'Please verify your email to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                Obx(
                  () => ElevatedButton.icon(
                    onPressed: resendCooldown.value == 0
                        ? resendVerificationEmail
                        : null,
                    icon: resendCooldown.value == 0
                        ? const Icon(Icons.refresh)
                        : null,
                    label: Text(
                      resendCooldown.value != 0
                          ? 'Wait ${resendCooldown.value} seconds to resend'
                          : 'Resend Email',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
