import 'package:habit_constellation/models/habit.dart';
import 'package:habit_constellation/models/log.dart';
import 'package:habit_constellation/models/user.dart';

abstract class HabitRepository {
  Future<User> signInWithGoogle(String idToken);
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<User> getCurrentUser();

  Future<List<HabitWithTodayLog>> getHabits(String date);
  Future<Habit> createHabit(String name);
  Future<Habit> renameHabit(String id, String name);
  Future<void> deleteHabit(String id);

  Future<LogEntry> logHabit(String habitId, String logDate);
  Future<void> deleteLog(String habitId, String logDate);
  Future<LogEntry> patchLog(String logId, {String? comment});

  Future<LogsResponse> getLogs(String from, String to);

  Future<User> patchMe({bool? tooltipLogSeen, bool? tooltipCommentSeen});
}
