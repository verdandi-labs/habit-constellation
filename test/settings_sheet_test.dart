import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/screens/sheets/settings_sheet.dart';

void main() {
  group('SettingsSheet', () {
    testWidgets('reminder toggle exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsSheet(onLogout: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Daily reminder'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('logout button exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsSheet(onLogout: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Log out'), findsWidgets);
    });

    testWidgets('logout confirmation dialog shows', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsSheet(onLogout: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Log out').first);
      await tester.pump();

      expect(find.text('Log out of Habit Constellation?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel dismisses dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsSheet(onLogout: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Log out').first);
      await tester.pump();

      await tester.tap(find.text('Cancel').last);
      await tester.pump();

      expect(find.text('Log out of Habit Constellation?'), findsNothing);
    });
  });
}
