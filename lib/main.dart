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
        scaffoldBackgroundColor: const Color(0xFF080B14),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ConstellationScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xEE080B14),
          indicatorColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.home, color: Colors.white),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.auto_awesome, color: Colors.white),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
