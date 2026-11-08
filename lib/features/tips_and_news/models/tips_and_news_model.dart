import 'package:intl/intl.dart';

class TipsAndNewsModel {
  TipsAndNewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    this.author = 'MatricMate Team',
    this.audience = 'both',
    this.isPinned = false,
    this.isUserPinned = false,
    this.isPublished = true,
    required this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String content;
  final String category; // 'news' or 'tip'
  final String? imageUrl;
  final String author;
  final String audience;
  final bool isPinned;
  final bool isUserPinned;
  final bool isPublished;
  final DateTime createdAt;
  final bool isRead;

  bool get isNews => category.toLowerCase().trim() == 'news';
  bool get isTip => category.toLowerCase().trim() == 'tip';
  bool get isSaved => isUserPinned;
  bool get isAnyPinned => isPinned || isUserPinned;

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 1) return 'Just now';
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(createdAt);
    }
  }

  factory TipsAndNewsModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d != null) {
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return TipsAndNewsModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: (json['category']?.toString() ?? 'news').toLowerCase(),
      imageUrl: json['image_url']?.toString(),
      author: json['author']?.toString() ?? 'MatricMate Team',
      audience: json['audience']?.toString() ?? 'both',
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      isUserPinned: json['is_user_pinned'] == true || json['is_user_pinned'] == 1,
      isPublished: json['is_published'] == null || json['is_published'] == true || json['is_published'] == 1,
      createdAt: parseDate(json['created_at']),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'author': author,
      'audience': audience,
      'is_pinned': isPinned ? 1 : 0,
      'is_user_pinned': isUserPinned ? 1 : 0,
      'is_published': isPublished ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  TipsAndNewsModel copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? imageUrl,
    String? author,
    String? audience,
    bool? isPinned,
    bool? isUserPinned,
    bool? isPublished,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return TipsAndNewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      audience: audience ?? this.audience,
      isPinned: isPinned ?? this.isPinned,
      isUserPinned: isUserPinned ?? this.isUserPinned,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

