import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_constellation/services/offline_queue.dart';

void main() {
  group('OfflineQueue', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('enqueue persists', () async {
      final queue = OfflineQueue();
      await queue.enqueue(QueuedAction(
        habitId: 'h1',
        logDate: '2024-01-15',
        action: QueueAction.log,
      ));

      await queue.load();
      expect(queue.items.length, 1);
      expect(queue.items.first.habitId, 'h1');
      expect(queue.items.first.action, QueueAction.log);
    });

    test('drain clears queue and returns items', () async {
      final queue = OfflineQueue();
      await queue.enqueue(QueuedAction(
        habitId: 'h1',
        logDate: '2024-01-15',
        action: QueueAction.log,
      ));
      await queue.enqueue(QueuedAction(
        habitId: 'h2',
        logDate: '2024-01-15',
        action: QueueAction.undo,
      ));

      final items = await queue.drain();
      expect(items.length, 2);
      expect(queue.items.isEmpty, isTrue);
    });

    test('coalesces per habit (last action wins)', () async {
      final queue = OfflineQueue();
      await queue.enqueue(QueuedAction(
        habitId: 'h1',
        logDate: '2024-01-15',
        action: QueueAction.log,
      ));
      await queue.enqueue(QueuedAction(
        habitId: 'h1',
        logDate: '2024-01-15',
        action: QueueAction.undo,
      ));

      await queue.load();
      expect(queue.items.length, 1);
      expect(queue.items.first.action, QueueAction.undo);
    });

    test('survives app restart', () async {
      final queue = OfflineQueue();
      await queue.enqueue(QueuedAction(
        habitId: 'h1',
        logDate: '2024-01-15',
        action: QueueAction.log,
      ));

      final queue2 = OfflineQueue();
      await queue2.load();
      expect(queue2.items.length, 1);
    });
  });
}
