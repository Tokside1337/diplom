import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'patient_list_screen.dart';
import 'patient_main_screen.dart'; // Изменено на MainScreen
import '../models/patient.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final user = await _dbService.loginUser(
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (!mounted) return;
        if (user.role == UserRole.doctor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PatientListScreen()),
          );
        } else if (user.role == UserRole.patient && user.patientId != null) {
          final patients = await _dbService.getPatients();
          final patient = patients.firstWhere((p) => p.id == user.patientId);
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PatientMainScreen(patient: patient)),
          );
        }
else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: Данные пациента не найдены')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный логин или пароль')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Система Реабилитации',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Войти'),
                    ),
              TextButton(
                onPressed: _goToRegister,
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Patient profile fields
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _contactController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  final _dbService = DatabaseService();
  bool _isLoading = false;

  void _register() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните логин и пароль')),
      );
      return;
    }

    if (_selectedRole == UserRole.patient) {
      if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заполните данные профиля пациента')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      int? patientId;

      if (_selectedRole == UserRole.patient) {
        // 1. Create Patient profile
        patientId = await _dbService.insertPatient(Patient(
          name: _nameController.text.trim(),
          birthDate: _birthDateController.text.trim(),
          relativeContact: _contactController.text.trim(),
        ));
      }

      // 2. Create User account
      await _dbService.registerUser(User(
        login: login,
        password: password,
        role: _selectedRole,
        patientId: patientId,
      ));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация успешна')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Данные аккаунта', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Логин', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Роль', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: UserRole.doctor, child: Text('Врач')),
                DropdownMenuItem(value: UserRole.patient, child: Text('Пациент')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            if (_selectedRole == UserRole.patient) ...[
              const SizedBox(height: 32),
              const Text('Профиль пациента', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ФИО пациента', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _birthDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Дата рождения',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Контакты близких', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Зарегистрироваться'),
                  ),
          ],
        ),
      ),
    );
  }
}
