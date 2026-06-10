import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/services/database_service.dart';

class PatientEditScreen extends StatefulWidget {
  final Patient patient;
  const PatientEditScreen({super.key, required this.patient});

  @override
  State<PatientEditScreen> createState() => _PatientEditScreenState();
}

class _PatientEditScreenState extends State<PatientEditScreen> {
  final _dbService = DatabaseService();
  late Patient _patient;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final success = await _dbService.updatePatient(_patient);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные пациента успешно сохранены')));
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось сохранить данные. Проверьте соединение с сервером.')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  void _editField(String label, String? currentValue, Function(String) onUpdate, {bool isMultiline = false}) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать: $label'),
        content: TextField(
          controller: controller, 
          maxLines: isMultiline ? 3 : 1,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              setState(() {
                onUpdate(controller.text.trim());
              });
              Navigator.pop(context);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _editDate(String label, String? currentValue, Function(String) onUpdate) async {
    final initialDate = DateTime.tryParse(currentValue ?? '') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        onUpdate(DateFormat('yyyy-MM-dd').format(date));
      });
    }
  }

  void _editDropdown<T>(String label, T? currentValue, List<T> options, Function(T) onUpdate, Map<T, String>? labels) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выбрать: $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(labels != null ? labels[opt]! : opt.toString()),
            trailing: opt == currentValue ? const Icon(Icons.check_rounded, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                onUpdate(opt);
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Редактирование: ${_patient.name}'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded, color: Colors.blue),
              onPressed: _save,
              tooltip: 'Сохранить все изменения',
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard('ЛИЧНЫЕ ДАННЫЕ', [
                _buildTile('ФИО', _patient.name, Icons.badge_outlined, (v) => _patient = _patient.copyWith(name: v)),
                _buildTile('Дата рождения', _patient.birthDate, Icons.cake_outlined, (v) => _patient = _patient.copyWith(birthDate: v), isDate: true),
                _buildTile('Пол', _patient.gender, Icons.wc_rounded, (v) => _patient = _patient.copyWith(gender: v), options: ['Мужской', 'Женский']),
                _buildTile('СНИЛС', _patient.snils, Icons.fingerprint_rounded, (v) => _patient = _patient.copyWith(snils: v)),
                _buildTile('Паспортные данные', _patient.passportData, Icons.description_outlined, (v) => _patient = _patient.copyWith(passportData: v)),
                _buildTile('Телефон', _patient.phone, Icons.phone_android_rounded, (v) => _patient = _patient.copyWith(phone: v)),
                _buildTile('Контакт родственника', _patient.relativeContact, Icons.family_restroom_rounded, (v) => _patient = _patient.copyWith(relativeContact: v)),
                _buildTile('Данные представителя', _patient.representativeData, Icons.supervisor_account_rounded, (v) => _patient = _patient.copyWith(representativeData: v)),
              ]),

              _buildCard('РАЗМЕЩЕНИЕ И ДАТЫ', [
                _buildTile('Корпус', _patient.building, Icons.apartment_rounded, (v) => _patient = _patient.copyWith(building: v)),
                _buildTile('Этаж', _patient.floor, Icons.layers_rounded, (v) => _patient = _patient.copyWith(floor: v)),
                _buildTile('Палата', _patient.roomNumber, Icons.meeting_room_rounded, (v) => _patient = _patient.copyWith(roomNumber: v)),
                _buildTile('Категория номера', _patient.roomCategory, Icons.hotel_class_rounded, (v) => _patient = _patient.copyWith(roomCategory: v)),
                _buildTile('Заезд (план)', _patient.plannedArrival, Icons.calendar_today, (v) => _patient = _patient.copyWith(plannedArrival: v), isDate: true),
                _buildTile('Выезд (план)', _patient.plannedDeparture, Icons.event_busy, (v) => _patient = _patient.copyWith(plannedDeparture: v), isDate: true),
              ]),

              _buildCard('ПУТЕВКА И СЕРВИС', [
                _buildTile('Цель заезда', _patient.arrivalPurpose, Icons.flag_outlined, (v) => _patient = _patient.copyWith(arrivalPurpose: v)),
                _buildTile('Источник направления', _patient.fundingSource, Icons.source_outlined, (v) => _patient = _patient.copyWith(fundingSource: v)),
                _buildTile('Тип питания', _patient.dietType, Icons.restaurant_rounded, (v) => _patient = _patient.copyWith(dietType: v)),
                _buildTile('Особые пожелания', _patient.specialNeeds, Icons.accessible_rounded, (v) => _patient = _patient.copyWith(specialNeeds: v)),
              ]),

              _buildCard('СТАТУС', [
                _buildTile('Статус заезда', _patient.status, Icons.sync_rounded, (v) => _patient = _patient.copyWith(status: v), options: ['active', 'wait_checkin', 'isolated', 'early_checkout', 'completed'], labels: {
                  'active': 'Активен',
                  'wait_checkin': 'Ожидает заезда',
                  'isolated': 'Изоляция',
                  'early_checkout': 'Досрочный выезд',
                  'completed': 'Выписан',
                }),
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile(String label, String? value, IconData icon, Function(String) onUpdate, {bool isDate = false, List<String>? options, Map<String, String>? labels}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.blue[700]),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        labels != null ? (labels[value] ?? value ?? '—') : (value == null || value.isEmpty ? '—' : value),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.edit_rounded, size: 18),
      onTap: () {
        if (isDate) {
          _editDate(label, value, onUpdate);
        } else if (options != null) {
          _editDropdown(label, value, options, onUpdate, labels);
        } else {
          _editField(label, value, onUpdate);
        }
      },
    );
  }
}

