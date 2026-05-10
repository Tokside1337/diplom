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

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _dbService = DatabaseService();
  bool _isLoading = true;
  List<User> _users = [];
  List<Patient> _patients = [];
  List<Doctor> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
                  initialValue: selectedRole,
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

  // Остальные методы _showAddPatientDialog и _showAddDoctorDialog можно оставить для ручного создания без аккаунта
  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final birthDateController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить пациента'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ФИО')),
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
            TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Контакт')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                await _dbService.insertPatient(Patient(
                  name: nameController.text.trim(),
                  birthDate: birthDateController.text.trim(),
                  relativeContact: contactController.text.trim(),
                ));
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Добавить'),
            ),
        ],
      ),
    );
  }

  void _showAddDoctorDialog() {
    final nameController = TextEditingController();
    final specController = TextEditingController();
    final phoneController = TextEditingController();
    final cabinetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить врача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'ФИО')),
            TextField(controller: specController, decoration: const InputDecoration(labelText: 'Специальность')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
            TextField(controller: cabinetController, decoration: const InputDecoration(labelText: 'Кабинет')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                await _dbService.insertDoctor(Doctor(
                  name: nameController.text.trim(),
                  specialization: specController.text.trim(),
                  phone: phoneController.text.trim(),
                  cabinet: cabinetController.text.trim(),
                ));
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Добавить'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель администратора'),
          bottom: const TabBar(
            tabs: [
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
                children: [
                  _buildUsersList(),
                  _buildPatientsList(),
                  _buildDoctorsList(),
                ],
              ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () {
              final tabIndex = DefaultTabController.of(context).index;
              if (tabIndex == 0) {
                _showAddUserDialog();
              } else if (tabIndex == 1) {
                _showAddPatientDialog();
              } else if (tabIndex == 2) {
                _showAddDoctorDialog();
              }
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    final roleDisplayNames = {
      UserRole.admin: 'Администратор',
      UserRole.doctor: 'Врач',
      UserRole.patient: 'Пациент',
    };
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          title: Text(user.login),
          subtitle: Text('Роль: ${roleDisplayNames[user.role] ?? user.role.name}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              if (user.login == 'admin') return; // Запрет удаления админа
              await _dbService.deleteUser(user.id!);
              _loadData();
            },
          ),
        );
      },
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
              await _dbService.deletePatient(patient.id!);
              _loadData();
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
              await _dbService.deleteDoctor(doctor.id!);
              _loadData();
            },
          ),
        );
      },
    );
  }
}
