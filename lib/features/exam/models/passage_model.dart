class PassageModel {
  int id;
  String content;
  String? imageUrl;
  PassageModel({required this.id, this.imageUrl, required this.content});

  factory PassageModel.fromJson(Map<String, dynamic> json) {
    return PassageModel(
      id: json['id'],
      content: json['content'],
      imageUrl: json['image_url'],
    );
  }
  factory PassageModel.fromMap(Map<String, dynamic> map) =>
      PassageModel.fromJson(map);

  Map<String, dynamic> toMap() {
    return {'id': id, 'content': content, 'image_url': imageUrl};
  }
}
