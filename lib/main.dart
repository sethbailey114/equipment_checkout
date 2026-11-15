import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

void main() {
  runApp(const EquipmentCheckoutApp());
}

class EquipmentCheckoutApp extends StatelessWidget {
  const EquipmentCheckoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equipment Checkout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F5F8B)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
