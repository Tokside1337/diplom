class Diagnosis {
  final int? id;
  final int patientId;
  final String description;
  final String date;

  Diagnosis({this.id, required this.patientId, required this.description, required this.date});

  Map<String, dynamic> toMap() => {'id': id, 'patientId': patientId, 'description': description, 'date': date};

  factory Diagnosis.fromMap(Map<String, dynamic> map) => Diagnosis(
    id: map['id'],
    patientId: map['patientId'],
    description: map['description'],
    date: map['date'],
  );
}

class Appointment {
  final int? id;
  final int patientId;
  final String type; // Procedure, LFK, Medication
  final String title;
  final String time;
  final String room;
  final String doctor;

  Appointment({this.id, required this.patientId, required this.type, required this.title, required this.time, required this.room, required this.doctor});

  Map<String, dynamic> toMap() => {'id': id, 'patientId': patientId, 'type': type, 'title': title, 'time': time, 'room': room, 'doctor': doctor};

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
    id: map['id'],
    patientId: map['patientId'],
    type: map['type'],
    title: map['title'],
    time: map['time'],
    room: map['room'],
    doctor: map['doctor'],
  );
}

class Measurement {
  final int? id;
  final int patientId;
  final double pressureSystolic;
  final double pressureDiastolic;
  final int pulse;
  final int painLevel; // 0-10
  final String timestamp;

  Measurement({this.id, required this.patientId, required this.pressureSystolic, required this.pressureDiastolic, required this.pulse, required this.painLevel, required this.timestamp});

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'pressureSystolic': pressureSystolic,
    'pressureDiastolic': pressureDiastolic,
    'pulse': pulse,
    'painLevel': painLevel,
    'timestamp': timestamp,
  };

  factory Measurement.fromMap(Map<String, dynamic> map) => Measurement(
    id: map['id'],
    patientId: map['patientId'],
    pressureSystolic: map['pressureSystolic'],
    pressureDiastolic: map['pressureDiastolic'],
    pulse: map['pulse'],
    painLevel: map['painLevel'],
    timestamp: map['timestamp'],
  );
}

class MoodEntry {
  final int? id;
  final int patientId;
  final int score; // 1-5
  final String comment;
  final String timestamp;
  final String? sentiment; // AI analyzed

  MoodEntry({this.id, required this.patientId, required this.score, required this.comment, required this.timestamp, this.sentiment});

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'score': score,
    'comment': comment,
    'timestamp': timestamp,
    'sentiment': sentiment,
  };

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
    id: map['id'],
    patientId: map['patientId'],
    score: map['score'],
    comment: map['comment'],
    timestamp: map['timestamp'],
    sentiment: map['sentiment'],
  );
}
