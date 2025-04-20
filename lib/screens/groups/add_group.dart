import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    try {
      // 🔍 Check if group with same name already exists for this user
      final existingGroups =
          await FirebaseFirestore.instance
              .collection('groups')
              .where('members', arrayContains: user.uid)
              .where('name', isEqualTo: groupName)
              .get();

      if (existingGroups.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You already have a group named '$groupName'"),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _dbService.createGroup(groupName, user.uid);

      if (!mounted) return;
      showSuccessMessage("", "Group '$groupName' created");
      Get.back();
    } catch (e) {
      if (!mounted) return;
      showErrorMessage("Error", "Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Group'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SingleChildScrollView(
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
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white, // make text white
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Create Group',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
