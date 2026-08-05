import 'dart:convert';

/// Local + remote representation of a row in the `notifications` table.
///
/// `type` drives both the icon shown in [NotificationTile] and the
/// navigation behavior on tap:
///   - 'payment'      → opens the payment verification screen
///   - 'new_content'  → opens the exact test via [NotificationTestOpener]
///   - 'announcement' → opens the notifications list (default/no-op)
class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'announcement' | 'payment' | 'new_content'
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    final rawPayload = map['payload'];
    if (rawPayload != null) {
      try {
        parsedPayload = rawPayload is String
            ? Map<String, dynamic>.from(jsonDecode(rawPayload))
            : Map<String, dynamic>.from(rawPayload as Map);
      } catch (_) {
        // Malformed payload — fall back to empty map rather than crash.
      }
    }

    return AppNotification(
      id: _parseInt(map['id']),
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'announcement',
      payload: parsedPayload,
      isRead: map['is_read'] == true || map['is_read'] == 1,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'payload': jsonEncode(payload),
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Safely parses an id that may arrive as [int], [String], or [num].
/// Supabase returns `bigint` columns as [String] in the Flutter client
/// to avoid JavaScript precision loss; SQLite returns them as [int].
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  return 0;
}
