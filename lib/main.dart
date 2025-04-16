import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/screens/groups/add_expense.dart';
import 'package:expense_tracker/screens/groups/add_group.dart';
import 'package:expense_tracker/screens/groups/group_details.dart';
import 'package:expense_tracker/screens/wrapper.dart';
import 'package:expense_tracker/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user.dart' as app_user;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  ExpenseTrackerAppState createState() => ExpenseTrackerAppState();
}

class ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<app_user.User?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode, // Use the current theme mode
        home: Wrapper(toggleTheme: _toggleTheme),
        routes: {
          '/add-group': (context) => const AddGroupScreen(),

          '/group-details': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return GroupDetails(groupId: args['groupId'] as String);
          },

          '/add-expense': (context) => const AddExpense(),
        },
      ),
    );
  }
}
