import 'package:expense_tracker/models/user.dart' as app_user;
import 'package:expense_tracker/screens/authentication/authenticate.dart';
import 'package:expense_tracker/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  final VoidCallback toggleTheme;
  const Wrapper({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final app_user.User? user = Provider.of<app_user.User?>(context);

    // Return either Home or Authenticate widget
    return user == null ? Authenticate() : Home(toggleTheme: toggleTheme,);
  }
}
