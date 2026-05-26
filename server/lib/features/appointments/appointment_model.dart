class AppointmentModel {
  final int? id;
  final int patientId;
  final String type;
  final String title;
  final String time;
  final String room;
  final String doctor;
  final String status;
  final String? patientName;

  AppointmentModel({
    this.id,
    required this.patientId,
    required this.type,
    required this.title,
    required this.time,
    required this.room,
    required this.doctor,
    this.status = 'pending',
    this.patientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'type': type,
      'title': title,
      'time': time,
      'room': room,
      'doctor': doctor,
      'status': status,
      'patient_name': patientName,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      time: _formatDate(map['time']),
      room: map['room'] ?? '',
      doctor: map['doctor'] ?? '',
      status: map['status'] ?? 'pending',
      patientName: map['patient_name'],
    );
  }
}
