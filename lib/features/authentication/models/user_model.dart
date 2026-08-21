class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? password;
  final String stream;

  /// subscription status: inactive | pending | active
  final String status;

  /// Account creation timestamp used for notification filtering.
  final DateTime? createdAt;

  /// Number of receipt upload attempts
  final int receiptUploadCount;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.stream,
    this.password,
    this.status = 'inactive',
    this.createdAt,
    this.receiptUploadCount = 0,
  });

  /// FROM JSON (Supabase → Dart)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      stream: json['stream']?.toString() ?? '',
      status: json['subscription_status']?.toString() ?? 'inactive',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      receiptUploadCount:
          (json['receipt_upload_count'] as num?)?.toInt() ?? 0,
    );
  }

  // from local db
  factory UserModel.fromMap(Map<String, dynamic> json) =>
      UserModel.fromJson(json);

  /// TO JSON (Dart → Supabase) for profile operations only.
  /// NOTE: receipt_upload_count is intentionally excluded — it is managed
  /// exclusively by PaymentRepository and must never be overwritten by a
  /// profile save/upsert.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'stream': stream,
      'subscription_status': status,
    };
  }

  // to local db
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'stream': stream,
      'subscription_status': status,
      'created_at': createdAt?.toIso8601String(),
      'receipt_upload_count': receiptUploadCount,
    };
  }

  /// COPY WITH
  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? stream,
    String? password,
    String? status,
    DateTime? createdAt,
    int? receiptUploadCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      stream: stream ?? this.stream,
      password: password ?? this.password,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      receiptUploadCount: receiptUploadCount ?? this.receiptUploadCount,
    );
  }

  /// EMPTY USER
  static UserModel empty() => UserModel(
    id: '',
    firstName: '',
    lastName: '',
    email: '',
    stream: '',
    status: 'inactive',
    receiptUploadCount: 0,
  );

  /// FULL NAME
  String get fullName => '$firstName $lastName';

  static List<String> nameParts(String fullName) => fullName.split(' ');

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';
  bool get exceededUploadLimit => receiptUploadCount >= 2;
}
