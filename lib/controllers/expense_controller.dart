import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseController extends GetxController {
  late final ExpenseService _expenseService;
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  Map<String, String>? selectedPayer;
  String? payerError;
  Map<String, double> splits = {};
  String splitType = 'equal';

  @override
  void onInit() {
    super.onInit();
    _expenseService = Get.find<ExpenseService>();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }

  void addExpense(String groupId) {
    if (!formKey.currentState!.validate()) return;
    
    if (selectedPayer == null) {
      payerError = 'Please select who paid';
      update();
      return;
    }

    final amount = double.parse(amountController.text);
    final members = Get.arguments['members'] as List<Map<String, String>>;

    // If splits are empty or equal split is selected, calculate equal splits
    if (splits.isEmpty || splitType == 'equal') {
      final share = amount / members.length;
      splits = {
        for (final member in members)
          member['uid']!: share,
      };
    } else if (splitType == 'unequal') {
      // Normalize the amounts to match the total expense
      final total = splits.values.fold(0.0, (sum, value) => sum + value);
      if (total > 0) {
        final factor = amount / total;
        splits = {
          for (final entry in splits.entries)
            entry.key: entry.value * factor,
        };
      }
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      description: descriptionController.text,
      amount: amount,
      paidBy: selectedPayer!['uid']!,
      paidByName: selectedPayer!['name']!,
      createdAt: DateTime.now(),
      splits: splits,
      splitType: splitType,
    );

    _expenseService.addExpense(expense);
    Get.back();
  }
} 