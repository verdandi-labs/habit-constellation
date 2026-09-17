import 'package:flutter_test/flutter_test.dart';
import 'package:habit_constellation/services/seeded_rng.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/models/habit.dart';

void main() {
  group('SeededRng', () {
    test('same seed produces same sequence', () {
      final rng1 = SeededRng('test-seed');
      final rng2 = SeededRng('test-seed');
      for (int i = 0; i < 10; i++) {
        expect(rng1.next(), rng2.next());
      }
    });

    test('different seeds produce different sequences', () {
      final rng1 = SeededRng('seed-a');
      final rng2 = SeededRng('seed-b');
      final values1 = List.generate(10, (_) => rng1.next());
      final values2 = List.generate(10, (_) => rng2.next());
      expect(values1, isNot(equals(values2)));
    });

    test('deterministic star positions for same log id', () {
      final log = LogEntry(
        id: 'log-1',
        habitId: 'h1',
        habitName: 'Meditate',
        habitArchived: false,
        logDate: '2024-01-15',
      );
      final habit = LogRegistryItem(id: 'h1', name: 'Meditate', archived: false, createdAt: DateTime(2024));
      final rng = SeededRng('${log.id}-0');
      final day = int.tryParse(log.logDate.substring(8)) ?? 1;
      final canvasWidth = 400.0;
      final laneHeight = 90.0;
      final laneCenter = (0 + 0.5) * laneHeight + 20;
      final jitterY = (rng.next() - 0.5) * laneHeight * 0.65;
      final jitterX = (rng.next() - 0.5) * 0.04 * canvasWidth;
      final x = (day / 31) * (canvasWidth - 24) + 12 + jitterX;
      final y = laneCenter + jitterY;

      final rng2 = SeededRng('${log.id}-0');
      final day2 = int.tryParse(log.logDate.substring(8)) ?? 1;
      final jitterY2 = (rng2.next() - 0.5) * laneHeight * 0.65;
      final jitterX2 = (rng2.next() - 0.5) * 0.04 * canvasWidth;
      final x2 = (day2 / 31) * (canvasWidth - 24) + 12 + jitterX2;
      final y2 = laneCenter + jitterY2;

      expect(x, equals(x2));
      expect(y, equals(y2));
    });

    test('jitter within bounds', () {
      final rng = SeededRng('test');
      for (int i = 0; i < 100; i++) {
        final v = rng.next();
        expect(v, isNotNull);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(1));
      }
    });
  });
}
