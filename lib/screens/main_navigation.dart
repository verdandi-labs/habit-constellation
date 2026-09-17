import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clock/clock.dart';
import 'package:habit_constellation/screens/home_screen.dart';
import 'package:habit_constellation/screens/constellation_screen.dart';
import 'package:habit_constellation/providers/habits_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _lastDate = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastDate = _todayString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentDate = _todayString();
      if (currentDate != _lastDate) {
        _lastDate = currentDate;
        ref.invalidate(habitsProvider);
      }
    }
  }

  String _todayString() {
    final now = clock.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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
