import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/patient_details_screen.dart';
import 'package:diplom/screens/login_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool hideAppBar;
  const PatientListScreen({super.key, this.hideAppBar = false});

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

  // Метод _showAddPatientDialog удален, так как добавление пациентов 
  // теперь осуществляется через панель администратора.

  Future<void> _deletePatient(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Вы уверены, что хотите удалить профиль пациента? Все связанные данные (анализы, дневник) будут удалены.'),
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
    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Цифровые профили пациентов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _patients.isEmpty 
        ? const Center(child: Text('Список пациентов пуст.'))
        : ListView.builder(
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final p = _patients[index];
              return Dismissible(
                key: Key(p.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  await _deletePatient(p.id!);
                  return false;
                },
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p.name),
                  subtitle: Text('Дата Рождения: ${_formatDate(p.birthDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PatientDetailsScreen(patient: p, isPatientView: false)),
                  ),
                ),
              );
            },
          ),
    );
  }
}
