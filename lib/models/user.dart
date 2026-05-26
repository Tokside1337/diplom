enum UserRole { doctor, patient, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.doctor:
        return 'Врач';
      case UserRole.patient:
        return 'Пациент';
      case UserRole.admin:
        return 'Администратор';
    }
  }
}

class User {
  final int? id;
  final String login;
  final String password;
  final UserRole role;
  final int? patientId; // null for doctors, linked to patients table for patients
  final int? doctorId;  // null for patients, linked to doctors table for doctors

  User({
    this.id,
    required this.login,
    required this.password,
    required this.role,
    this.patientId,
    this.doctorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'login': login,
      'password': password,
      'role': role.name,
      'patient_id': patientId,
      'doctor_id': doctorId,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      login: map['login'] ?? '',
      password: map['password'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      patientId: map['patient_id'],
      doctorId: map['doctor_id'],
    );
  }
}
