import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/repositories/habit_repository.dart';
import 'package:habit_constellation/repositories/fake_repository.dart';
import 'package:habit_constellation/repositories/http_repository.dart';
import 'package:habit_constellation/services/token_store.dart';

const baseUrl = 'https://habit-constellation-api.onrender.com';

final tokenStoreProvider = Provider((ref) => TokenStore());

final repositoryProvider = Provider<HabitRepository>((ref) {
  return HttpRepository(baseUrl: baseUrl, tokenStore: ref.watch(tokenStoreProvider));
});

final fakeRepositoryProvider = Provider<HabitRepository>((ref) {
  return FakeRepository();
});
