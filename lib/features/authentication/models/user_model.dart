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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      stream: json['stream']?.toString() ?? '',
    );
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

  // Convert UserModel to Map for MongoDB
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'stream': stream,
      'password': password,
    };
  }

  static UserModel empty() =>
      UserModel(id: "", firstName: "", lastName: "", email: '', stream: '');

  String get fullName => '$firstName $lastName';
}
