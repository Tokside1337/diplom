import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import 'patient_details_screen.dart';

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

  _loadPatients() async {
    try {
      final patients = await _dbService.getPatients();
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: \$e')),
      );
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
              TextField(controller: dateController, decoration: InputDecoration(labelText: 'Дата рождения (ГГГГ-ММ-ДД)')),
              TextField(controller: contactController, decoration: InputDecoration(labelText: 'Контакты родственников')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _dbService.insertPatient(Patient(
                  name: nameController.text,
                  birthDate: dateController.text,
                  relativeContact: contactController.text,
                ));
                Navigator.pop(context);
                _loadPatients();
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Цифровые профили пациентов')),
      body: _patients.isEmpty 
        ? Center(child: Text('Список пуст. Добавьте первого пациента.'))
        : ListView.builder(
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final p = _patients[index];
              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(p.name),
                subtitle: Text('ДР: \${p.birthDate}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientDetailsScreen(patient: p)),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPatientDialog,
        child: Icon(Icons.add),
        tooltip: 'Добавить пациента',
      ),
    );
  }
}
