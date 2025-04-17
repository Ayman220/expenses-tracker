import 'package:expense_tracker/controllers/auth_controller.dart';
import 'package:expense_tracker/controllers/theme_controller.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/screens/groups/add_expense.dart';
import 'package:expense_tracker/screens/groups/add_group.dart';
import 'package:expense_tracker/screens/groups/group_details.dart';
import 'package:expense_tracker/screens/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize controllers
  Get.put(ThemeController());
  Get.put(AuthController());

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
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
      themeMode: themeController.themeMode.value,
      home: const Wrapper(),
      getPages: [
        GetPage(name: '/', page: () => const Wrapper()),
        GetPage(name: '/add-group', page: () => const AddGroupScreen()),
        GetPage(
          name: '/group-details',
          page: () => GroupDetails(groupId: Get.arguments['groupId']),
        ),
        GetPage(name: '/add-expense', page: () => const AddExpense()),
      ],
    ));
  }
}
