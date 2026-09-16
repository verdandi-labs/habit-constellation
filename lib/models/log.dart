class LogEntry {
  final String id;
  final String habitId;
  final String habitName;
  final bool habitArchived;
  final String logDate;
  final String? comment;

  const LogEntry({
    required this.id,
    required this.habitId,
    required this.habitName,
    required this.habitArchived,
    required this.logDate,
    this.comment,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      habitName: json['habit_name'] as String,
      habitArchived: json['habit_archived'] as bool,
      logDate: json['log_date'] as String,
      comment: json['comment'] as String?,
    );
  }
}

class LogRegistryItem {
  final String id;
  final String name;
  final bool archived;
  final DateTime createdAt;

  const LogRegistryItem({
    required this.id,
    required this.name,
    required this.archived,
    required this.createdAt,
  });

  factory LogRegistryItem.fromJson(Map<String, dynamic> json) {
    return LogRegistryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      archived: json['archived'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class LogsResponse {
  final List<LogRegistryItem> habits;
  final List<LogEntry> logs;

  const LogsResponse({
    required this.habits,
    required this.logs,
  });

  factory LogsResponse.fromJson(Map<String, dynamic> json) {
    return LogsResponse(
      habits: (json['habits'] as List)
          .map((h) => LogRegistryItem.fromJson(h as Map<String, dynamic>))
          .toList(),
      logs: (json['logs'] as List)
          .map((l) => LogEntry.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}
