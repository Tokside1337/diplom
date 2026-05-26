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
      'patientId': patientId,
      'pressureSystolic': pressureSystolic,
      'pressureDiastolic': pressureDiastolic,
      'pulse': pulse,
      'painLevel': painLevel,
      'timestamp': timestamp,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'],
      pressureSystolic: (map['pressure_systolic'] ?? map['pressureSystolic'] as num).toDouble(),
      pressureDiastolic: (map['pressure_diastolic'] ?? map['pressureDiastolic'] as num).toDouble(),
      pulse: map['pulse'],
      painLevel: map['pain_level'] ?? map['painLevel'],
      timestamp: _formatDate(map['timestamp']),
    );
  }
}
