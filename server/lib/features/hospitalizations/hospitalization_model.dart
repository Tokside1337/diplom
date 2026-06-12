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
      'patient_id': patientId,
      'admission_date': admissionDate,
      'discharge_date': dischargeDate,
      'reason': reason,
      'department': department,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) {
      String s = val.toIso8601String();
      if (s.contains('T00:00:00')) return s.split('T')[0];
      return s;
    }
    String s = val.toString();
    if (s.contains('T00:00:00')) return s.split('T')[0];
    return s;
  }

  factory HospitalizationModel.fromMap(Map<String, dynamic> map) {
    return HospitalizationModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      admissionDate: _formatDate(map['admission_date'] ?? map['admissionDate']),
      dischargeDate: _formatDate(map['discharge_date'] ?? map['dischargeDate']),
      reason: map['reason'] ?? '',
      department: map['department'] ?? '',
    );
  }
}
