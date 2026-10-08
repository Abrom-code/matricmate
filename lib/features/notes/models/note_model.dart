import 'dart:io';
import 'package:matricmate/utils/helpers/new_tag_helper.dart';

class NoteModel {
  final int id;
  final int subjectId;
  final int? chapterId;
  final int grade;
  final int chapterNumber;
  final String title;
  final String? description;
  final String fileKey;
  final String? fileUrl;
  final String fileType;
  final int fileSizeBytes;
  final int pageCount;
  final bool isPremium;
  final int orderIndex;
  final String? localFilePath;
  final bool isDownloaded;
  final String? downloadedAt;
  final bool isCompleted;
  final String? completedAt;
  final int userRating; // 0 = unrated, 1..5 = rated
  final DateTime? createdAt;

  const NoteModel({
    required this.id,
    required this.subjectId,
    this.chapterId,
    required this.grade,
    required this.chapterNumber,
    required this.title,
    this.description,
    required this.fileKey,
    this.fileUrl,
    this.fileType = 'pdf',
    this.fileSizeBytes = 0,
    this.pageCount = 0,
    this.isPremium = true,
    this.orderIndex = 0,
    this.localFilePath,
    this.isDownloaded = false,
    this.downloadedAt,
    this.isCompleted = false,
    this.completedAt,
    this.userRating = 0,
    this.createdAt,
  });

  /// Returns true if the user has rated this note (1 to 5).
  bool get isRated => userRating >= 1 && userRating <= 5;

  /// Returns true if this note was created within the last 1 week (7 days) and has not yet been clicked/opened.
  bool get isNew => NewTagHelper.isNoteNew(
        noteId: id,
        createdAt: createdAt,
        downloadedAt: downloadedAt,
        isCompleted: isCompleted,
      );

  /// Human-readable file size in MB (e.g., "2.4 MB", "0.8 MB")
  String get formattedSize => sizeInMB;

  /// File size specifically in MB (e.g. "2.4 MB", "0.8 MB", "0.5 MB")
  String get sizeInMB {
    int bytes = fileSizeBytes;
    if (bytes <= 0 && localFilePath != null) {
      try {
        final f = File(localFilePath!);
        if (f.existsSync()) {
          bytes = f.lengthSync();
        }
      } catch (_) {}
    }
    if (bytes <= 0) {
      if (pageCount > 0) {
        final estimatedMb = (pageCount * 120 * 1024) / (1024 * 1024);
        final val = estimatedMb.clamp(0.2, 50.0);
        return '${val.toStringAsFixed(1)} MB';
      }
      return '';
    }
    final mb = bytes / (1024 * 1024);
    if (mb < 1.0) {
      final val = mb < 0.1 ? 0.1 : mb;
      return '${val.toStringAsFixed(1)} MB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Human-readable page count (e.g., "12 pages")
  String get formattedPages {
    if (pageCount <= 0) return '';
    return '$pageCount ${pageCount == 1 ? 'page' : 'pages'}';
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    final rawKey = map['file_key']?.toString();
    final rawUrl = map['file_url']?.toString();
    final key = (rawKey != null && rawKey.trim().isNotEmpty)
        ? rawKey.trim()
        : (rawUrl?.trim() ?? '');

    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['created_at']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.trim().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.trim());
    }

    return NoteModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      subjectId: (map['subject_id'] as num?)?.toInt() ?? 0,
      chapterId: (map['chapter_id'] as num?)?.toInt(),
      grade: (map['grade'] as num?)?.toInt() ?? 9,
      chapterNumber: (map['chapter_number'] as num?)?.toInt() ?? 1,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      fileKey: key,
      fileUrl: rawUrl,
      fileType: map['file_type']?.toString() ?? 'pdf',
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ??
          (map['file_size'] as num?)?.toInt() ??
          0,
      pageCount: (map['page_count'] as num?)?.toInt() ?? 0,
      isPremium: map['is_premium'] == null
          ? true
          : (map['is_premium'] == true ||
              map['is_premium'] == 1 ||
              map['is_premium'] == '1'),
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 0,
      localFilePath: map['local_file_path']?.toString(),
      isDownloaded: map['is_downloaded'] == 1 ||
          map['is_downloaded'] == true ||
          map['is_downloaded'] == '1',
      downloadedAt: map['downloaded_at']?.toString(),
      isCompleted: map['is_completed'] == 1 ||
          map['is_completed'] == true ||
          map['is_completed'] == '1',
      completedAt: map['completed_at']?.toString(),
      userRating: (map['user_rating'] as num?)?.toInt() ?? 0,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'grade': grade,
      'chapter_number': chapterNumber,
      'title': title,
      'description': description,
      'file_key': fileKey,
      'file_url': fileUrl ?? fileKey,
      'file_type': fileType,
      'file_size_bytes': fileSizeBytes,
      'page_count': pageCount,
      'is_premium': isPremium ? 1 : 0,
      'order_index': orderIndex,
      'local_file_path': localFilePath,
      'is_downloaded': isDownloaded ? 1 : 0,
      'downloaded_at': downloadedAt,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
      'user_rating': userRating,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  NoteModel copyWith({
    int? id,
    int? subjectId,
    int? chapterId,
    int? grade,
    int? chapterNumber,
    String? title,
    String? description,
    String? fileKey,
    String? fileUrl,
    String? fileType,
    int? fileSizeBytes,
    int? pageCount,
    bool? isPremium,
    int? orderIndex,
    String? localFilePath,
    bool? isDownloaded,
    String? downloadedAt,
    bool? isCompleted,
    String? completedAt,
    int? userRating,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      grade: grade ?? this.grade,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      fileKey: fileKey ?? this.fileKey,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      isPremium: isPremium ?? this.isPremium,
      orderIndex: orderIndex ?? this.orderIndex,
      localFilePath: localFilePath ?? this.localFilePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      userRating: userRating ?? this.userRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
