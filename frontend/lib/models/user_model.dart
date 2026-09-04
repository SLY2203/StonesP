class UserModel {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String role; // 'ADMIN' or 'ALUMNI'
  final bool isVerified;
  final String? dateJoined;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isVerified,
    this.dateJoined,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isAlumnus => role == 'ALUMNI';
  String get fullName => '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'ALUMNI',
      isVerified: json['is_verified'] ?? false,
      dateJoined: json['date_joined'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_verified': isVerified,
      'date_joined': dateJoined,
    };
  }
}
