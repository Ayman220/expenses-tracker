import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignIn extends StatelessWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final _formKey = GlobalKey<FormState>();
    final _obscurePassword = true.obs;
    final _loading = false.obs;

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign In"),
        centerTitle: true,
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: () => toggleView(),
            icon: const Icon(Icons.person),
            label: const Text("register"),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  enabled: !_loading.value,
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
                      controller: _passwordController,
                      enabled: !_loading.value,
                      obscureText: _obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => _obscurePassword.toggle(),
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
                      onPressed: _loading.value
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                _loading.value = true;
                                try {
                                  await authController.signInWithEmailAndPassword(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                } finally {
                                  _loading.value = false;
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _loading.value
                          ? const CircularProgressIndicator()
                          : const Text('Sign In'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
