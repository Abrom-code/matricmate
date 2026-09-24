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
  });

  /// Human-readable file size (e.g., "2.4 MB", "420 KB")
  String get formattedSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024 * 1024) {
      final kb = (fileSizeBytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
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
    );
  }
}
