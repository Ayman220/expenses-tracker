import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';

class ExpenseController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  Map<String, String>? selectedPayer;
  String splitType = 'equal';
  Map<String, double> splits = {};
  String? payerError;

  final ExpenseService _expenseService = ExpenseService();

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    super.onClose();
  }

  Future<void> addExpense(String groupId) async {
    payerError = null;

    if (selectedPayer == null) {
      payerError = 'Please select who paid';
      update();
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        showErrorMessage('Error', 'You must be logged in to add an expense');
        return;
      }

      final amount = double.tryParse(amountController.text) ?? 0.0;
      if (amount <= 0) {
        showErrorMessage('Error', 'Amount must be greater than 0');
        return;
      }

      if (splits.isEmpty) {
        final groupDoc =
            await FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get();

        if (!groupDoc.exists) {
          showErrorMessage('Error', 'Group not found');
          return;
        }

        final members = List<String>.from(groupDoc['members'] ?? []);
        final equalShare = amount / members.length;

        for (var memberId in members) {
          splits[memberId] = equalShare;
        }
      }

      final expenseId =
          FirebaseFirestore.instance.collection('expenses').doc().id;

      final expense = Expense(
        id: expenseId,
        description: descriptionController.text.trim(),
        amount: amount,
        paidBy: selectedPayer!['uid']!,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        splitType: splitType,
        splits: splits,
        groupId: groupId,
      );

      await _expenseService.addExpense(expense);

      await FirebaseFirestore.instance.collection('groups').doc(groupId).update(
        {
          'expenses': FieldValue.arrayUnion([expenseId]),
        },
      );

      await _updateSimplifiedDebts(groupId);

      descriptionController.clear();
      amountController.clear();
      selectedPayer = null;
      splits = {};
      splitType = 'equal';

      Get.back();
      showSuccessMessage('Success', 'Expense added successfully');
    } catch (e) {
      showErrorMessage('Error', 'Failed to add expense: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String expenseId, String groupId) async {
    try {
      // First, delete the expense document from the 'expenses' collection
      await _expenseService.deleteExpense(expenseId);

      // Then, remove the expenseId from the group's expenses array
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update(
        {
          'expenses': FieldValue.arrayRemove([expenseId]),
        },
      );

      // Finally, update the simplified debts
      await _updateSimplifiedDebts(groupId);

      showSuccessMessage('Success', 'Expense deleted successfully');
    } catch (e) {
      showErrorMessage('Error', 'Failed to delete expense: ${e.toString()}');
    }
  }

  List<Map<String, dynamic>> simplifyDebts(Map<String, double> balances) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    balances.forEach((uid, balance) {
      if (balance > 0) {
        creditors.add(MapEntry(uid, balance));
      } else if (balance < 0) {
        debtors.add(MapEntry(uid, balance));
      }
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value));

    final settlements = <Map<String, dynamic>>[];

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final amount = min(creditor.value, -debtor.value);

      settlements.add({
        'from': debtor.key,
        'to': creditor.key,
        'amount': double.parse(amount.toStringAsFixed(2)),
      });

      debtors[i] = MapEntry(debtor.key, debtor.value + amount);
      creditors[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtors[i].value == 0) i++;
      if (creditors[j].value == 0) j++;
    }

    return settlements;
  }

  Future<void> _updateSimplifiedDebts(String groupId) async {
    final expensesSnapshot =
        await FirebaseFirestore.instance
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .get();

    final balances = <String, double>{};

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final paidBy = data['paidBy'] as String;
      final splits = Map<String, dynamic>.from(data['splits']);

      balances[paidBy] = (balances[paidBy] ?? 0) + amount;

      for (var entry in splits.entries) {
        final uid = entry.key;
        final share = (entry.value as num).toDouble();
        balances[uid] = (balances[uid] ?? 0) - share;
      }
    }

    final simplified = simplifyDebts(balances);

    await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'simplifiedDebts': simplified,
    });
  }
}
