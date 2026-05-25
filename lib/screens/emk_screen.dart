import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/emk_model.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/services/pdf_service.dart';

class EMKScreen extends StatefulWidget {
  final Patient patient;
  final bool isDoctor;

  const EMKScreen({super.key, required this.patient, required this.isDoctor});

  @override
  State<EMKScreen> createState() => _EMKScreenState();
}

class _EMKScreenState extends State<EMKScreen> {
  final _dbService = DatabaseService();
  EMK? _emk;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEMK();
  }

  Future<void> _loadEMK() async {
    setState(() => _isLoading = true);
    final emk = await _dbService.getEMK(widget.patient.id!);
    if (mounted) {
      setState(() {
        _emk = emk ??
            EMK(
              patientId: widget.patient.id!,
              createdAt: DateTime.now().toIso8601String(),
            );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('ЭМК: ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => PdfService.printEMK(_emk!, widget.patient),
            tooltip: 'Печать ЭМК',
          ),
          if (widget.isDoctor)
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: () async {
                await _dbService.saveEMK(_emk!);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ЭМК сохранена')));
              },
            )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('0. САНАТОРНО-КУРОРТНАЯ КАРТА (СКК)', {
                'Номер СКК': widget.patient.skkNumber,
                'Дата выдачи': widget.patient.skkDate,
                'Кем выдана': widget.patient.issuedByLpu,
                'Основной диагноз (МКБ)': widget.patient.mainDiagnosisMkb,
                'Группа здоровья': widget.patient.healthGroup,
                'Стол питания': widget.patient.dietTable,
                'Режим': widget.patient.mobilityRegime,
              }, [
                'Номер СКК',
                'Дата выдачи',
                'Кем выдана',
                'Основной диагноз (МКБ)',
                'Группа здоровья',
                'Стол питания',
                'Режим'
              ]),
              _buildSection('1. ДИАГНОЗЫ', _emk!.diagnoses, [
                'Основной диагноз',
                'Сопутствующие',
                'Осложнения',
                'Направление',
                'Функциональный (МКФ)'
              ]),
              _buildSection('2. ПРОТИВОПОКАЗАНИЯ', _emk!.contraindications, [
                'Абсолютные',
                'Относительные',
                'Аллергены',
                'Запрещенные процедуры IDs',
                'Макс. нагрузка (кг)'
              ]),
              _buildSection('3. ЦЕЛИ ЛЕЧЕНИЯ', _emk!.treatmentGoals, [
                'Потенциал (high/medium/low)',
                'SMART-цели',
                'Шкалы на входе (MRC, Berg, Barthel)',
                'Приоритеты'
              ]),
              _buildListSection('4.1 ЕЖЕДНЕВНЫЕ ЗАПИСИ', _emk!.dailyLogs),
              _buildListSection('4.2 ЭТАПНЫЕ ОСМОТРЫ', _emk!.stageReviews),
              _buildSection('5. ИТОГОВЫЕ РЕКОМЕНДАЦИИ', _emk!.finalRecommendations, [
                'Эпикриз',
                'Итоговый статус',
                'Домашний режим',
                'Лекарства'
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data, List<String> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          ),
          ...fields.map((f) => ListTile(
                title: Text(f, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(data[f]?.toString() ?? 'Не заполнено'),
                trailing: widget.isDoctor ? const Icon(Icons.edit_rounded, size: 18) : null,
                onTap: widget.isDoctor ? () => _editField(data, f) : null,
              )),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                if (widget.isDoctor)
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addEntry(list))
              ],
            ),
          ),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Записей нет', style: TextStyle(fontStyle: FontStyle.italic))),
          ...list.map((item) => ListTile(
                title: Text(item.toString()),
                dense: true,
              )),
        ],
      ),
    );
  }

  void _editField(Map<String, dynamic> section, String field) {
    final controller = TextEditingController(text: section[field]?.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать: $field'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
              onPressed: () {
                setState(() {
                  section[field] = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('ОК')),
        ],
      ),
    );
  }

  void _addEntry(List<dynamic> list) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая запись'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Введите данные осмотра...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
              onPressed: () {
                setState(() {
                  list.add('${DateFormat('dd.MM HH:mm').format(DateTime.now())}: ${controller.text}');
                });
                Navigator.pop(context);
              },
              child: const Text('Добавить')),
        ],
      ),
    );
  }
}
