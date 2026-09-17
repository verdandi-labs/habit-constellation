import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/screens/home_screen.dart';
import 'package:habit_constellation/screens/constellation_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Constellation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07091C),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(
          onGoConstellation: () => setState(() => _currentIndex = 1),
        ),
        ConstellationScreen(
          habits: const [],
          logs: const [],
        ),
      ],
    );
  }
}
