import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'intro.dart';

class SMScodeScreen extends StatefulWidget {
  SMScodeScreen(this.verificationId, this.userId, this.prefs);
  final String verificationId;
  final String userId;
  final SharedPreferences prefs;
  @override
  _SMScodeScreenState createState() => _SMScodeScreenState();
}

class _SMScodeScreenState extends State<SMScodeScreen> {
  var smscode = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter sms code")),
      body: Column(
        children: <Widget>[
          TextField(
            controller: smscode,
          ),
          RaisedButton(
            child: Text("send"),
            onPressed: () async {
              print("code ${smscode.text}");
              AuthCredential auth = PhoneAuthProvider.getCredential(
                verificationId: widget.verificationId,
                smsCode: smscode.text,
              );
              FirebaseAuth.instance.signInWithCredential(auth).then((AuthResult value) {
                if (value.user != null) {
                  onAuthenticationSuccessful(widget.userId, widget.prefs, context);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
