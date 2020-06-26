import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'intro.dart';
import 'userdata.dart';

class Settings extends StatelessWidget {
  Settings(this._userData);

  final UserData _userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("settings".tr()),
      ),
      body: ListView(
        children: <Widget>[
          ChangeLang(_userData),
          SignOut(_userData),
          About()
        ],
      ),
    );
  }
}

class ChangeLang extends StatefulWidget {
  ChangeLang(this._userData);

  final UserData _userData;

  @override
  State createState() => _ChangeLangState();
}

class _ChangeLangState extends State<ChangeLang> {
  String dropvalue = 'English';
  Map<String, Locale> _locale = {
    "Русский": Locale('ru', 'RU'),
    "English": Locale('en', 'US'),
  };

  Future<void> _setNewLang(String lang) async {
    setState(() {
      dropvalue = lang;
    });
    context.locale = _locale[dropvalue];
    await widget._userData.prefs.setBool("customLang", true);
    await widget._userData.prefs
        .setString('langCode', context.locale.languageCode);
    await widget._userData.prefs
        .setString('countryCode', context.locale.countryCode);
  }

  @override
  Widget build(BuildContext context) {
    dropvalue = _locale.keys
        .firstWhere((element) => _locale[element] == context.locale);
    return ListTile(
      leading: Icon(Icons.language),
      title: Text("language".tr()),
      trailing: DropdownButton(
        value: dropvalue,
        onChanged: _setNewLang,
        items: _locale.keys.map<DropdownMenuItem<String>>((langkey) {
          return DropdownMenuItem(
            value: langkey,
            child: Text(langkey),
          );
        }).toList(),
      ),
    );
  }
}

class SignOut extends StatelessWidget {
  SignOut(this._userData);

  final UserData _userData;

  Function _signOut(BuildContext context) {
    return () async {
      FirebaseAuth.instance.signOut();
      _userData.prefs.remove("userId");
      Navigator.pop(context);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => IntroScreen(_userData.prefs)));
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.exit_to_app),
      title: Text('signOut'.tr()),
      onTap: _signOut(context),
    );
  }
}

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.info),
      title: Text("about".tr()),
      subtitle: Text("about_descr".tr()),
    );
  }
}
