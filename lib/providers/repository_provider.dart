import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/repositories/habit_repository.dart';
import 'package:habit_constellation/repositories/fake_repository.dart';

final repositoryProvider = Provider<HabitRepository>((ref) {
  return FakeRepository();
});
