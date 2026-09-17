import 'package:clock/clock.dart';
import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/models/user.dart';
import 'package:habit_constellation/repositories/habit_repository.dart';

class FakeRepository implements HabitRepository {
  final Map<String, List<HabitWithTodayLog>> _habits = {};
  final Map<String, LogEntry> _logs = {};
  User? _currentUser;
  bool _signedIn = false;

  @override
  Future<User> signInWithGoogle(String idToken) async {
    _currentUser = User(
      id: 'fake-user-id',
      email: 'fake@example.com',
      name: 'Fake User',
      tooltipLogSeen: false,
      tooltipCommentSeen: false,
      createdAt: DateTime(2024),
    );
    _signedIn = true;
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _signedIn = false;
  }

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<bool> silentSignIn() async => _signedIn;

  @override
  Future<User> getCurrentUser() async {
    if (_currentUser == null) throw Exception('Not signed in');
    return _currentUser!;
  }

  @override
  Future<List<HabitWithTodayLog>> getHabits(String date) async {
    return _habits[date] ?? [];
  }

  @override
  Future<Habit> createHabit(String name) async {
    final habit = Habit(
      id: 'habit-${_habits.length + 1}',
      name: name,
      createdAt: clock.now(),
    );
    return habit;
  }

  @override
  Future<Habit> renameHabit(String id, String name) async {
    return Habit(
      id: id,
      name: name,
      createdAt: clock.now(),
    );
  }

  @override
  Future<void> deleteHabit(String id) async {}

  @override
  Future<LogEntry> logHabit(String habitId, String logDate) async {
    final log = LogEntry(
      id: 'log-${_logs.length + 1}',
      habitId: habitId,
      habitName: 'Fake Habit',
      habitArchived: false,
      logDate: logDate,
    );
    _logs[log.id] = log;
    return log;
  }

  @override
  Future<void> deleteLog(String habitId, String logDate) async {
    _logs.removeWhere((_, log) =>
        log.habitId == habitId && log.logDate == logDate);
  }

  @override
  Future<LogEntry> patchLog(String logId, {String? comment}) async {
    final existing = _logs[logId];
    if (existing == null) throw Exception('Log not found');
    final updated = LogEntry(
      id: existing.id,
      habitId: existing.habitId,
      habitName: existing.habitName,
      habitArchived: existing.habitArchived,
      logDate: existing.logDate,
      comment: comment,
    );
    _logs[logId] = updated;
    return updated;
  }

  @override
  Future<LogsResponse> getLogs(String from, String to) async {
    return const LogsResponse(habits: [], logs: []);
  }

  @override
  Future<User> patchMe({bool? tooltipLogSeen, bool? tooltipCommentSeen}) async {
    if (_currentUser == null) throw Exception('Not signed in');
    _currentUser = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: _currentUser!.name,
      tooltipLogSeen: tooltipLogSeen ?? _currentUser!.tooltipLogSeen,
      tooltipCommentSeen: tooltipCommentSeen ?? _currentUser!.tooltipCommentSeen,
      createdAt: _currentUser!.createdAt,
    );
    return _currentUser!;
  }
}
