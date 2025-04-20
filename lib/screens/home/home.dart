import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/components/custom_loader.dart';
import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/controllers/theme_controller.dart';
import 'package:expense_tracker/screens/authentication/reset_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  Stream<QuerySnapshot> _groupStream(String userId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Groups",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => themeController.toggleTheme(),
            tooltip: "Toggle Theme",
            icon: const Icon(Icons.brightness_6_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await authController.signOut();
                } else if (value == 'reset_password') {
                  Get.dialog(const ResetPasswordDialog());
                }
              },
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF2196F3),
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 10),
                          Text('Logout'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Text('Reset Password'),
                    ),
                  ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Loader());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading groups',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.group_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No groups yet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tap + to create one!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final group = docs[index].data() as Map<String, dynamic>;
              final groupId = docs[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.toNamed(
                      '/group-details',
                      arguments: {'groupId': groupId},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${group['members'].length} members',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(128),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-group'),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
