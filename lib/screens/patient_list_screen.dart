import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/patient_details_screen.dart';
import 'package:diplom/screens/login_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool hideAppBar;
  final Doctor? doctor;
  const PatientListScreen({super.key, this.hideAppBar = false, this.doctor});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Patient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _dbService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _deletePatient(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Вы уверены, что хотите удалить профиль пациента? Все связанные данные будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deletePatient(id);
      _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Профили пациентов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _patients.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: colorScheme.outline),
                const SizedBox(height: 16),
                const Text('Список пациентов пуст.'),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final p = _patients[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Дата Рождения: ${_formatDate(p.birthDate)}'),
                    trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientDetailsScreen(
                        patient: p, 
                        isPatientView: false,
                        doctor: widget.doctor,
                      )),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
