class Patient {
  final int? id;
  final String name;
  final String birthDate;
  final String? photoPath;
  final String relativeContact;
  final int? doctorId;
  final String? diagnosis;
  final String? contraindications;
  final String? treatmentGoals;
  final String? dynamics;
  final String? finalRecommendations;

  Patient({
    this.id,
    required this.name,
    required this.birthDate,
    this.photoPath,
    required this.relativeContact,
    this.doctorId,
    this.diagnosis,
    this.contraindications,
    this.treatmentGoals,
    this.dynamics,
    this.finalRecommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'photoPath': photoPath,
      'relativeContact': relativeContact,
      'doctor_id': doctorId,
      'diagnosis': diagnosis,
      'contraindications': contraindications,
      'treatment_goals': treatmentGoals,
      'dynamics': dynamics,
      'final_recommendations': finalRecommendations,
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
      diagnosis: map['diagnosis'],
      contraindications: map['contraindications'],
      treatmentGoals: map['treatment_goals'],
      dynamics: map['dynamics'],
      finalRecommendations: map['final_recommendations'],
    );
  }
}
