import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'lenta.dart';
import 'userdata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(
    ChangeNotifierProvider(
      create: (_) => UserData(),
      child: LocalizedApp(),
    ),
  );
}

class LocalizedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    //if (userData.prefsLoaded)
    if (userData.prefsLoaded) {
      bool customLang = userData.prefs.getBool("customLang") ?? false;
      return EasyLocalization(
        supportedLocales: [
          Locale('en', 'US'),
          Locale('ru', 'RU'),
        ],
        path: 'lang',
        fallbackLocale: Locale('en', 'US'),
        child: App(userData),
        startLocale: customLang
            ? Locale(
                userData.prefs.getString("langCode"),
                userData.prefs.getString("countryCode"),
              )
            : null, // System language
      );
    } else {
      return Container();
    }
  }
}

class App extends StatelessWidget {
  App(this.userData);
  UserData userData;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Middle",
      theme: ThemeData(
        primaryColor: Colors.yellow,
        accentColor: Colors.orange[100],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Lenta(userData),
      },
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
    );
  }
}
