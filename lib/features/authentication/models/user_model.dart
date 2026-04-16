class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? password;
  final String phoneNumber;
  final String profileImage;
  final String role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.password,
    required this.phoneNumber,
    required this.profileImage,
    this.role = "user",
  });

  // Convert MongoDB Map to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      role: json['role'] ?? 'user',
    );
  }
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? password,
    String? phoneNumber,
    String? profileImage,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
    );
  }

  // Convert UserModel to Map for MongoDB
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'password': password,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'role': role,
    };
  }

  static UserModel empty() => UserModel(
    id: "",
    firstName: "",
    lastName: "",
    email: '',
    username: '',
    phoneNumber: '',
    profileImage: '',
    role: '',
  );

  String get fullName => '$firstName $lastName';
}
