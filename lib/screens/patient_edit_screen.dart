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
  final _formKey = GlobalKey<FormState>();

  // 1. Личные данные
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  late TextEditingController _snilsController;
  late TextEditingController _passportController;
  late TextEditingController _phoneController;
  late TextEditingController _contactController;
  late TextEditingController _representativeController;
  String? _gender;

  // 2. Размещение и Даты
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _roomNumberController;
  late TextEditingController _roomCategoryController;
  late TextEditingController _plannedArrivalController;
  late TextEditingController _plannedDepartureController;
  late TextEditingController _actualArrivalController;
  late TextEditingController _actualDepartureController;

  // 3. Путевка и Сервис
  late TextEditingController _arrivalPurposeController;
  late TextEditingController _fundingSourceController;
  late TextEditingController _voucherTypeController;
  late TextEditingController _dietTypeController;
  late TextEditingController _specialNeedsController;
  late TextEditingController _extraServicesController;
  late TextEditingController _companionController;

  // 4. Статусы и интеграция
  String? _status;
  late TextEditingController _egiszIdController;
  late TextEditingController _fssReferralIdController;
  bool _isEgiszActivated = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;

    _nameController = TextEditingController(text: p.name);
    _birthDateController = TextEditingController(text: p.birthDate);
    _snilsController = TextEditingController(text: p.snils);
    _passportController = TextEditingController(text: p.passportData);
    _phoneController = TextEditingController(text: p.phone);
    _contactController = TextEditingController(text: p.relativeContact);
    _representativeController = TextEditingController(text: p.representativeData);
    _gender = p.gender;

    _buildingController = TextEditingController(text: p.building);
    _floorController = TextEditingController(text: p.floor);
    _roomNumberController = TextEditingController(text: p.roomNumber);
    _roomCategoryController = TextEditingController(text: p.roomCategory);
    _plannedArrivalController = TextEditingController(text: p.plannedArrival);
    _plannedDepartureController = TextEditingController(text: p.plannedDeparture);
    _actualArrivalController = TextEditingController(text: p.actualArrival);
    _actualDepartureController = TextEditingController(text: p.actualDeparture);

    _arrivalPurposeController = TextEditingController(text: p.arrivalPurpose);
    _fundingSourceController = TextEditingController(text: p.fundingSource);
    _voucherTypeController = TextEditingController(text: p.voucherType);
    _dietTypeController = TextEditingController(text: p.dietType);
    _specialNeedsController = TextEditingController(text: p.specialNeeds);
    _extraServicesController = TextEditingController(text: p.extraServices);
    _companionController = TextEditingController(text: p.companionData);

    _status = p.status;
    _egiszIdController = TextEditingController(text: p.egiszId);
    _fssReferralIdController = TextEditingController(text: p.fssReferralId);
    _isEgiszActivated = p.isEgiszActivated;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = Patient(
      id: widget.patient.id,
      name: _nameController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      gender: _gender,
      snils: _snilsController.text.trim(),
      passportData: _passportController.text.trim(),
      phone: _phoneController.text.trim(),
      relativeContact: _contactController.text.trim(),
      representativeData: _representativeController.text.trim(),
      photoPath: widget.patient.photoPath,

      building: _buildingController.text.trim(),
      floor: _floorController.text.trim(),
      roomNumber: _roomNumberController.text.trim(),
      roomCategory: _roomCategoryController.text.trim(),
      plannedArrival: _plannedArrivalController.text.trim(),
      plannedDeparture: _plannedDepartureController.text.trim(),
      actualArrival: _actualArrivalController.text.trim(),
      actualDeparture: _actualDepartureController.text.trim(),

      arrivalPurpose: _arrivalPurposeController.text.trim(),
      fundingSource: _fundingSourceController.text.trim(),
      voucherType: _voucherTypeController.text.trim(),
      dietType: _dietTypeController.text.trim(),
      specialNeeds: _specialNeedsController.text.trim(),
      extraServices: _extraServicesController.text.trim(),
      companionData: _companionController.text.trim(),

      status: _status ?? 'active',
      egiszId: _egiszIdController.text.trim(),
      fssReferralId: _fssReferralIdController.text.trim(),
      isEgiszActivated: _isEgiszActivated,

      // Сохраняем медицинские поля и поля ЭМК без изменений (они редактируются в ЭМК)
      doctorId: widget.patient.doctorId,
      bedDaysCount: widget.patient.bedDaysCount,
      skkNumber: widget.patient.skkNumber,
      skkDate: widget.patient.skkDate,
      issuedByLpu: widget.patient.issuedByLpu,
      mainDiagnosisMkb: widget.patient.mainDiagnosisMkb,
      secondaryDiagnosesMkb: widget.patient.secondaryDiagnosesMkb,
      checkInExamination: widget.patient.checkInExamination,
      healthGroup: widget.patient.healthGroup,
      dietTable: widget.patient.dietTable,
      forbiddenProcedures: widget.patient.forbiddenProcedures,
      mobilityRegime: widget.patient.mobilityRegime,
      sanatoriumProfile: widget.patient.sanatoriumProfile,
      lfkGroup: widget.patient.lfkGroup,
      culturalParticipation: widget.patient.culturalParticipation,
      treatmentEfficiency: widget.patient.treatmentEfficiency,
      treatmentDurationCategory: widget.patient.treatmentDurationCategory,
      benefitCategory: widget.patient.benefitCategory,
      diagnosis: widget.patient.diagnosis,
      contraindications: widget.patient.contraindications,
      treatmentGoals: widget.patient.treatmentGoals,
      dynamics: widget.patient.dynamics,
      finalRecommendations: widget.patient.finalRecommendations,
    );

    try {
      await _dbService.updatePatient(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль пациента обновлен')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование данных'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('ЛИЧНЫЕ ДАННЫЕ'),
            _buildTextField(_nameController, 'ФИО', Icons.badge_outlined),
            _buildTextField(_birthDateController, 'Дата рождения', Icons.cake_outlined, readOnly: true, onTap: () => _selectDate(_birthDateController)),
            _buildDropdown<String>('Пол', _gender, ['Мужской', 'Женский'], (v) => setState(() => _gender = v), Icons.wc_rounded),
            _buildTextField(_snilsController, 'СНИЛС', Icons.fingerprint_rounded),
            _buildTextField(_passportController, 'Паспортные данные', Icons.description_outlined),
            _buildTextField(_phoneController, 'Телефон', Icons.phone_android_rounded),
            _buildTextField(_contactController, 'Контакт родственника', Icons.family_restroom_rounded),
            _buildTextField(_representativeController, 'Данные представителя', Icons.supervisor_account_rounded),

            const SizedBox(height: 24),
            _buildSectionTitle('РАЗМЕЩЕНИЕ И ДАТЫ'),
            Row(
              children: [
                Expanded(child: _buildTextField(_buildingController, 'Корпус', Icons.apartment_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_floorController, 'Этаж', Icons.layers_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(_roomNumberController, 'Палата', Icons.meeting_room_rounded)),
              ],
            ),
            _buildTextField(_roomCategoryController, 'Категория номера', Icons.hotel_class_rounded),
            Row(
              children: [
                Expanded(child: _buildTextField(_plannedArrivalController, 'Заезд (план)', Icons.calendar_today, readOnly: true, onTap: () => _selectDate(_plannedArrivalController))),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_plannedDepartureController, 'Выезд (план)', Icons.event_busy, readOnly: true, onTap: () => _selectDate(_plannedDepartureController))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildTextField(_actualArrivalController, 'Заезд (факт)', Icons.login_rounded, readOnly: true, onTap: () => _selectDate(_actualArrivalController))),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_actualDepartureController, 'Выезд (факт)', Icons.logout_rounded, readOnly: true, onTap: () => _selectDate(_actualDepartureController))),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('ПУТЕВКА И СЕРВИС'),
            _buildTextField(_arrivalPurposeController, 'Цель заезда', Icons.flag_outlined),
            _buildTextField(_fundingSourceController, 'Источник направления', Icons.source_outlined),
            _buildTextField(_voucherTypeController, 'Тип путевки', Icons.confirmation_number_rounded),
            _buildTextField(_dietTypeController, 'Тип питания (быт)', Icons.restaurant_rounded),
            _buildTextField(_specialNeedsController, 'Особые пожелания', Icons.accessible_rounded),
            _buildTextField(_extraServicesController, 'Доп. услуги', Icons.add_shopping_cart_rounded),
            _buildTextField(_companionController, 'Данные сопровождающего', Icons.group_add_rounded),

            const SizedBox(height: 24),
            _buildSectionTitle('СТАТУС И ИНТЕГРАЦИЯ'),
            _buildStatusDropdown(),
            _buildTextField(_egiszIdController, 'ID ЕГИСЗ', Icons.fingerprint_rounded),
            _buildTextField(_fssReferralIdController, 'ID направления ФСС', Icons.link_rounded),
            SwitchListTile(
              title: const Text('Передано в ЕГИСЗ'),
              secondary: const Icon(Icons.verified_user_rounded),
              value: _isEgiszActivated,
              onChanged: (v) => setState(() => _isEgiszActivated = v),
            ),

            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Сохранить изменения'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[800], letterSpacing: 1.2)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (v) => (label == 'ФИО' || label == 'Дата рождения') && (v == null || v.isEmpty) ? 'Обязательное поле' : null,
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, ValueChanged<T?> onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString()))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final Map<String, String> statusMap = {
      'active': 'Активен',
      'wait_checkin': 'Ожидает заезда',
      'isolated': 'Изоляция',
      'early_checkout': 'Досрочный выезд',
      'completed': 'Выписан',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _status,
        items: statusMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) => setState(() => _status = v),
        decoration: InputDecoration(
          labelText: 'Статус заезда',
          prefixIcon: const Icon(Icons.sync_rounded, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => controller.text = DateFormat('yyyy-MM-dd').format(date));
    }
  }
}
