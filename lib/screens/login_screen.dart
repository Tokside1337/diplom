import 'package:flutter/material.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/patient_main_screen.dart';
import 'package:diplom/screens/admin_panel_screen.dart';
import 'package:diplom/screens/doctor_main_screen.dart';
import 'package:diplom/models/doctor.dart';
import 'package:provider/provider.dart';
import 'package:diplom/providers/settings_provider.dart';

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
  bool _obscurePassword = true;

  void _login() async {
    if (_loginController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите логин и пароль')),
      );
      return;
    }

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: Данные пользователя не найдены')),
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = settingsProvider.isDarkMode;

    // Стиль границ для четкого отображения
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.5),
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 2.0,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: colorScheme.primary,
            ),
            tooltip: 'Переключить тему',
            onPressed: () => settingsProvider.toggleTheme(!isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  ]
                : [
                    colorScheme.primaryContainer.withValues(alpha: 0.2),
                    colorScheme.surface,
                  ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 0,
                color: colorScheme.surface.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          size: 40,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Система Реабилитации',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _loginController,
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          border: inputBorder,
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: inputBorder,
                          focusedBorder: focusedBorder,
                          border: inputBorder,
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : FilledButton(
                              onPressed: _login,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Войти',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
