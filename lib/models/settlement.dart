class Settlement {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime createdAt;
  final String? note;

  Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'],
      groupId: map['groupId'],
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      amount: map['amount'].toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      note: map['note'],
    );
  }
} 