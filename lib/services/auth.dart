import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  app_user.User? _userFromFirebaseUser(User? user) {
    return user != null ? app_user.User(uid: user.uid, name: "") : null;
  }

  // auth change user stream
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign in with email/password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      return null;
    }
  }

  // register with email/password
  Future<app_user.User?> registerWithEmailAndPassword(String email, String password)async{
try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      return null;
    }
  }

  // logout
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      return null;
    }
  }
}
