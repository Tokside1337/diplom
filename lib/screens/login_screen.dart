import 'package:flutter/material.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/patient_main_screen.dart'; // Изменено на MainScreen
import 'package:diplom/screens/admin_panel_screen.dart';
import 'package:diplom/screens/doctor_main_screen.dart';
import 'package:diplom/models/doctor.dart';

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
          Doctor? doctor;
          if (user.doctorId != null) {
            doctor = await _dbService.getDoctorById(user.doctorId!);
          }
          
          if (!mounted) return;
          if (doctor != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DoctorMainScreen(doctor: doctor!)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка: Профиль врача не найден')),
            );
          }
        } else if (user.role == UserRole.admin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
            ],
          ),
        ),
      ),
    );
  }
}

// RegisterScreen удален, так как регистрация перенесена в админ-панель
