class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? password;
  final String stream;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.stream,
    this.password,
  });

  /// FROM JSON (Supabase → Dart)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      stream: json['stream']?.toString() ?? '',
    );
  }

  /// TO JSON (Dart → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'stream': stream,
      // ⚠️ optional: don't store password here
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? stream,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      stream: stream ?? this.stream,
      password: password ?? this.password,
    );
  }

  static UserModel empty() =>
      UserModel(id: "", firstName: "", lastName: "", email: '', stream: '');

  String get fullName => '$firstName $lastName';
}
