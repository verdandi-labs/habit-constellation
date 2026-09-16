class User {
  final String id;
  final String email;
  final String name;
  final bool tooltipLogSeen;
  final bool tooltipCommentSeen;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.tooltipLogSeen,
    required this.tooltipCommentSeen,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      tooltipLogSeen: json['tooltip_log_seen'] as bool,
      tooltipCommentSeen: json['tooltip_comment_seen'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
