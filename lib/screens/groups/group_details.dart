import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/screens/groups/expense_list.dart';
import 'package:expense_tracker/screens/groups/group_balances.dart';
import 'package:expense_tracker/screens/groups/settle_debts.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/screens/groups/add_member.dart';
import 'package:expense_tracker/controllers/expense_controller.dart';

class GroupDetails extends StatefulWidget {
  final String groupId;

  const GroupDetails({super.key, required this.groupId});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late Future<DocumentSnapshot> _groupFuture;
  late Future<List<Map<String, String>>> _memberInfoFuture;

  @override
  void initState() {
    super.initState();
    _groupFuture =
        FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .get();

    _memberInfoFuture = _fetchMemberInfo();

    // Register the ExpenseController if not already registered
    if (!Get.isRegistered<ExpenseController>()) {
      Get.put(ExpenseController());
    }
  }

  Future<List<Map<String, String>>> _fetchMemberInfo() async {
    try {
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final memberIds = List<String>.from(groupDoc['members'] ?? []);
      if (memberIds.isEmpty) {
        return [];
      }

      final userDocs = await Future.wait(
        memberIds.map(
          (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
        ),
      );

      return userDocs.map((doc) {
        final data = doc.data();
        return {'uid': doc.id, 'name': (data?['name'] as String?) ?? 'Unknown'};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching member info: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading group: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Group not found.'));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final groupName = groupData['name'] ?? 'Unnamed Group';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<List<Map<String, String>>>(
                      future: _memberInfoFuture,
                      builder: (context, membersSnapshot) {
                        if (membersSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (membersSnapshot.hasError) {
                          return const Text("Error loading members");
                        }

                        if (!membersSnapshot.hasData ||
                            membersSnapshot.data!.isEmpty) {
                          return const Text("No members available");
                        }

                        final members = membersSnapshot.data!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Get.toNamed(
                                '/add-expense',
                                arguments: {
                                  'groupId': widget.groupId,
                                  'groupName': groupName,
                                  'members': members,
                                },
                              );
                            },
                            child: const Text("Add expenses"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Members:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<Map<String, String>>>(
                        future: _memberInfoFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error loading members: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No members in this group"),
                            );
                          }

                          final members = snapshot.data!;
                          return Wrap(
                            spacing: 8.0,
                            children:
                                members
                                    .map(
                                      (m) => Chip(label: Text(m['name'] ?? '')),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () async {
                        final groupDoc =
                            await FirebaseFirestore.instance
                                .collection('groups')
                                .doc(widget.groupId)
                                .get();

                        if (!groupDoc.exists) return;

                        final existingMembers = List<String>.from(
                          groupDoc['members'] ?? [],
                        );

                        final result = await Get.to(
                          () => AddMember(
                            groupId: widget.groupId,
                            existingMembers: existingMembers,
                          ),
                        );

                        if (result == true) {
                          // Refresh the member list
                          setState(() {
                            _memberInfoFuture = _fetchMemberInfo();
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Get.to(
                            () => ExpenseList(
                              groupId: widget.groupId,
                              groupName: groupName,
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Expenses'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => GroupBalances(groupId: widget.groupId));
                        },
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('View Balances'),
                      ),
                    ),
                  ],
                ),

                // Add the new Settle Up button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(
                        () => SettleDebts(
                          groupId: widget.groupId,
                          groupName: groupName,
                        ),
                      );
                    },
                    icon: const Icon(Icons.handshake),
                    label: const Text('Settle Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('expenses')
                          .where('groupId', isEqualTo: widget.groupId)
                          .orderBy('createdAt', descending: true)
                          .limit(3)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final expenses = snapshot.data?.docs ?? [];

                    if (expenses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No expenses yet. Add an expense to get started!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Expenses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(
                                  () => ExpenseList(
                                    groupId: widget.groupId,
                                    groupName: groupName,
                                  ),
                                );
                              },
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...expenses.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final description =
                              data['description'] as String? ??
                              'Unnamed expense';
                          final amount = data['amount'] as double? ?? 0.0;
                          final paidById = data['paidBy'] as String? ?? '';

                          return FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(paidById)
                                    .get(),
                            builder: (context, userSnapshot) {
                              String payerName = 'Unknown';
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                payerName =
                                    userData?['name'] as String? ?? 'Unknown';
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(description),
                                  subtitle: Text('Paid by $payerName'),
                                  trailing: Text(
                                    amount.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),

                // Add recent settlements section
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('settlements')
                          .where('groupId', isEqualTo: widget.groupId)
                          .orderBy('createdAt', descending: true)
                          .limit(3)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final settlements = snapshot.data?.docs ?? [];

                    if (settlements.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Get all user IDs
                    final userIds =
                        settlements
                            .expand<String>((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return [
                                data['fromUserId'] as String,
                                data['toUserId'] as String,
                              ];
                            })
                            .toSet()
                            .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Settlements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(
                                  () => SettleDebts(
                                    groupId: widget.groupId,
                                    groupName: groupName,
                                  ),
                                );
                              },
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, String>>(
                          future: _fetchUserNames(userIds),
                          builder: (context, namesSnapshot) {
                            if (namesSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final names = namesSnapshot.data ?? {};

                            return Column(
                              children:
                                  settlements.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final fromId = data['fromUserId'] as String;
                                    final toId = data['toUserId'] as String;
                                    final amount =
                                        (data['amount'] as num).toDouble();

                                    final fromName = names[fromId] ?? 'Unknown';
                                    final toName = names[toId] ?? 'Unknown';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.green,
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text('$fromName paid $toName'),
                                        trailing: Text(
                                          amount.toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
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
