import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/controllers/settlement_controller.dart';

class GroupBalances extends StatelessWidget {
  final String groupId;

  const GroupBalances({super.key, required this.groupId});

  /// Fetch simplified debts stored in the group document.
  Future<List<Map<String, dynamic>>> fetchSimplifiedDebts() async {
    final groupDoc =
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .get();
    if (groupDoc.exists) {
      final data = groupDoc.data();
      if (data != null && data.containsKey('simplifiedDebts')) {
        return List<Map<String, dynamic>>.from(
          data['simplifiedDebts'] as List<dynamic>,
        );
      }
    }
    return [];
  }

  /// Batch fetch user display names for given UIDs.
  Future<Map<String, String>> fetchUserNames(List<String> uids) async {
    if (uids.isEmpty) return {};
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: uids)
            .get();
    return {for (var doc in snapshot.docs) doc.id: doc['name'] as String};
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the settlement controller
    final settlementController = Get.put(SettlementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simplified Balances'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchSimplifiedDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final debts = snapshot.data ?? [];
          if (debts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('All settled up!', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'There are no outstanding debts in this group.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Collect unique user IDs
          final allUids =
              debts
                  .expand((d) => [d['from'] as String, d['to'] as String])
                  .toSet()
                  .cast<String>()
                  .toList();

          return FutureBuilder<Map<String, String>>(
            future: fetchUserNames(allUids),
            builder: (context, nameSnap) {
              if (nameSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final names = nameSnap.data ?? {};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: debts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  final fromId = debt['from'] as String;
                  final toId = debt['to'] as String;
                  final amount = (debt['amount'] as num).toDouble();
                  final fromName = names[fromId] ?? 'Unknown';
                  final toName = names[toId] ?? 'Unknown';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.swap_horiz),
                            title: Text('$fromName owes $toName'),
                            trailing: Text(
                              amount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed:
                                () => _showSettleConfirmation(
                                  context,
                                  settlementController,
                                  fromId,
                                  toId,
                                  fromName,
                                  toName,
                                  amount,
                                ),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Mark as Settled',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
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

  void _showSettleConfirmation(
    BuildContext context,
    SettlementController settlementController,
    String fromId,
    String toId,
    String fromName,
    String toName,
    double amount,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Settlement'),
          content: Text(
            'Are you sure $fromName has paid $toName ${amount.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                settlementController.settleDebt(
                  groupId: groupId,
                  fromUserId: fromId,
                  toUserId: toId,
                  amount: amount,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
