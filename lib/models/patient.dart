class Patient {
  final int? id;
  final String name;
  final String birthDate;
  final String? photoPath;
  final String relativeContact;
  final int? doctorId; // New field for linked doctor

  Patient({
    this.id,
    required this.name,
    required this.birthDate,
    this.photoPath,
    required this.relativeContact,
    this.doctorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'photoPath': photoPath,
      'relativeContact': relativeContact,
      'doctor_id': doctorId,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      birthDate: map['birthDate'],
      photoPath: map['photoPath'],
      relativeContact: map['relativeContact'],
      doctorId: map['doctor_id'],
    );
  }
}
