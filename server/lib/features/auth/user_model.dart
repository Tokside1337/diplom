class UserModel {
  final int? id;
  final String login;
  final String password;
  final String role;
  final int? patientId;
  final int? doctorId;

  UserModel({
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
      'role': role,
      'patient_id': patientId,
      'doctor_id': doctorId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      login: map['login'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      patientId: map['patient_id'] ?? map['patientId'],
      doctorId: map['doctor_id'] ?? map['doctorId'],
    );
  }
}
