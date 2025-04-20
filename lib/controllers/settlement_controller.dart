import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/helpers/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SettlementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Marks a debt as settled between two users in a group
  Future<void> settleDebt({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        showErrorMessage('Error', 'You must be logged in to settle debts');
        return;
      }

      // Create a settlement record
      final settlementId = _firestore.collection('settlements').doc().id;
      
      await _firestore.collection('settlements').doc(settlementId).set({
        'id': settlementId,
        'groupId': groupId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'status': 'completed',
      });

      // Update the group's simplified debts
      await _updateGroupDebts(groupId, fromUserId, toUserId, amount);
      
      showSuccessMessage('Success', 'Payment marked as settled');
    } catch (e) {
      showErrorMessage('Error', 'Failed to settle debt: ${e.toString()}');
    }
  }

  /// Updates the simplified debts in the group document after a settlement
  Future<void> _updateGroupDebts(
    String groupId, 
    String fromUserId, 
    String toUserId, 
    double settledAmount,
  ) async {
    return _firestore.runTransaction((transaction) async {
      // Get the current group document
      final groupDocRef = _firestore.collection('groups').doc(groupId);
      final groupSnapshot = await transaction.get(groupDocRef);
      
      if (!groupSnapshot.exists) {
        throw Exception('Group not found');
      }
      
      final groupData = groupSnapshot.data()!;
      final List<dynamic> currentDebts = groupData['simplifiedDebts'] ?? [];
      
      // Find and update the debt between these users
      bool debtFound = false;
      final updatedDebts = <Map<String, dynamic>>[];
      
      for (var debt in currentDebts) {
        if (debt['from'] == fromUserId && debt['to'] == toUserId) {
          final currentAmount = (debt['amount'] as num).toDouble();
          final remainingAmount = currentAmount - settledAmount;
          
          // If there's still debt remaining
          if (remainingAmount > 0.01) {  // Using a small threshold to account for floating point errors
            updatedDebts.add({
              'from': fromUserId,
              'to': toUserId,
              'amount': double.parse(remainingAmount.toStringAsFixed(2)),
            });
          }
          debtFound = true;
        } else {
          // Keep other debts unchanged
          updatedDebts.add(debt);
        }
      }
      
      if (!debtFound) {
        throw Exception('Debt not found between these users');
      }
      
      // Update the group document with the new simplified debts
      transaction.update(groupDocRef, {
        'simplifiedDebts': updatedDebts,
      });
    });
  }
  
  /// Gets the settlement history for a group
  Stream<QuerySnapshot> getSettlementHistory(String groupId) {
    return _firestore
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}