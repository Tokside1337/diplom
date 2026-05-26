import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/emk_model.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/services/pdf_service.dart';

class EMKScreen extends StatefulWidget {
  final Patient patient;
  final bool isDoctor;

  const EMKScreen({super.key, required this.patient, required this.isDoctor});

  @override
  State<EMKScreen> createState() => _EMKScreenState();
}

class _EMKScreenState extends State<EMKScreen> {
  final _dbService = DatabaseService();
  EMK? _emk;
  late Patient _patient;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final emkFuture = _dbService.getEMK(widget.patient.id!);
      final patientFuture = _dbService.getPatientById(widget.patient.id!);
      
      final results = await Future.wait([emkFuture, patientFuture]);
      
      if (mounted) {
        setState(() {
          _emk = (results[0] as EMK?) ??
              EMK(
                patientId: widget.patient.id!,
                createdAt: DateTime.now().toIso8601String(),
              );
          if (results[1] != null) {
            _patient = results[1] as Patient;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  Future<void> _saveAll() async {
    if (_emk == null || _isSaving) return;
    
    setState(() => _isSaving = true);
    try {
      // 1. Save EMK
      await _dbService.saveEMK(_emk!);
      
      // 2. Save Patient (which contains СКК fields)
      await _dbService.updatePatient(_patient);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Все данные успешно сохранены')));
        setState(() => _isSaving = false);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  void _editMedicalField(String label, String? currentValue, Function(String) onUpdate) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать: $label'),
        content: TextField(
          controller: controller, 
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final newValue = controller.text.trim();
              setState(() {
                onUpdate(newValue);
              });
              Navigator.pop(context);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _editEMKField(Map<String, dynamic> section, String field) {
    final controller = TextEditingController(text: section[field]?.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать: $field'),
        content: TextField(
          controller: controller, 
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              setState(() {
                section[field] = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _addEMKLogEntry(List<dynamic> list) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая запись'),
        content: TextField(
          controller: controller, 
          maxLines: 3, 
          decoration: InputDecoration(
            hintText: 'Введите данные осмотра...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  list.add('${DateFormat('dd.MM HH:mm').format(DateTime.now())}: ${controller.text.trim()}');
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('ЭМК: ${_patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => PdfService.printEMK(_emk!, _patient),
            tooltip: 'Печать ЭМК',
          ),
          if (widget.isDoctor)
            _isSaving 
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : IconButton(
                  icon: const Icon(Icons.save_rounded, color: Colors.blue),
                  onPressed: _saveAll,
                  tooltip: 'Сохранить все изменения',
                )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMedicalInfoSection(),
              _buildSection('2. ДИАГНОЗЫ (КЛИНИЧЕСКИЕ)', _emk!.diagnoses, [
                'Основной диагноз',
                'Сопутствующие',
                'Осложнения',
                'Направление',
                'Функциональный (МКФ)'
              ]),
              _buildSection('3. ПРОТИВОПОКАЗАНИЯ (БЛОКИРОВКА)', _emk!.contraindications, [
                'Абсолютные',
                'Относительные',
                'Аллергены',
                'Запрещенные процедуры IDs',
                'Макс. нагрузка (кг)'
              ]),
              _buildSection('4. ЦЕЛИ ЛЕЧЕНИЯ (SMART)', _emk!.treatmentGoals, [
                'Потенциал (high/medium/low)',
                'SMART-цели',
                'Шкалы на входе (MRC, Berg, Barthel)',
                'Приоритеты'
              ]),
              _buildListSection('5.1 ЕЖЕДНЕВНЫЕ ЗАПИСИ (ДНЕВНИК)', _emk!.dailyLogs),
              _buildListSection('5.2 ЭТАПНЫЕ ОСМОТРЫ', _emk!.stageReviews),
              _buildSection('6. ИТОГОВЫЕ РЕКОМЕНДАЦИИ', _emk!.finalRecommendations, [
                'Эпикриз',
                'Итоговый статус',
                'Домашний режим',
                'Лекарства'
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('1. САНАТОРНО-КУРОРТНАЯ КАРТА (СКК)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          ),
          _buildMedicalTile('Номер СКК', _patient.skkNumber, Icons.history_edu_rounded, 'skkNumber'),
          _buildMedicalTile('Дата выдачи', _patient.skkDate, Icons.calendar_month_rounded, 'skkDate'),
          _buildMedicalTile('Кем выдана', _patient.issuedByLpu, Icons.account_balance_rounded, 'issuedByLpu'),
          _buildMedicalTile('Основной диагноз (МКБ)', _patient.mainDiagnosisMkb, Icons.medical_services_rounded, 'mainDiagnosisMkb'),
          _buildMedicalTile('Диет. стол (по Певзнеру)', _patient.dietTable, Icons.restaurant_rounded, 'dietTable'),
          _buildMedicalTile('Двигательный режим', _patient.mobilityRegime, Icons.directions_run_rounded, 'mobilityRegime'),
          _buildMedicalTile('Группа здоровья', _patient.healthGroup, Icons.health_and_safety_rounded, 'healthGroup'),
          _buildMedicalTile('Запрещенные процедуры', _patient.forbiddenProcedures, Icons.block_rounded, 'forbiddenProcedures'),
        ],
      ),
    );
  }

  Widget _buildMedicalTile(String label, String? value, IconData icon, String fieldName) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.blue[700]),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: widget.isDoctor ? const Icon(Icons.edit_rounded, size: 18) : null,
      onTap: widget.isDoctor ? () => _editMedicalField(label, value, (val) {
        _patient = _updatePatientLocalField(_patient, fieldName, val);
      }) : null,
    );
  }

  Patient _updatePatientLocalField(Patient p, String fieldName, String value) {
    return Patient(
      id: p.id,
      name: p.name,
      birthDate: p.birthDate,
      relativeContact: p.relativeContact,
      doctorId: p.doctorId,
      gender: p.gender,
      snils: p.snils,
      passportData: p.passportData,
      phone: p.phone,
      representativeData: p.representativeData,
      photoPath: p.photoPath,
      skkNumber: fieldName == 'skkNumber' ? value : p.skkNumber,
      skkDate: fieldName == 'skkDate' ? value : p.skkDate,
      issuedByLpu: fieldName == 'issuedByLpu' ? value : p.issuedByLpu,
      mainDiagnosisMkb: fieldName == 'mainDiagnosisMkb' ? value : p.mainDiagnosisMkb,
      secondaryDiagnosesMkb: p.secondaryDiagnosesMkb,
      checkInExamination: fieldName == 'checkInExamination' ? value : p.checkInExamination,
      healthGroup: fieldName == 'healthGroup' ? value : p.healthGroup,
      dietTable: fieldName == 'dietTable' ? value : p.dietTable,
      forbiddenProcedures: fieldName == 'forbiddenProcedures' ? value : p.forbiddenProcedures,
      mobilityRegime: fieldName == 'mobilityRegime' ? value : p.mobilityRegime,
      status: p.status,
      arrivalPurpose: p.arrivalPurpose,
      fundingSource: p.fundingSource,
      sanatoriumProfile: p.sanatoriumProfile,
      plannedArrival: p.plannedArrival,
      plannedDeparture: p.plannedDeparture,
      actualArrival: p.actualArrival,
      actualDeparture: p.actualDeparture,
      roomNumber: p.roomNumber,
      building: p.building,
      floor: p.floor,
      bedDaysCount: p.bedDaysCount,
      roomCategory: p.roomCategory,
      dietType: p.dietType,
      specialNeeds: p.specialNeeds,
      lfkGroup: p.lfkGroup,
      culturalParticipation: p.culturalParticipation,
      voucherType: p.voucherType,
      extraServices: p.extraServices,
      companionData: p.companionData,
      treatmentEfficiency: p.treatmentEfficiency,
      treatmentDurationCategory: p.treatmentDurationCategory,
      benefitCategory: p.benefitCategory,
      egiszId: p.egiszId,
      fssReferralId: p.fssReferralId,
      isEgiszActivated: p.isEgiszActivated,
      diagnosis: p.diagnosis,
      contraindications: p.contraindications,
      treatmentGoals: p.treatmentGoals,
      dynamics: p.dynamics,
      finalRecommendations: p.finalRecommendations,
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data, List<String> fields) {
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
          ...fields.map((f) => ListTile(
                title: Text(f, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(data[f]?.toString() ?? 'Не заполнено'),
                trailing: widget.isDoctor ? const Icon(Icons.edit_rounded, size: 18) : null,
                onTap: widget.isDoctor ? () => _editEMKField(data, f) : null,
              )),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                if (widget.isDoctor)
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addEMKLogEntry(list))
              ],
            ),
          ),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Записей нет', style: TextStyle(fontStyle: FontStyle.italic))),
          ...list.map((item) => ListTile(
                title: Text(item.toString()),
                dense: true,
              )),
        ],
      ),
    );
  }
}
