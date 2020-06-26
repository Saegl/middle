import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData with ChangeNotifier {
  SharedPreferences prefs;
  String id;
  bool auth;
  DocumentSnapshot firestoreSnap;
  UserData({this.prefs, this.id, this.auth, this.firestoreSnap});
  Future<void> reloadSnap() async {
    final user = await Firestore.instance.collection("user").document(id).get();
    firestoreSnap = user;
  }
}
