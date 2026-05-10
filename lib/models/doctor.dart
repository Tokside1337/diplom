class Doctor {
  final int? id;
  final String name;           // ФИО
  final String specialization; // Специальность
  final String? phone;         // Телефон
  final String? cabinet;       // Кабинет

  Doctor({
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

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name'],
      specialization: map['specialization'],
      phone: map['phone'],
      cabinet: map['cabinet'],
    );
  }
}
