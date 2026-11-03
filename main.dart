import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';

void main() => runApp(const NovelForgeApp());

class NovelForgeApp extends StatelessWidget {
  const NovelForgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NOVEL FORGE AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C68)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8F7),
    ),
    supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const HomeScreen(),
  );
}
