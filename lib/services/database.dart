import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // Collection reference
  final CollectionReference groups = FirebaseFirestore.instance.collection(
    "groups",
  );
  final CollectionReference users = FirebaseFirestore.instance.collection(
    "users",
  );

  Future<void> createUser(String name, String email, String userId) async {
    await users.doc(userId).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new group
  Future<void> createGroup(String groupName, String userId) async {
    await groups.add({
      'name': groupName,
      'members': [userId],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add a user to an existing group
  Future<void> addUserToGroup(String groupId, String userId) async {
    await groups.doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // Add an expense to a group
  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> involvedUsers,
  }) async {
    final expensesRef = groups.doc(groupId).collection("expenses");

    await expensesRef.add({
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'involvedUsers': involvedUsers,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get group details (like name and members)
  Future<DocumentSnapshot> getGroupDetails(String groupId) {
    return groups.doc(groupId).get();
  }

  // Get all expenses in a group
  Stream<QuerySnapshot> getGroupExpenses(String groupId) {
    return groups
        .doc(groupId)
        .collection("expenses")
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Settle payment between users
  Future<void> settlePayment({
    required String groupId,
    required String fromUser,
    required String toUser,
    required double amount,
  }) async {
    final settlementsRef = groups.doc(groupId).collection("settlements");

    await settlementsRef.add({
      'from': fromUser,
      'to': toUser,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
