import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService{

  // collection reference
  final CollectionReference groups= FirebaseFirestore.instance.collection("groups");
}