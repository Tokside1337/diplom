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
      'patient_id': patientId,
      'author': author,
      'content': content,
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

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      patientId: map['patient_id'] ?? map['patientId'] ?? 0,
      author: map['author'] ?? '',
      content: map['content'] ?? '',
      timestamp: _formatDate(map['timestamp']),
    );
  }
}
