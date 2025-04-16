import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late String groupId;
  late String groupName;
  late List<Map<String, dynamic>> members;
  String? selectedPayerId;

  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      groupId = args['groupId'];
      groupName = args['groupName'];
      // Ensure the members list is correctly cast
      members = List<Map<String, dynamic>>.from(args['members'] ?? []);
      selectedPayerId = FirebaseAuth.instance.currentUser?.uid;
    }
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate() || selectedPayerId == null) return;

    setState(() => isLoading = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final payerData =
        members.firstWhere((m) => m['uid'] == selectedPayerId, orElse: () => {});

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .add({
      'title': _titleController.text.trim(),
      'amount': amount,
      'paidBy': selectedPayerId,
      'paidByName': payerData['name'] ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount"),
                      validator: (val) =>
                          val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPayerId,
                      decoration: const InputDecoration(labelText: "Paid By"),
                      items: members.map((member) {
                        return DropdownMenuItem<String>(
                          value: member['uid'],
                          child: Text(member['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() {
                        selectedPayerId = val;
                      }),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addExpense,
                      child: const Text("Create Expense"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
