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

  /// The plan key the user subscribed to (e.g. '1_year').
  final String? subscriptionPlan;

  /// When the current subscription expires.
  final DateTime? subscriptionExpiresAt;

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
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
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
      subscriptionPlan: json['subscription_plan']?.toString(),
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.tryParse(json['subscription_expires_at'].toString())
          : null,
    );
  }

  // from local db
  factory UserModel.fromMap(Map<String, dynamic> json) =>
      UserModel.fromJson(json);

  /// TO JSON (Dart → Supabase) for profile operations only.
  /// NOTE: receipt_upload_count, subscription_plan, and
  /// subscription_expires_at are intentionally excluded — they are managed
  /// by server-side logic and must never be overwritten by a profile
  /// save/upsert.
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
      'subscription_plan': subscriptionPlan,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
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
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
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
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
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

  /// User is active if status is 'active' AND subscription has not expired.
  /// Legacy users without an expiry date are treated as active (lifetime).
  bool get isActive {
    if (status != 'active') return false;
    if (subscriptionExpiresAt == null) return true;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';

  /// True when status is 'active' but expiry date has passed.
  bool get isExpired =>
      status == 'active' &&
      subscriptionExpiresAt != null &&
      subscriptionExpiresAt!.isBefore(DateTime.now());

  bool get exceededUploadLimit => receiptUploadCount >= 2;

  /// Human-readable remaining time (e.g. "184 days left").
  String get remainingDaysText {
    if (subscriptionExpiresAt == null) return '';
    final diff = subscriptionExpiresAt!.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Expired';
    if (diff > 365) return '${(diff / 365).toStringAsFixed(1)} years left';
    if (diff > 30) return '${(diff / 30).floor()} months left';
    return '$diff days left';
  }
}
