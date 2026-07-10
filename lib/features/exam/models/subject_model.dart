class SubjectModel {
  int id;
  String name;
  bool isNatural, isCommon, isDownloaded, isEntranceDownloaded;

  SubjectModel({
    required this.id,
    required this.name,
    required this.isNatural,
    this.isCommon = false,
    this.isDownloaded = false,
    this.isEntranceDownloaded = false,
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
    };
  }
}
