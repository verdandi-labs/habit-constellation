import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum QueueAction { log, undo }

class QueuedAction {
  final String habitId;
  final String logDate;
  final QueueAction action;

  const QueuedAction({
    required this.habitId,
    required this.logDate,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
    'habit_id': habitId,
    'log_date': logDate,
    'action': action.name,
  };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
    habitId: json['habit_id'] as String,
    logDate: json['log_date'] as String,
    action: QueueAction.values.firstWhere((a) => a.name == json['action']),
  );
}

class OfflineQueue {
  static const _key = 'offline_queue';
  List<QueuedAction> _queue = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _queue = raw.map((s) => QueuedAction.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _queue.map((a) => jsonEncode(a.toJson())).toList());
  }

  List<QueuedAction> get items => List.unmodifiable(_queue);

  Future<void> enqueue(QueuedAction action) async {
    _queue.removeWhere((a) => a.habitId == action.habitId);
    _queue.add(action);
    await _save();
  }

  Future<void> removeByHabitId(String habitId) async {
    _queue.removeWhere((a) => a.habitId == habitId);
    await _save();
  }

  Future<void> clear() async {
    _queue.clear();
    await _save();
  }

  Future<void> remove(QueuedAction action) async {
    _queue.removeWhere((a) => a.habitId == action.habitId && a.action == action.action);
    await _save();
  }
}
