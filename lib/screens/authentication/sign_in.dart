import 'package:expense_tracker/components/custom_loader.dart';
import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/screens/authentication/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final authController = Get.find<AuthController>();
  final formKey = GlobalKey<FormState>();
  final loading = false.obs;
  final obscurePassword = true.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => widget.toggleView(),
            icon: const Icon(Icons.person),
            label: const Text("register"),
          ),
        ],
      ),
      body: Obx(() {
        if (loading.value) {
          return const Loader(); // Show loading screen when loading is true
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController,
                    enabled: !loading.value, // Disable input when loading
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                      final regex = RegExp(pattern);

                      if (val == null || val.isEmpty) {
                        return 'Enter your email';
                      } else if (!regex.hasMatch(val)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => TextFormField(
                      controller: passwordController,
                      enabled: !loading.value, // Disable input when loading
                      obscureText: obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => obscurePassword.toggle(),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter your password';
                        } else if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        loading.value
                            ? null
                            : () async {
                              FocusScope.of(context).unfocus();
                              if (formKey.currentState!.validate()) {
                                loading.value = true;
                                try {
                                  await authController
                                      .signInWithEmailAndPassword(
                                        emailController.text,
                                        passwordController.text,
                                      );
                                } finally {
                                  loading.value =
                                      false; // Turn off loading once done
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Sign In'),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.dialog(const ResetPasswordDialog());
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
