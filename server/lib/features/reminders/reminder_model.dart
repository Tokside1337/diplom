class ReminderModel {
  final int? id;
  final int patientId;
  final int doctorId;
  final String message;
  final bool isRead;
  final String timestamp;

  ReminderModel({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.message,
    this.isRead = false,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'],
      doctorId: map['doctor_id'] ?? map['doctorId'],
      message: map['message'],
      isRead: map['is_read'] ?? map['isRead'] ?? false,
      timestamp: _formatDate(map['timestamp']),
    );
  }
}
