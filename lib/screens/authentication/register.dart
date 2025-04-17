import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Register extends StatelessWidget {
  final Function toggleView;
  const Register({super.key, required this.toggleView});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final databaseService = DatabaseService();
    final formKey = GlobalKey<FormState>();
    final loading = false.obs;
    final obscurePassword = true.obs;

    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Future<void> register() async {
      if (formKey.currentState!.validate()) {
        loading.value = true;
        try {
          final UserCredential? result = await authController.registerWithEmailAndPassword(
            emailController.text.trim(),
            passwordController.text,
          );

          if (result != null) {
            // Create user profile in Firestore
            await databaseService.createUser(
              nameController.text.trim(),
              emailController.text.trim(),
              result.user!.uid,
            );
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to register: $e');
        } finally {
          loading.value = false;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => toggleView(),
            icon: const Icon(Icons.person),
            label: const Text("sign in"),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  enabled: !loading.value,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  enabled: !loading.value,
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
                Obx(() => TextFormField(
                      controller: passwordController,
                      enabled: !loading.value,
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
                    )),
                const SizedBox(height: 20),
                Obx(() => ElevatedButton(
                      onPressed: loading.value ? null : register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: loading.value
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
