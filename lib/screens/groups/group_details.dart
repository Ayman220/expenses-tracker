import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense_tracker/screens/groups/add_member.dart';

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

    _memberInfoFuture = _fetchMemberInfo(); // Initialize here
  }

  Future<List<Map<String, String>>> _fetchMemberInfo() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
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
        return {
          'uid': doc.id,
          'name': (data?['name'] as String?) ?? 'Unknown',
        };
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
            return const Center(
              child: Text('Group not found.'),
            );
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final groupName = groupData['name'] ?? 'Unnamed Group';

          return Padding(
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

                        if (!membersSnapshot.hasData || membersSnapshot.data!.isEmpty) {
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                            children: members
                                .map((m) => Chip(label: Text(m['name'] ?? '')))
                                .toList(),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () async {
                        final groupDoc = await FirebaseFirestore.instance
                            .collection('groups')
                            .doc(widget.groupId)
                            .get();
                        
                        if (!groupDoc.exists) return;
                        
                        final existingMembers = List<String>.from(groupDoc['members'] ?? []);
                        
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
              ],
            ),
          );
        },
      ),
    );
  }
}
