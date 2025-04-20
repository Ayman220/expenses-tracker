class User {
  final String uid;
  String name;
  bool emailVerified;

  double balance;

  User({
    required this.uid,
    required this.name,
    this.balance = 0.0,
    this.emailVerified = false,
  });
}
