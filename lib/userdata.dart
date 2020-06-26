import 'dart:collection';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> 87627cd4c3b65aed40639c11e55c7624019e1017
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData with ChangeNotifier {
  UserData() {
    load();
  }
  
  SharedPreferences prefs;
  bool prefsLoaded = false;
  String id; // User ID, phone no.
  bool auth; // is user authenticated
  bool authLoaded = false;
  DocumentSnapshot snapshot; // user account raw snapshot from firebase
  
  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString("userId");
    prefsLoaded = true;
    notifyListeners();

    snapshot = await Firestore.instance.collection("user").document(id).get();
    final user = await FirebaseAuth.instance.currentUser();
    auth = (user == null || id == null);
    authLoaded = true;
    notifyListeners();
  }
}
