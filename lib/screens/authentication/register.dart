import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:expense_tracker/services/database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final authController = Get.find<AuthController>();
  final databaseService = DatabaseService();
  final formKey = GlobalKey<FormState>();
  final loading = false.obs;
  final obscurePassword = true.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {
    if (formKey.currentState!.validate()) {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();

      loading.value = true;
      try {
        await authController
            .registerWithEmailAndPassword(
              nameController.text.trim(),
              emailController.text.trim(),
              passwordController.text,
            );
      } catch (e) {
        if (mounted) {
          showErrorMessage(
            'Error',
            'Failed to register: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          loading.value = false;
        }
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => widget.toggleView(),
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
                Obx(
                  () => TextFormField(
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
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => ElevatedButton(
                    onPressed: loading.value ? null : register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child:
                        loading.value
                            ? const CircularProgressIndicator()
                            : const Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
