class SubjectModel {
  int id;
  String name;
  bool isNatural, isCommon, isDownloaded, isEntranceDownloaded;

  /// Cached remote counts — persisted to SQLite so they survive app restarts
  /// without a network call.
  int entranceCount;
  int modelCount;

  SubjectModel({
    required this.id,
    required this.name,
    required this.isNatural,
    this.isCommon = false,
    this.isDownloaded = false,
    this.isEntranceDownloaded = false,
    this.entranceCount = 0,
    this.modelCount = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'],
      name: json['name'],
      isNatural: json['is_natural'],
      isCommon: json['is_common'],
    );
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'],
      name: map['name'],
      isNatural: map['is_natural'] == 1,
      isCommon: map['is_common'] == 1,
      isDownloaded: map['is_downloaded'] == 1,
      isEntranceDownloaded: (map['is_entrance_downloaded'] ?? 0) == 1,
      entranceCount: map['entrance_count'] as int? ?? 0,
      modelCount: map['model_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_natural': isNatural ? 1 : 0,
      'is_common': isCommon ? 1 : 0,
      'is_downloaded': isDownloaded ? 1 : 0,
      'is_entrance_downloaded': isEntranceDownloaded ? 1 : 0,
      'entrance_count': entranceCount,
      'model_count': modelCount,
    };
  }
}
