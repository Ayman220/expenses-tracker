import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/components/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/controllers/expense_controller.dart';

class ExpenseList extends StatelessWidget {
  final String groupId;
  final String groupName;

  const ExpenseList({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName Expenses'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('expenses')
                .where('groupId', isEqualTo: groupId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Loader());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data?.docs ?? [];
          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first expense to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expenseDoc = expenses[index];
              final data = expenseDoc.data() as Map<String, dynamic>;
              final description =
                  data['description'] as String? ?? 'Unnamed expense';
              final amount = data['amount'] as double? ?? 0.0;
              final paidById = data['paidBy'] as String? ?? '';
              final createdAt = data['createdAt'];
              final timestamp =
                  createdAt is Timestamp
                      ? createdAt
                      : (createdAt is String
                          ? Timestamp.fromDate(DateTime.parse(createdAt))
                          : null);
          
              final date =
                  timestamp != null
                      ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                      : 'Unknown date';
          
              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(paidById)
                        .get(),
                builder: (context, userSnapshot) {
                  String payerName = 'Unknown';
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    payerName = userData?['name'] as String? ?? 'Unknown';
                  }
          
                  return Dismissible(
                    key: Key(expenseDoc.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text(
                              'Are you sure you want to delete this expense? This will also update all balances.',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      expenseController.deleteExpense(expenseDoc.id, groupId);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt),
                        ),
                        title: Text(description),
                        subtitle: Text('Paid by $payerName • $date'),
                        trailing: Text(
                          amount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          _showExpenseDetails(context, data, payerName);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showExpenseDetails(
    BuildContext context,
    Map<String, dynamic> expenseData,
    String payerName,
  ) async {
    final splits = Map<String, double>.from(
      expenseData['splits'] as Map? ?? {},
    );
    final amount = expenseData['amount'] as double? ?? 0.0;
    final description =
        expenseData['description'] as String? ?? 'Unnamed expense';

    // Get member names
    final memberNames = <String, String>{};
    for (final userId in splits.keys) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        memberNames[userId] = userData?['name'] ?? 'Unknown';
      } else {
        memberNames[userId] = 'Unknown';
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paid by $payerName',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Split Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: splits.length,
                  itemBuilder: (context, index) {
                    final entry = splits.entries.elementAt(index);
                    final userId = entry.key;
                    final share = entry.value;
                    final memberName = memberNames[userId] ?? 'Unknown';

                    return ListTile(
                      title: Text(memberName),
                      trailing: Text(
                        share.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              userId == expenseData['paidBy']
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
