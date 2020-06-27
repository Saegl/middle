import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData with ChangeNotifier {
  UserData() {
    load();
  }
  
  SharedPreferences prefs;
  String id; // User ID, phone no.
  bool auth; // is user authenticated
  DocumentSnapshot snapshot; // user account raw snapshot from firebase
  bool loaded = false;

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString("userId");
    // TODO logging library
    print("UserId: $id");
    snapshot = await Firestore.instance.collection("user").document(id).get();
    final user = await FirebaseAuth.instance.currentUser();
    print("Firebase Auth instance: $user");
    auth = !(user == null || id == null);
    print("auth: $auth");
    loaded = true;
    notifyListeners();
  }
}
