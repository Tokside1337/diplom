enum UserRole { doctor, patient }

class User {
  final int? id;
  final String login;
  final String password;
  final UserRole role;
  final int? patientId; // null for doctors, linked to patients table for patients

  User({
    this.id,
    required this.login,
    required this.password,
    required this.role,
    this.patientId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'password': password,
      'role': role.name,
      'patient_id': patientId,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      login: map['login'],
      password: map['password'],
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      patientId: map['patient_id'],
    );
  }
}
