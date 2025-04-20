import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final String createdBy;
  final DateTime createdAt;
  final String splitType;
  final Map<String, double> splits;
  final String groupId;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.createdBy,
    required this.createdAt,
    required this.splitType,
    required this.splits,
    required this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'splitType': splitType,
      'splits': splits,
      'groupId': groupId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      paidBy: map['paidBy'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt']) 
          : (map['createdAt'] as Timestamp).toDate(),
      splitType: map['splitType'] ?? 'equal',
      splits: Map<String, double>.from(map['splits'] as Map<dynamic, dynamic>),
      groupId: map['groupId'] ?? '',
    );
  }
}