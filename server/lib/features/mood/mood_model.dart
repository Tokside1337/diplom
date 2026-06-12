class MoodModel {
  final int? id;
  final int patientId;
  final int score;
  final String comment;
  final String timestamp;
  final String? sentiment;

  MoodModel({
    this.id,
    required this.patientId,
    required this.score,
    required this.comment,
    required this.timestamp,
    this.sentiment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'score': score,
      'comment': comment,
      'timestamp': timestamp,
      'sentiment': sentiment,
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

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      score: map['score'] ?? 0,
      comment: map['comment'] ?? '',
      timestamp: _formatDate(map['timestamp']),
      sentiment: map['sentiment'],
    );
  }
}
