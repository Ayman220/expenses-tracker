import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/components/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/controllers/settlement_controller.dart';
import 'package:intl/intl.dart';

class SettleDebts extends StatelessWidget {
  final String groupId;
  final String groupName;

  const SettleDebts({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final settlementController = Get.put(SettlementController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$groupName Settlements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Outstanding Debts'),
              Tab(text: 'Settlement History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOutstandingDebtsTab(context, settlementController),
            _buildSettlementHistoryTab(settlementController),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingDebtsTab(
    BuildContext context,
    SettlementController settlementController,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loader());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Group not found'));
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final debts = List<Map<String, dynamic>>.from(
          groupData['simplifiedDebts'] ?? [],
        );

        if (debts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
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
          future: _fetchUserNames(allUids),
          builder: (context, nameSnap) {
            if (nameSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: Loader());
            }

            final names = nameSnap.data ?? {};
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                final fromId = debt['from'] as String;
                final toId = debt['to'] as String;
                final amount = (debt['amount'] as num).toDouble();
                final fromName = names[fromId] ?? 'Unknown';
                final toName = names[toId] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '$fromName owes $toName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              amount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check),
                              SizedBox(width: 8),
                              Text('Mark as Settled'),
                            ],
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
    );
  }

  Widget _buildSettlementHistoryTab(SettlementController settlementController) {
    return StreamBuilder<QuerySnapshot>(
      stream: settlementController.getSettlementHistory(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loader());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final settlements = snapshot.data?.docs ?? [];
        if (settlements.isEmpty) {
          return const Center(child: Text('No settlement history yet'));
        }

        // Collect unique user IDs
        final allUids =
            settlements
                .expand((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return [
                    data['fromUserId'] as String,
                    data['toUserId'] as String,
                    data['createdBy'] as String,
                  ];
                })
                .toSet()
                .cast<String>()
                .toList();

        return FutureBuilder<Map<String, String>>(
          future: _fetchUserNames(allUids),
          builder: (context, nameSnap) {
            if (nameSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: Loader());
            }

            final names = nameSnap.data ?? {};
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settlements.length,
              itemBuilder: (context, index) {
                final settlementDoc = settlements[index];
                final data = settlementDoc.data() as Map<String, dynamic>;

                final fromId = data['fromUserId'] as String;
                final toId = data['toUserId'] as String;
                final createdById = data['createdBy'] as String;
                final amount = (data['amount'] as num).toDouble();

                final fromName = names[fromId] ?? 'Unknown';
                final toName = names[toId] ?? 'Unknown';
                final createdByName = names[createdById] ?? 'Unknown';

                // Format date
                final timestamp = data['createdAt'] as Timestamp?;
                final date =
                    timestamp != null
                        ? DateFormat(
                          'MMM d, yyyy - h:mm a',
                        ).format(timestamp.toDate())
                        : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.paid)),
                    title: Text('$fromName paid $toName'),
                    subtitle: Text('$date • Marked by $createdByName'),
                    trailing: Text(
                      amount.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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

  /// Batch fetch user display names for given UIDs
  Future<Map<String, String>> _fetchUserNames(List<String> uids) async {
    if (uids.isEmpty) return {};

    // Split into batches of 10 to avoid Firestore limitations
    final batches = <List<String>>[];
    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 < uids.length) ? i + 10 : uids.length;
      batches.add(uids.sublist(i, end));
    }

    final results = <String, String>{};

    for (final batch in batches) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

      for (var doc in snapshot.docs) {
        results[doc.id] = doc['name'] as String? ?? 'Unknown';
      }
    }

    return results;
  }
}
