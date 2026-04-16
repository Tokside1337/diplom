import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import 'patient_details_screen.dart';
import 'login_screen.dart';

class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
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
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  _loadPatients() async {
    try {
      final patients = await _dbService.getPatients();
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: \$e')),
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

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить пациента'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'ФИО')),
              TextField(
                controller: dateController, 
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Дата рождения',
                  hintText: 'Выберите дату',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              TextField(controller: contactController, decoration: InputDecoration(labelText: 'Контакты родственников')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && dateController.text.isNotEmpty) {
                await _dbService.insertPatient(Patient(
                  name: nameController.text,
                  birthDate: dateController.text,
                  relativeContact: contactController.text,
                ));
                if (mounted) Navigator.pop(context);
                _loadPatients();
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deletePatient(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удаление'),
        content: Text('Вы уверены, что хотите удалить профиль пациента? Все связанные данные (анализы, дневник) будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: Text('Цифровые профили пациентов'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _patients.isEmpty 
        ? Center(child: Text('Список пациентов пуст.'))
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
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  _deletePatient(p.id!);
                  return false;
                },
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p.name),
                  subtitle: Text('Дата Рождения: ' + _formatDate(p.birthDate)),
                  trailing: Icon(Icons.chevron_right),
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