extension on Patient {
  Patient copyWith({
    String? name,
    String? birthDate,
    String? gender,
    String? snils,
    String? passportData,
    String? phone,
    String? relativeContact,
    String? representativeData,
    String? building,
    String? floor,
    String? roomNumber,
    String? roomCategory,
    String? plannedArrival,
    String? plannedDeparture,
    String? arrivalPurpose,
    String? fundingSource,
    String? dietType,
    String? specialNeeds,
    String? status,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      snils: snils ?? this.snils,
      passportData: passportData ?? this.passportData,
      phone: phone ?? this.phone,
      relativeContact: relativeContact ?? this.relativeContact,
      representativeData: representativeData ?? this.representativeData,
      photoPath: photoPath,
      doctorId: doctorId,
      skkNumber: skkNumber,
      skkDate: skkDate,
      issuedByLpu: issuedByLpu,
      mainDiagnosisMkb: mainDiagnosisMkb,
      secondaryDiagnosesMkb: secondaryDiagnosesMkb,
      checkInExamination: checkInExamination,
      healthGroup: healthGroup,
      dietTable: dietTable,
      forbiddenProcedures: forbiddenProcedures,
      mobilityRegime: mobilityRegime,
      status: status ?? this.status,
      arrivalPurpose: arrivalPurpose ?? this.arrivalPurpose,
      fundingSource: fundingSource ?? this.fundingSource,
      sanatoriumProfile: sanatoriumProfile,
      plannedArrival: plannedArrival ?? this.plannedArrival,
      plannedDeparture: plannedDeparture ?? this.plannedDeparture,
      roomNumber: roomNumber ?? this.roomNumber,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      bedDaysCount: bedDaysCount,
      roomCategory: roomCategory ?? this.roomCategory,
      dietType: dietType ?? this.dietType,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      lfkGroup: lfkGroup,
      culturalParticipation: culturalParticipation,
      voucherType: voucherType,
      extraServices: extraServices,
      companionData: companionData,
      treatmentEfficiency: treatmentEfficiency,
      treatmentDurationCategory: treatmentDurationCategory,
      benefitCategory: benefitCategory,
      egiszId: egiszId,
      fssReferralId: fssReferralId,
      isEgiszActivated: isEgiszActivated,
      diagnosis: diagnosis,
      contraindications: contraindications,
      treatmentGoals: treatmentGoals,
      dynamics: dynamics,
      finalRecommendations: finalRecommendations,
    );
  }
}
