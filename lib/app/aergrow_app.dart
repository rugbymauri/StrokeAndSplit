import 'package:flutter/material.dart';

import '../features/connection/start_screen.dart';

class AergRowApp extends StatelessWidget {
  const AergRowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AergRow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E99), brightness: Brightness.light),
      // Dark by default: easier to read at the erg and kinder to the battery.
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E99), brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const StartScreen(),
    );
  }
}
