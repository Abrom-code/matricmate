import 'dart:convert';

/// Local and remote model for the notifications table.
class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'announcement' | 'payment' | 'new_content'
  final Map<String, dynamic> payload;
  final String?
  targetStream; // null = global broadcast; 'natural'/'social' = stream-targeted
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.payload,
    this.targetStream,
    required this.isRead,
    this.isArchived = false,
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
      targetStream: map['target_stream']?.toString(),
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
      'target_stream': targetStream,
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
      targetStream: targetStream,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Safely parses id from int, String, or num representations.
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  return 0;
}
