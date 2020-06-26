import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'lenta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO load userdata by provider
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool customLang = prefs.getBool("customLang") ?? false;
  return runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
      ],
      path: 'lang',
      fallbackLocale: Locale('en', 'US'),
      child: Main(),
      startLocale: customLang
          ? Locale(prefs.getString("langCode"), prefs.getString("countryCode"))
          : null, // System language
    ),
  );
}


class Main extends StatelessWidget {
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
        '/': (context) => Lenta(),
      },

      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,

      debugShowCheckedModeBanner: false,
    );
  }
}
