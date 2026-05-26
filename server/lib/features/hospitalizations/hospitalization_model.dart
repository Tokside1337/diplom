class HospitalizationModel {
  final int? id;
  final int patientId;
  final String admissionDate;
  final String dischargeDate;
  final String reason;
  final String department;

  HospitalizationModel({
    this.id,
    required this.patientId,
    required this.admissionDate,
    required this.dischargeDate,
    required this.reason,
    required this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'admission_date': admissionDate,
      'discharge_date': dischargeDate,
      'reason': reason,
      'department': department,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory HospitalizationModel.fromMap(Map<String, dynamic> map) {
    return HospitalizationModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'],
      admissionDate: _formatDate(map['admission_date'] ?? map['admissionDate']),
      dischargeDate: _formatDate(map['discharge_date'] ?? map['dischargeDate']),
      reason: map['reason'],
      department: map['department'],
    );
  }
}
