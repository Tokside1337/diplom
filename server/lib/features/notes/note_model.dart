class NoteModel {
  final int? id;
  final int patientId;
  final String author;
  final String content;
  final String timestamp;

  NoteModel({
    this.id,
    required this.patientId,
    required this.author,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'author': author,
      'content': content,
      'timestamp': timestamp,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'],
      author: map['author'],
      content: map['content'],
      timestamp: _formatDate(map['timestamp']),
    );
  }
}
