class DoctorModel {
  final int? id;
  final String name;
  final String specialization;
  final String? phone;
  final String? cabinet;

  DoctorModel({
    this.id,
    required this.name,
    required this.specialization,
    this.phone,
    this.cabinet,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'phone': phone,
      'cabinet': cabinet,
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'],
      name: map['name'],
      specialization: map['specialization'],
      phone: map['phone'],
      cabinet: map['cabinet'],
    );
  }
}
