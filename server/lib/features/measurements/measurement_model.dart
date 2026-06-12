class MeasurementModel {
  final int? id;
  final int patientId;
  final double pressureSystolic;
  final double pressureDiastolic;
  final int pulse;
  final int painLevel;
  final String timestamp;

  MeasurementModel({
    this.id,
    required this.patientId,
    required this.pressureSystolic,
    required this.pressureDiastolic,
    required this.pulse,
    required this.painLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'pressure_systolic': pressureSystolic,
      'pressure_diastolic': pressureDiastolic,
      'pulse': pulse,
      'pain_level': painLevel,
      'timestamp': timestamp,
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

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      pressureSystolic: (map['pressure_systolic'] ?? map['pressureSystolic'] as num).toDouble(),
      pressureDiastolic: (map['pressure_diastolic'] ?? map['pressureDiastolic'] as num).toDouble(),
      pulse: map['pulse'] ?? 0,
      painLevel: map['pain_level'] ?? map['painLevel'] ?? 0,
      timestamp: _formatDate(map['timestamp']),
    );
  }
}
