import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/main.dart';
import 'package:habit_constellation/repositories/fake_repository.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/screens/auth_screen.dart';

void main() {
  testWidgets('App renders auth screen when not signed in', (WidgetTester tester) async {
    final repo = FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
