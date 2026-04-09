class SubjectMoModel {
  int? id;
  String name;
  bool isNatural, isCommon, isDownloaded;

  SubjectMoModel({
    this.id,
    required this.name,
    required this.isNatural,
    this.isCommon = false,
    this.isDownloaded = false,
  });
  // Convert Json to SubjectMoModel object
  factory SubjectMoModel.fromJson(Map<String, dynamic> json) {
    return SubjectMoModel(
      id: json['id'],
      name: json['name'],
      isNatural: json['is_natural'],
      isCommon: json['is_common'],
    );
  }

  // Convert DB Map to SubjectMoModel object
  factory SubjectMoModel.fromMap(Map<String, dynamic> map) {
    return SubjectMoModel(
      id: map['id'],
      name: map['name'],
      isNatural: map['is_natural'] == 1,
      isCommon: map['is_common'] == 1,
      isDownloaded: map['is_downloaded'] == 1,
    );
  }

  // Convert SubjectMoModel object to Map for DB insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_natural': isNatural ? 1 : 0,
      'is_common': isCommon ? 1 : 0,
      'is_downloaded': 0,
    };
  }
}
