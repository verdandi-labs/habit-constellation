class Habit {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }
}

class HabitWithTodayLog {
  final String id;
  final String name;
  final TodayLog? todayLog;

  const HabitWithTodayLog({
    required this.id,
    required this.name,
    this.todayLog,
  });

  bool get isDoneToday => todayLog != null;

  factory HabitWithTodayLog.fromJson(Map<String, dynamic> json) {
    return HabitWithTodayLog(
      id: json['id'] as String,
      name: json['name'] as String,
      todayLog: json['today_log'] != null
          ? TodayLog.fromJson(json['today_log'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TodayLog {
  final String id;
  final String logDate;
  final String? comment;

  const TodayLog({
    required this.id,
    required this.logDate,
    this.comment,
  });

  bool get hasComment => comment != null && comment!.isNotEmpty;

  factory TodayLog.fromJson(Map<String, dynamic> json) {
    return TodayLog(
      id: json['id'] as String,
      logDate: json['log_date'] as String,
      comment: json['comment'] as String?,
    );
  }
}
