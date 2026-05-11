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
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getAllUsers();
      final patients = await _dbService.getPatients();
      final doctors = await _dbService.getDoctors();
      setState(() {
        _users = users;
        _patients = patients;
        _doctors = doctors;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showEditUserDialog(User user) async {
    final loginController = TextEditingController(text: user.login);
    final passwordController = TextEditingController(text: user.password);
    UserRole selectedRole = user.role;

    // Данные профиля
    final nameController = TextEditingController();
    final specController = TextEditingController();
    final phoneController = TextEditingController();
    final cabinetController = TextEditingController();
    final birthDateController = TextEditingController();

    int? profileId = user.role == UserRole.doctor ? user.doctorId : user.patientId;

    if (user.role == UserRole.doctor && user.doctorId != null) {
      final doc = await _dbService.getDoctorById(user.doctorId!);
      if (doc != null) {
        nameController.text = doc.name;
        specController.text = doc.specialization;
        phoneController.text = doc.phone ?? '';
        cabinetController.text = doc.cabinet ?? '';
      }
    } else if (user.role == UserRole.patient && user.patientId != null) {
      final pat = await _dbService.getPatientById(user.patientId!);
      if (pat != null) {
        nameController.text = pat.name;
        birthDateController.text = pat.birthDate;
      }
    }

    if (!mounted) return;

    final roleDisplayNames = {
      UserRole.admin: 'Администратор',
      UserRole.doctor: 'Врач',
      UserRole.patient: 'Пациент',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактировать пользователя'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Данные входа', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: loginController, decoration: const InputDecoration(labelText: 'Логин')),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                ),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  items: [UserRole.doctor, UserRole.patient, UserRole.admin].map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(roleDisplayNames[role] ?? role.name),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  decoration: const InputDecoration(labelText: 'Роль'),
                ),
                if (selectedRole != UserRole.admin) ...[
                  const SizedBox(height: 20),
                  const Text('Данные профиля', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ФИО')),
                  if (selectedRole == UserRole.doctor) ...[
                    TextField(controller: specController, decoration: const InputDecoration(labelText: 'Специальность')),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
                    TextField(controller: cabinetController, decoration: const InputDecoration(labelText: 'Кабинет')),
                  ],
                  if (selectedRole == UserRole.patient)
                    TextField(
                      controller: birthDateController,
                      decoration: const InputDecoration(labelText: 'Дата рождения (ГГГГ-ММ-ДД)'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(birthDateController.text) ?? DateTime(1980),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Обновляем/Создаем профиль
                  int? newProfileId = profileId;
                  if (selectedRole == UserRole.doctor) {
                    final doc = Doctor(
                      id: profileId,
                      name: nameController.text.trim(),
                      specialization: specController.text.trim(),
                      phone: phoneController.text.trim(),
                      cabinet: cabinetController.text.trim(),
                    );
                    if (profileId != null && user.role == UserRole.doctor) {
                      await _dbService.updateDoctor(doc);
                    } else {
                      newProfileId = await _dbService.insertDoctor(doc);
                    }
                  } else if (selectedRole == UserRole.patient) {
                    final pat = Patient(
                      id: profileId,
                      name: nameController.text.trim(),
                      birthDate: birthDateController.text.trim(),
                      relativeContact: 'Авто-создание',
                    );
                    if (profileId != null && user.role == UserRole.patient) {
                      await _dbService.updatePatient(pat);
                    } else {
                      newProfileId = await _dbService.insertPatient(pat);
                    }
                  }

                  // 2. Обновляем пользователя
                  final updatedUser = User(
                    id: user.id,
                    login: loginController.text.trim(),
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    patientId: selectedRole == UserRole.patient ? newProfileId : null,
                    doctorId: selectedRole == UserRole.doctor ? newProfileId : null,
                  );

                  await _dbService.updateUser(updatedUser);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка обновления: $e')),
                    );
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.patient;

    // Поля для автоматического создания профиля
    final nameController = TextEditingController();
    final specController = TextEditingController(); // Для врача
    final phoneController = TextEditingController(); // Для врача
    final cabinetController = TextEditingController(); // Для врача
    final birthDateController = TextEditingController(); // Для пациента

    final roleDisplayNames = {
      UserRole.admin: 'Администратор',
      UserRole.doctor: 'Врач',
      UserRole.patient: 'Пациент',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Создать аккаунт и профиль'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Данные входа', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: loginController, decoration: const InputDecoration(labelText: 'Логин')),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                  obscureText: true,
                ),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  items: [UserRole.doctor, UserRole.patient, UserRole.admin].map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(roleDisplayNames[role] ?? role.name),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                  decoration: const InputDecoration(labelText: 'Роль'),
                ),
                if (selectedRole != UserRole.admin) ...[
                  const SizedBox(height: 20),
                  const Text('Данные профиля', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ФИО')),
                  if (selectedRole == UserRole.doctor) ...[
                    TextField(controller: specController, decoration: const InputDecoration(labelText: 'Специальность')),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
                    TextField(controller: cabinetController, decoration: const InputDecoration(labelText: 'Кабинет')),
                  ],
                  if (selectedRole == UserRole.patient)
                    TextField(
                      controller: birthDateController,
                      decoration: const InputDecoration(labelText: 'Дата рождения (ГГГГ-ММ-ДД)'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1980),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                if (loginController.text.isEmpty || passwordController.text.isEmpty) return;

                try {
                  int? profileId;
                  if (selectedRole == UserRole.doctor) {
                    profileId = await _dbService.insertDoctor(Doctor(
                      name: nameController.text.trim(),
                      specialization: specController.text.trim(),
                      phone: phoneController.text.trim(),
                      cabinet: cabinetController.text.trim(),
                    ));
                  } else if (selectedRole == UserRole.patient) {
                    profileId = await _dbService.insertPatient(Patient(
                      name: nameController.text.trim(),
                      birthDate: birthDateController.text.trim(),
                      relativeContact: 'Авто-создание',
                    ));
                  }

                  final user = User(
                    login: loginController.text.trim(),
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    patientId: selectedRole == UserRole.patient ? profileId : null,
                    doctorId: selectedRole == UserRole.doctor ? profileId : null,
                  );

                  await _dbService.registerUser(user);

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка создания: $e')),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Пользователи'),
            Tab(icon: Icon(Icons.person), text: 'Пациенты'),
            Tab(icon: Icon(Icons.medical_services), text: 'Врачи'),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(),
          _buildPatientsList(),
          _buildDoctorsList(),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    final roleDisplayNames = {
      UserRole.admin: 'Администратор',
      UserRole.doctor: 'Врач',
      UserRole.patient: 'Пациент',
    };

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                title: Text(user.login),
                subtitle: Text('Роль: ${roleDisplayNames[user.role] ?? user.role.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditUserDialog(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        if (user.login == 'admin') return;
                        final confirmed = await _confirmDelete(
                          'Удаление пользователя',
                          'Вы уверены, что хотите удалить пользователя ${user.login}?',
                        );
                        if (confirmed) {
                          await _dbService.deleteUser(user.id!);
                          _loadData();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showAddUserDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(200, 48),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Добавить пользователя',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientsList() {
    return ListView.builder(
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return ListTile(
          title: Text(patient.name),
          subtitle: Text(patient.birthDate),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await _confirmDelete(
                'Удаление профиля',
                'Вы уверены, что хотите удалить профиль пациента ${patient.name}? Все медицинские данные будут удалены.',
              );
              if (confirmed) {
                await _dbService.deletePatient(patient.id!);
                _loadData();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDoctorsList() {
    return ListView.builder(
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return ListTile(
          title: Text(doctor.name),
          subtitle: Text(doctor.specialization),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await _confirmDelete(
                'Удаление профиля',
                'Вы уверены, что хотите удалить профиль врача ${doctor.name}?',
              );
              if (confirmed) {
                await _dbService.deleteDoctor(doctor.id!);
                _loadData();
              }
            },
          ),
        );
      },
    );
  }
}