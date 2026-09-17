import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/repositories/habit_repository.dart';
import 'package:habit_constellation/repositories/fake_repository.dart';
import 'package:habit_constellation/repositories/http_repository.dart';
import 'package:habit_constellation/services/token_store.dart';

const baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

final tokenStoreProvider = Provider((ref) => TokenStore());

final repositoryProvider = Provider<HabitRepository>((ref) {
  return HttpRepository(baseUrl: baseUrl, tokenStore: ref.watch(tokenStoreProvider));
});

final fakeRepositoryProvider = Provider<HabitRepository>((ref) {
  return FakeRepository();
});
