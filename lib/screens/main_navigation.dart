import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clock/clock.dart';
import 'package:habit_constellation/screens/home_screen.dart';
import 'package:habit_constellation/screens/constellation_screen.dart';
import 'package:habit_constellation/providers/habits_provider.dart';
import 'package:habit_constellation/models/log.dart';
import 'dart:async';

final constellationProvider = FutureProvider<List<LogEntry>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return const [];
});

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  String _lastDate = '';
  AppLifecycleListener? _lifecycleListener;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _lastDate = _todayString();
    _lifecycleListener = AppLifecycleListener(
      onResume: _onResume,
    );
    _startPeriodicTimer();
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _periodicTimer?.cancel();
    super.dispose();
  }

  void _onResume() {
    _checkDayChange();
  }

  void _startPeriodicTimer() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkDayChange();
    });
  }

  void _checkDayChange() {
    final currentDate = _todayString();
    if (currentDate != _lastDate) {
      _lastDate = currentDate;
      ref.invalidate(habitsProvider);
    }
  }

  String _todayString() {
    final now = clock.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final constellationAsync = ref.watch(constellationProvider);
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(
          onGoConstellation: () => setState(() => _currentIndex = 1),
        ),
        ConstellationScreen(
          habits: const [],
          logs: const [],
          isLoading: constellationAsync.isLoading,
          error: constellationAsync.error,
          onRetry: () => ref.invalidate(constellationProvider),
        ),
      ],
    );
  }
}
