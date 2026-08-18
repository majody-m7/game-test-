import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TrafficUntangleApp());
}

class TrafficUntangleApp extends StatelessWidget {
  const TrafficUntangleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traffic Untangle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF457B9D),
        scaffoldBackgroundColor: const Color(0xFFFAF6ED),
        fontFamily: 'Roboto',
        ),
      home: const HomeScreen(),
      );
  }
}
