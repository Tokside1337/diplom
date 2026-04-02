class Patient {
  final int? id;
  final String name;
  final String birthDate;
  final String? photoPath;
  final String relativeContact;

  Patient({
    this.id,
    required this.name,
    required this.birthDate,
    this.photoPath,
    required this.relativeContact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'photoPath': photoPath,
      'relativeContact': relativeContact,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      birthDate: map['birthDate'],
      photoPath: map['photoPath'],
      relativeContact: map['relativeContact'],
    );
  }
}
