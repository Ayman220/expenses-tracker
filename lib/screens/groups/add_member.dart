import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/components/custom_loader.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMember extends StatefulWidget {
  final String groupId;
  final List<String> existingMembers;

  const AddMember({
    super.key,
    required this.groupId,
    required this.existingMembers,
  });

  @override
  State<AddMember> createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  RxBool isLoading = false.obs;
  String? _errorMessage;

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      // Find user by email
      final usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

      if (usersSnapshot.docs.isEmpty) {
        showErrorMessage("", 'No user found with this email');
        isLoading.value = false;
        return;
      }

      final userDoc = usersSnapshot.docs.first;
      final userId = userDoc.id;

      // Check if user is already in the group
      if (widget.existingMembers.contains(userId)) {
        showErrorMessage('', 'User is already a member of this group');
        isLoading.value = false;
        return;
      }

      // Add user to group
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
            'members': FieldValue.arrayUnion([userId]),
          });

      if (!mounted) return;
      Get.back(result: true); // Return true to indicate success
      showSuccessMessage("Success", "User added successfully");
    } catch (e) {
      showErrorMessage('', 'Error adding member: $e');
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Member'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Obx(() {
          if (isLoading.value) {
            return const Loader(); // Show loading screen when loading is true
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _addMember,
                    child: const Text('Add Member'),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
