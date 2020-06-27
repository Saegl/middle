import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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

class App extends StatelessWidget {
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
