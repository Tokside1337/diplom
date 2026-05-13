import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/screens/patient_details_screen.dart';
import 'package:diplom/screens/login_screen.dart';

enum PatientSort { nameAsc, nameDesc, ageAsc, ageDesc }

class PatientListScreen extends StatefulWidget {
  final bool hideAppBar;
  final Doctor? doctor;
  const PatientListScreen({super.key, this.hideAppBar = false, this.doctor});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  String _searchQuery = '';
  PatientSort _currentSort = PatientSort.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _applySort();
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

  void _applySort() {
    switch (_currentSort) {
      case PatientSort.nameAsc:
        _patients.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PatientSort.nameDesc:
        _patients.sort((a, b) => b.name.compareTo(a.name));
        break;
      case PatientSort.ageAsc:
        _patients.sort((a, b) => a.birthDate.compareTo(b.birthDate));
        break;
      case PatientSort.ageDesc:
        _patients.sort((a, b) => b.birthDate.compareTo(a.birthDate));
        break;
    }
  }

  void _setSort(PatientSort sort) {
    setState(() {
      _currentSort = sort;
      _applySort();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildSortButton() {
    return PopupMenuButton<PatientSort>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Сортировка',
      onSelected: _setSort,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: PatientSort.nameAsc,
          child: Row(children: [Icon(Icons.sort_by_alpha_rounded), SizedBox(width: 8), Text('Имя (А-Я)')]),
        ),
        const PopupMenuItem(
          value: PatientSort.nameDesc,
          child: Row(children: [Icon(Icons.sort_by_alpha_rounded), SizedBox(width: 8), Text('Имя (Я-А)')]),
        ),
        const PopupMenuItem(
          value: PatientSort.ageAsc,
          child: Row(children: [Icon(Icons.calendar_today_rounded), SizedBox(width: 8), Text('Сначала старшие')]),
        ),
        const PopupMenuItem(
          value: PatientSort.ageDesc,
          child: Row(children: [Icon(Icons.calendar_today_rounded), SizedBox(width: 8), Text('Сначала младшие')]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final filteredPatients = _patients.where((p) {
      // Изменено: теперь поиск проверяет начало строки (по первой букве/слову)
      return p.name.trim().toLowerCase().startsWith(_searchQuery.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Профили пациентов'),
        actions: [
          _buildSortButton(),
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
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск пациента...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isEmpty ? 'Всего: ${_patients.length}' : 'Найдено: ${filteredPatients.length}',
                      style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (widget.hideAppBar) _buildSortButton(),
                  ],
                ),
              ),
              Expanded(
                child: filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Пациент на "$_searchQuery" не найден', style: TextStyle(color: colorScheme.outline)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final p = filteredPatients[index];
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
              ),
            ],
          ),
    );
  }
}
