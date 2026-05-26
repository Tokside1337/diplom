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
      'patientId': patientId,
      'score': score,
      'comment': comment,
      'timestamp': timestamp,
      'sentiment': sentiment,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory MoodModel.fromMap(Map<String, dynamic> map) {
    return MoodModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'],
      score: map['score'],
      comment: map['comment'],
      timestamp: _formatDate(map['timestamp']),
      sentiment: map['sentiment'],
    );
  }
}
