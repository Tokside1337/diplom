class QuestionnaireModel {
  final int? id;
  final int patientId;
  final String title;
  final int totalScore;
  final String date;

  QuestionnaireModel({
    this.id,
    required this.patientId,
    required this.title,
    required this.totalScore,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'total_score': totalScore,
      'date': date,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory QuestionnaireModel.fromMap(Map<String, dynamic> map) {
    return QuestionnaireModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      title: map['title'] ?? '',
      totalScore: map['total_score'] ?? map['totalScore'] ?? 0,
      date: _formatDate(map['date']),
    );
  }
}
