import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/balance.dart';
import '../models/settlement.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _expensesCollection = 'expenses';
  final String _balancesCollection = 'balances';
  final String _settlementsCollection = 'settlements';

  Future<void> addExpense(Expense expense) async {
    await _firestore.collection(_expensesCollection).doc(expense.id).set(expense.toMap());
    await _updateBalances(expense);
  }

  Future<List<Expense>> getExpensesByGroup(String groupId) async {
    final snapshot = await _firestore
        .collection(_expensesCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
  }

  Future<void> deleteExpense(String expenseId) async {
    final expenseDoc = await _firestore.collection(_expensesCollection).doc(expenseId).get();
    if (expenseDoc.exists) {
      final expense = Expense.fromMap(expenseDoc.data()!);
      await _firestore.collection(_expensesCollection).doc(expenseId).delete();
      await _revertBalances(expense);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final oldExpenseDoc = await _firestore.collection(_expensesCollection).doc(expense.id).get();
    if (oldExpenseDoc.exists) {
      final oldExpense = Expense.fromMap(oldExpenseDoc.data()!);
      await _revertBalances(oldExpense);
    }
    await _firestore.collection(_expensesCollection).doc(expense.id).update(expense.toMap());
    await _updateBalances(expense);
  }

  Future<List<Balance>> getBalancesByGroup(String groupId) async {
    final snapshot = await _firestore
        .collection(_balancesCollection)
        .where('groupId', isEqualTo: groupId)
        .get();

    return snapshot.docs.map((doc) => Balance.fromMap(doc.data())).toList();
  }

  Future<void> addSettlement(Settlement settlement) async {
    await _firestore.collection(_settlementsCollection).doc(settlement.id).set(settlement.toMap());
    await _updateBalancesFromSettlement(settlement);
  }

  Future<List<Settlement>> getSettlementsByGroup(String groupId) async {
    final snapshot = await _firestore
        .collection(_settlementsCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Settlement.fromMap(doc.data())).toList();
  }

  Future<void> _updateBalances(Expense expense) async {
    final paidBy = expense.paidBy;
    final splits = expense.splits;

    for (final entry in splits.entries) {
      final userId = entry.key;
      final amount = entry.value;

      if (userId != paidBy) {
        // Create or update balance from user to payer
        await _updateBalance(
          expense.groupId,
          userId,
          paidBy,
          amount,
        );
      }
    }
  }

  Future<void> _revertBalances(Expense expense) async {
    final paidBy = expense.paidBy;
    final splits = expense.splits;

    for (final entry in splits.entries) {
      final userId = entry.key;
      final amount = entry.value;

      if (userId != paidBy) {
        // Revert the balance
        await _updateBalance(
          expense.groupId,
          userId,
          paidBy,
          -amount,
        );
      }
    }
  }

  Future<void> _updateBalance(
    String groupId,
    String fromUserId,
    String toUserId,
    double amount,
  ) async {
    final balanceRef = _firestore
        .collection(_balancesCollection)
        .where('groupId', isEqualTo: groupId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .limit(1);

    final snapshot = await balanceRef.get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final currentAmount = doc.data()['amount'] as double;
      await doc.reference.update({
        'amount': currentAmount + amount,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } else {
      await _firestore.collection(_balancesCollection).add({
        'groupId': groupId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _updateBalancesFromSettlement(Settlement settlement) async {
    await _updateBalance(
      settlement.groupId,
      settlement.fromUserId,
      settlement.toUserId,
      -settlement.amount,
    );
  }
} 