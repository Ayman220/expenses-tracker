import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupDetails extends StatefulWidget {
  const GroupDetails({super.key});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late String groupId;
  late String groupName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      groupId = args['groupId'];
      groupName = args['groupName'];
    }
  }

  Stream<QuerySnapshot> _getExpensesStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No expenses yet. Tap + to add one."),
            );
          }

          final expenses = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = expenses[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Expense';
              final amount = data['amount'] ?? 0;
              final paidBy = data['paidByName'] ?? 'Someone';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text("Paid by $paidBy"),
                  trailing: Text("₹$amount"),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-expense',
            arguments: {
              'groupId': groupId,
              'groupName': groupName,
            },
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
