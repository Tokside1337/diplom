class MedicalNote {
  final int? id;
  final int patientId;
  final String author; // Doctor, Psychologist, Instructor
  final String content;
  final String timestamp;

  MedicalNote({this.id, required this.patientId, required this.author, required this.content, required this.timestamp});

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'author': author,
    'content': content,
    'timestamp': timestamp,
  };
}

class Event {
  final String title;
  final DateTime dateTime;
  final String type; // Group therapy, Event

  Event({required this.title, required this.dateTime, required this.type});
}
