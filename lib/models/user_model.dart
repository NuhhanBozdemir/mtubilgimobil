class UserModel {
  final String uid;
  final String name;
  final String email;       // ✅ yeni alan
  final String department;
  final String number;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.number,
    required this.role,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',          // ✅ email alanı
      department: data['department'] ?? '',
      number: data['number'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,                      // ✅ email alanı
      'department': department,
      'number': number,
      'role': role,
    };
  }
}