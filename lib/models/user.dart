class User {
  final String uid;
  String name;

  double balance;

  User({
    required this.uid,
    required this.name,
    this.balance = 0.0,
  });
}
