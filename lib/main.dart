import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'posts.dart';
import 'userdata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
      ],
      path: 'lang',
      fallbackLocale: Locale('en', 'US'),
      child: ChangeNotifierProvider(
        create: (_) => UserData(),
        child: App(),
      ),
      startLocale: null
    ),
  );
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final fcm = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    print("Token: ${fcm.getToken()}");
    fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage");
        print(message);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("onMessage"),
        ));
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch");
        print(message);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("OnLaunch"),
        ));
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume");
        print(message);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("onResume"),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Middle",
      theme: ThemeData(
        // platform: TargetPlatform.iOS,
        primaryColor: Colors.yellow,
        accentColor: Colors.orange[100],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => UserLoading(),
      },
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
