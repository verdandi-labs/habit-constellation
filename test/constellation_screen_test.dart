import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/screens/constellation_screen.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/services/toast_service.dart';

void main() {
  group('Constellation screen', () {
    testWidgets('dots render for logs', (WidgetTester tester) async {
      final habits = [
        LogRegistryItem(id: 'h1', name: 'Meditate', archived: false, createdAt: DateTime(2024)),
      ];
      final logs = [
        LogEntry(id: 'l1', habitId: 'h1', habitName: 'Meditate', habitArchived: false, logDate: '2024-01-15'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ConstellationScreen(
              habits: habits,
              logs: logs,
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Small victories'), findsOneWidget);
      expect(find.text("This month's sky is dark."), findsOneWidget);
    });

    testWidgets('empty month shows dark sky', (WidgetTester tester) async {
      final habits = [
        LogRegistryItem(id: 'h1', name: 'Meditate', archived: false, createdAt: DateTime(2024)),
      ];
      final logs = <LogEntry>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ConstellationScreen(
              habits: habits,
              logs: logs,
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text("This month's sky is dark."), findsOneWidget);
    });

    testWidgets('error banner renders with retry', (WidgetTester tester) async {
      final habits = [
        LogRegistryItem(id: 'h1', name: 'Meditate', archived: false, createdAt: DateTime(2024)),
      ];
      final logs = <LogEntry>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ConstellationScreen(
              habits: habits,
              logs: logs,
              isLoading: false,
              error: Exception('test error'),
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('loading skeleton renders', (WidgetTester tester) async {
      final habits = [
        LogRegistryItem(id: 'h1', name: 'Meditate', archived: false, createdAt: DateTime(2024)),
      ];
      final logs = <LogEntry>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ConstellationScreen(
              habits: habits,
              logs: logs,
              isLoading: true,
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedBuilder).first, findsOneWidget);
    });
  });
}
