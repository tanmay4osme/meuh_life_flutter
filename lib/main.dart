import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meuh_life/screens/root_screen.dart';
import 'package:meuh_life/services/authentication.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Meuh Life',
      theme: new ThemeData(
        //primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade800,
        accentColor: Colors.amber.shade800,
      ),
      home: new RootScreen(auth: new Auth()),
      localizationsDelegates: [
        // ... app-specific localization delegate[s] here
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // English
        const Locale('fr'), // Hebrew
      ],
    );
  }
}