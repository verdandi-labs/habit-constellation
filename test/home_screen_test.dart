import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_constellation/screens/home_screen.dart';
import 'package:habit_constellation/repositories/fake_repository.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/providers/habits_provider.dart';
import 'package:clock/clock.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Home screen', () {
    testWidgets('habit list renders', (WidgetTester tester) async {
      final repo = FakeRepository();
      await repo.createHabit('Meditate');
      await repo.createHabit('Stretch');
      await repo.signInWithGoogle('mock_token');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: HomeScreen(onGoConstellation: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Meditate'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
    });

    testWidgets('tap marks done state', (WidgetTester tester) async {
      final repo = FakeRepository();
      await repo.createHabit('Meditate');
      await repo.signInWithGoogle('mock_token');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: HomeScreen(onGoConstellation: () {}),
          ),
        ),
      );
      await tester.pump();

      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsWidgets);
      await tester.tap(animatedContainers.first);
      await tester.pump(const Duration(milliseconds: 1200));

      final container = tester.widget<AnimatedContainer>(animatedContainers.first);
      final boxDecoration = container.decoration as BoxDecoration?;
      expect(boxDecoration?.color, isNotNull);
    });

    testWidgets('empty state and footer visible', (WidgetTester tester) async {
      final repo = FakeRepository();
      await repo.signInWithGoogle('mock_token');

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: HomeScreen(onGoConstellation: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Your constellation is waiting, log your first habit.'), findsOneWidget);
      expect(find.text('add a new habit'), findsOneWidget);
    });
  });
}
