class UserSession {
  const UserSession({
    required this.token,
    required this.username,
    required this.role,
    this.name,
    this.rollNumber,
    this.hostel,
    this.roomNumber,
  });

  final String token;
  final String username;
  final String role;
  final String? name;
  final String? rollNumber;
  final String? hostel;
  final String? roomNumber;

  bool get isStudent => role.toUpperCase() == 'STUDENT';
  bool get isGuard => role.toUpperCase() == 'GUARD';
  bool get isAdmin {
    final value = role.toUpperCase();
    return value.contains('ADMIN');
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'] as String,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String?,
      rollNumber: json['rollNumber'] as String?,
      hostel: json['hostel'] as String?,
      roomNumber: json['roomNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'username': username,
        'role': role,
        'name': name,
        'rollNumber': rollNumber,
        'hostel': hostel,
        'roomNumber': roomNumber,
      };
}
