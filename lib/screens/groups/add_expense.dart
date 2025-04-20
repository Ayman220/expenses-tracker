import 'package:flutter/material.dart';
import 'package:expense_tracker/components/custom_dropdown.dart';
import 'package:expense_tracker/controllers/expense_controller.dart';
import 'package:expense_tracker/screens/groups/split_options.dart';
import 'package:get/get.dart';

class AddExpense extends StatelessWidget {
  final String groupId;
  final List<Map<String, String>> members;

  const AddExpense({
    super.key,
    required this.groupId,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomDropdown(
                    items: members,
                    selectedItem: controller.selectedPayer,
                    onChanged: (value) => controller.selectedPayer = value,
                    hintText: 'Paid by',
                    errorText: controller.payerError,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final amount = double.tryParse(controller.amountController.text) ?? 0.0;
                      final result = await Get.to(
                        () => SplitOptions(
                          members: members,
                          initialSplits: controller.splits,
                          splitType: controller.splitType,
                        ),
                        arguments: {'amount': amount},
                      );
                      if (result != null) {
                        controller.splits = result['splits'];
                        controller.splitType = result['splitType'];
                      }
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Split Options'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.addExpense(groupId),
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
