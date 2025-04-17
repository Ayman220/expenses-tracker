class Balance {
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime lastUpdated;

  Balance({
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      groupId: map['groupId'],
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      amount: map['amount'].toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
} 