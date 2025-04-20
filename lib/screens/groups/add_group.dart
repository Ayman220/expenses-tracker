import 'package:expense_tracker/components/custom_loader.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:expense_tracker/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  RxBool isLoading = false.obs;

  Future<void> _createGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    final groupName = _groupNameController.text.trim();

    if (user == null) return;

    FocusScope.of(context).unfocus(); // Dismiss keyboard

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group name cannot be empty")),
      );
      return;
    }

    isLoading.value = true;

    try {
      await _dbService.createGroup(groupName, user.uid);

      if (!mounted) return;
      Get.back();
      showSuccessMessage("", "Group '$groupName' created");
    } catch (e) {
      if (!mounted) return;
      showErrorMessage("Error", "Error: ${e.toString()}");
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Loader(); // Show loading screen when loading is true
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createGroup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white, // make text white
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Group',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
