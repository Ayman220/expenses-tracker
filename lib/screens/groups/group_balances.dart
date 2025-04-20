import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupBalances extends StatelessWidget {
  final String groupId;

  const GroupBalances({super.key, required this.groupId});

  /// Fetch simplified debts stored in the group document.
  Future<List<Map<String, dynamic>>> fetchSimplifiedDebts() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    if (groupDoc.exists) {
      final data = groupDoc.data();
      if (data != null && data.containsKey('simplifiedDebts')) {
        return List<Map<String, dynamic>>.from(
            data['simplifiedDebts'] as List<dynamic>);
      }
    }
    return [];
  }

  /// Batch fetch user display names for given UIDs.
  Future<Map<String, String>> fetchUserNames(List<String> uids) async {
    if (uids.isEmpty) return {};
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids)
        .get();
    return {for (var doc in snapshot.docs) doc.id: doc['name'] as String};
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text('No debts to show', style: TextStyle(fontSize: 16)),
            );
          }

          // Collect unique user IDs
          final allUids = debts
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

                  return ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text('$fromName owes $toName'),
                    trailing: Text(
                      amount.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
