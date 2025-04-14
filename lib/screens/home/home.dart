import 'package:expense_tracker/services/auth.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final VoidCallback toggleTheme;
  const Home({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Groups",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: toggleTheme,
            tooltip: "Toggle Theme",
            icon: const Icon(Icons.brightness_6_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await authService.signOut();
                }
              },
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 20, color: Colors.black),
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
                  ],
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to Expense Groups",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
