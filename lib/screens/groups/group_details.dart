import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .get();

      final memberIds = List<String>.from(groupDoc['members'] ?? []);

      final userDocs = await Future.wait(
        memberIds.map(
          (id) => FirebaseFirestore.instance.collection('users').doc(id).get(),
        ),
      );

      return userDocs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name':
              (data?['name'] as String?) ??
              'Unknown', // Explicitly cast to String? and handle null
        };
      }).toList();
    } catch (e) {
      return [
        {'uid': 'error', 'name': 'Failed to load'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        centerTitle: true,
        elevation: 2,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Group not found.'));
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
                          return const CircularProgressIndicator(); // Show loading indicator
                        }
                        if (!membersSnapshot.hasData) {
                          return const Text(
                            "No members available",
                          ); //Or return an empty container
                        }

                        final members = membersSnapshot.data!;

                        return ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/add-expense',
                              arguments: {
                                'groupId': widget.groupId,
                                'groupName': groupName,
                                'members': members,
                              },
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add expenses"),
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
                FutureBuilder<List<Map<String, String>>>(
                  future: _memberInfoFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData) {
                      return const Text("Failed to load members");
                    }

                    final members = snapshot.data!;
                    return Wrap(
                      spacing: 8.0,
                      children:
                          members
                              .map((m) => Chip(label: Text(m['name'] ?? '')))
                              .toList(),
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
}
