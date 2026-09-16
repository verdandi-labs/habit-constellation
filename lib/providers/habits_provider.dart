import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/providers/repository_provider.dart';

final habitsProvider = FutureProvider<List<HabitWithTodayLog>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  final now = DateTime.now();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return repository.getHabits(dateStr);
});
