class User {
  final int id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
