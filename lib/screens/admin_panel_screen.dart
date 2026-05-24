import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<User> _users = [];
  List<Patient> _patients = [];
  List<Doctor> _doctors = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getAllUsers();
      final patients = await _dbService.getPatients();
      final doctors = await _dbService.getDoctors();
      if (mounted) {
        setState(() {
          _users = users;
          _patients = patients;
          _doctors = doctors;
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

  Future<bool> _confirmDelete(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(76),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  void _showUserDialog({User? user, Patient? patient, Doctor? doctor}) async {
    final isEditing = user != null || patient != null || doctor != null;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    User? targetUser = user;
    if (targetUser == null && patient != null) {
      try { targetUser = _users.firstWhere((u) => u.patientId == patient.id); } catch(_) {}
    } else if (targetUser == null && doctor != null) {
      try { targetUser = _users.firstWhere((u) => u.doctorId == doctor.id); } catch(_) {}
    }

    final loginController = TextEditingController(text: targetUser?.login);
    final passwordController = TextEditingController(text: targetUser?.password);
    UserRole selectedRole = targetUser?.role ?? (patient != null ? UserRole.patient : (doctor != null ? UserRole.doctor : UserRole.patient));

    final nameController = TextEditingController();
    final specController = TextEditingController();
    final phoneController = TextEditingController();
    final cabinetController = TextEditingController();
    final birthDateController = TextEditingController();
    final contactController = TextEditingController();
    int? selectedDoctorId;

    int? profileId = patient?.id ?? doctor?.id ?? (targetUser?.role == UserRole.doctor ? targetUser?.doctorId : targetUser?.patientId);

    if (patient != null) {
      nameController.text = patient.name;
      birthDateController.text = patient.birthDate;
      contactController.text = patient.relativeContact;
      selectedDoctorId = patient.doctorId;
    } else if (doctor != null) {
      nameController.text = doctor.name;
      specController.text = doctor.specialization;
      phoneController.text = doctor.phone ?? '';
      cabinetController.text = doctor.cabinet ?? '';
    } else if (targetUser != null) {
      if (targetUser.role == UserRole.doctor && targetUser.doctorId != null) {
        final doc = await _dbService.getDoctorById(targetUser.doctorId!);
        if (doc != null) {
          nameController.text = doc.name;
          specController.text = doc.specialization;
          phoneController.text = doc.phone ?? '';
          cabinetController.text = doc.cabinet ?? '';
        }
      } else if (targetUser.role == UserRole.patient && targetUser.patientId != null) {
        final pat = await _dbService.getPatientById(targetUser.patientId!);
        if (pat != null) {
          nameController.text = pat.name;
          birthDateController.text = pat.birthDate;
          contactController.text = pat.relativeContact;
          selectedDoctorId = pat.doctorId;
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing ? 'Редактирование' : 'Новый профиль',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: (screenWidth - 60).clamp(240.0, 380.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogSectionTitle(context, 'ДАННЫЕ АККАУНТА'),
                  _buildField(
                    controller: loginController,
                    label: 'Логин',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: passwordController,
                    label: 'Пароль',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Роль',
                      prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withAlpha(76),
                      contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: UserRole.values.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                  if (selectedRole != UserRole.admin) ...[
                    const SizedBox(height: 20),
                    _dialogSectionTitle(context, 'ЛИЧНЫЕ ДАННЫЕ'),
                    _buildField(
                      controller: nameController,
                      label: 'ФИО',
                      icon: Icons.face_rounded,
                    ),
                    if (selectedRole == UserRole.doctor) ...[
                      const SizedBox(height: 12),
                      _buildField(
                        controller: specController,
                        label: 'Специальность',
                        icon: Icons.medical_services_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildField(
                              controller: phoneController,
                              label: 'Телефон',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildField(
                              controller: cabinetController,
                              label: 'Каб.',
                              icon: Icons.meeting_room_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (selectedRole == UserRole.patient) ...[
                      const SizedBox(height: 12),
                      _buildField(
                        controller: birthDateController,
                        label: 'Дата рождения',
                        icon: Icons.cake_outlined,
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1990),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: contactController,
                        label: 'Контакт родственника',
                        icon: Icons.contact_phone_outlined,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedDoctorId,
                        isExpanded: true,
                        isDense: true,
                        decoration: InputDecoration(
                          labelText: 'Лечащий врач',
                          prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withAlpha(76),
                          contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null, 
                            child: Text('Не назначен', overflow: TextOverflow.ellipsis)
                          ),
                          ..._doctors.map((doc) => DropdownMenuItem<int?>(
                            value: doc.id,
                            child: Text(doc.name, overflow: TextOverflow.ellipsis),
                          )),
                        ],
                        onChanged: (val) => setDialogState(() => selectedDoctorId = val),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                try {
                  int? newProfileId = profileId;
                  if (selectedRole == UserRole.doctor) {
                    final doc = Doctor(
                      id: profileId,
                      name: nameController.text.trim(),
                      specialization: specController.text.trim(),
                      phone: phoneController.text.trim(),
                      cabinet: cabinetController.text.trim(),
                    );
                    if (isEditing && (targetUser?.role == UserRole.doctor || doctor != null)) {
                      await _dbService.updateDoctor(doc);
                    } else {
                      newProfileId = await _dbService.insertDoctor(doc);
                    }
                  } else if (selectedRole == UserRole.patient) {
                    final pat = Patient(
                      id: profileId,
                      name: nameController.text.trim(),
                      birthDate: birthDateController.text.trim(),
                      relativeContact: contactController.text.trim().isEmpty ? 'Не указан' : contactController.text.trim(),
                      doctorId: selectedDoctorId,
                      diagnosis: patient?.diagnosis,
                      contraindications: patient?.contraindications,
                      treatmentGoals: patient?.treatmentGoals,
                      dynamics: patient?.dynamics,
                      finalRecommendations: patient?.finalRecommendations,
                    );
                    if (isEditing && (targetUser?.role == UserRole.patient || patient != null)) {
                      await _dbService.updatePatient(pat);
                    } else {
                      newProfileId = await _dbService.insertPatient(pat);
                    }
                  }

                  final userData = User(
                    id: targetUser?.id,
                    login: loginController.text.trim(),
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    patientId: selectedRole == UserRole.patient ? newProfileId : null,
                    doctorId: selectedRole == UserRole.doctor ? newProfileId : null,
                  );

                  if (isEditing && targetUser != null) {
                    await _dbService.updateUser(userData);
                  } else {
                    await _dbService.registerUser(userData);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              icon: Icon(isEditing ? Icons.check_rounded : Icons.person_add_rounded, size: 18),
              label: Text(isEditing ? 'Сохранить' : 'Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Аккаунты'), Tab(text: 'Пациенты'), Tab(text: 'Врачи')],
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded)),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(_users, _buildUserTile),
                _buildListView(_patients, _buildPatientTile),
                _buildListView(_doctors, _buildDoctorTile),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        label: const Text('Добавить'),
        icon: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Widget _buildListView<T>(List<T> items, Widget Function(T) tileBuilder) {
    if (items.isEmpty) return const Center(child: Text('Нет данных'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => tileBuilder(items[index]),
    );
  }

  Widget _buildUserTile(User user) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128))),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorScheme.surfaceContainerHighest, child: Icon(Icons.account_circle_outlined, color: colorScheme.primary)),
        title: Text(user.login, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Роль: ${user.role.displayName}'),
        trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showUserDialog(user: user)),
      ),
    );
  }

  Widget _buildPatientTile(Patient p) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128))),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorScheme.primaryContainer, child: Icon(Icons.person_outline, color: colorScheme.onPrimaryContainer)),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${p.birthDate} • ${p.relativeContact}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showUserDialog(patient: p),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (await _confirmDelete('Удаление', 'Удалить профиль ${p.name}?')) {
                  await _dbService.deletePatient(p.id!);
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorTile(Doctor d) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128))),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorScheme.tertiaryContainer, child: Icon(Icons.medical_services_outlined, color: colorScheme.onTertiaryContainer)),
        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(d.specialization),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showUserDialog(doctor: d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (await _confirmDelete('Удаление', 'Удалить профиль врача ${d.name}?')) {
                  await _dbService.deleteDoctor(d.id!);
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
