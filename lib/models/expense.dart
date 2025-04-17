class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidBy;
  final String paidByName;
  final DateTime createdAt;
  final Map<String, double> splits; // Maps user ID to their share amount
  final String splitType; // 'equal', 'unequal', 'percentage'

  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.createdAt,
    required this.splits,
    this.splitType = 'equal',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'createdAt': createdAt.toIso8601String(),
      'splits': splits,
      'splitType': splitType,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      groupId: map['groupId'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      paidBy: map['paidBy'],
      paidByName: map['paidByName'],
      createdAt: DateTime.parse(map['createdAt']),
      splits: Map<String, double>.from(map['splits'] ?? {}),
      splitType: map['splitType'] ?? 'equal',
    );
  }
} 