import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

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

  bool get isPayment => type == 'payment';

  bool get isNewContent => type == 'new_content';

  bool get isChallenge =>
      type == 'challenge' ||
      type == 'challenge_round' ||
      type == 'challenge_reward' ||
      payload.containsKey('challenge_id');

  bool get isAnnouncement => !isPayment && !isNewContent && !isChallenge;

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

    final rawType = map['type']?.toString().toLowerCase().trim() ?? '';
    final payloadType = parsedPayload['type']?.toString().toLowerCase().trim();
    final title = map['title']?.toString() ?? '';

    String resolvedType;
    if (rawType.isNotEmpty && rawType != 'announcement') {
      resolvedType = rawType;
    } else if (payloadType != null &&
        payloadType.isNotEmpty &&
        payloadType != 'announcement') {
      resolvedType = payloadType;
    } else if (parsedPayload.containsKey('test_id') ||
        parsedPayload.containsKey('test_type')) {
      resolvedType = 'new_content';
    } else if (title.toLowerCase().startsWith('new content') ||
        title.toLowerCase().startsWith('[new content]')) {
      resolvedType = 'new_content';
    } else {
      resolvedType = 'announcement';
    }

    return AppNotification(
      id: _parseInt(map['id']),
      userId: map['user_id']?.toString() ?? '',
      title: title,
      body: map['body']?.toString() ?? '',
      type: resolvedType,
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

/// Filter categories for the student notification center.
enum NotificationFilter {
  all,
  unread,
  newContent,
  announcements,
  challenges,
  payments,
}

extension NotificationFilterX on NotificationFilter {
  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.newContent:
        return 'New Content';
      case NotificationFilter.announcements:
        return 'Announcements';
      case NotificationFilter.challenges:
        return 'Challenges';
      case NotificationFilter.payments:
        return 'Payments';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationFilter.all:
        return Icons.grid_view_rounded;
      case NotificationFilter.unread:
        return Icons.mark_email_unread_rounded;
      case NotificationFilter.newContent:
        return Icons.menu_book_rounded;
      case NotificationFilter.announcements:
        return Icons.campaign_rounded;
      case NotificationFilter.challenges:
        return Icons.emoji_events_rounded;
      case NotificationFilter.payments:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationFilter.all:
        return AppColors.primary;
      case NotificationFilter.unread:
        return const Color(0xFFF59E0B);
      case NotificationFilter.newContent:
        return const Color(0xFF0284C7);
      case NotificationFilter.announcements:
        return AppColors.primary;
      case NotificationFilter.challenges:
        return const Color(0xFF2563EB);
      case NotificationFilter.payments:
        return const Color(0xFFF59E0B);
    }
  }
}
