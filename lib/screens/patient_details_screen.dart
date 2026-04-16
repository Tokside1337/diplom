import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import '../models/medical_models.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'questionnaire_screen.dart';
import 'communication_screen.dart';
import 'login_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  final bool isPatientView;
  const PatientDetailsScreen({super.key, required this.patient, this.isPatientView = false});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Measurement> _measurements = [];
  List<MoodEntry> _moods = [];
  List<Appointment> _appointments = [];
  String _trend = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final m = await _dbService.getMeasurements(widget.patient.id!);
      final mood = await _dbService.getMoodEntries(widget.patient.id!);
      final appts = await _dbService.getAppointments(widget.patient.id!);
      if (mounted) {
        setState(() {
          _measurements = m;
          _moods = mood;
          _appointments = appts;
          _trend = AIService.analyzeTrend(m);
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  _addAppointment() async {
    final titleController = TextEditingController();
    final typeController = TextEditingController(text: 'Процедура');
    final roomController = TextEditingController();
    final doctorController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новое мероприятие'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Название')),
                TextField(controller: typeController, decoration: const InputDecoration(labelText: 'Тип (ЛФК, Прием и т.д.)')),
                TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Кабинет')),
                TextField(controller: doctorController, decoration: const InputDecoration(labelText: 'Врач')),
                const SizedBox(height: 10),
                ListTile(
                  title: Text("Дата: ${selectedDate.toString().split(' ')[0]}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: Text("Время: ${selectedTime.format(context)}"),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setDialogState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                final fullDateTime = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                await _dbService.insertAppointment(Appointment(
                  patientId: widget.patient.id!,
                  type: typeController.text,
                  title: titleController.text,
                  time: fullDateTime.toString(),
                  room: roomController.text,
                  doctor: doctorController.text,
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  _addMeasurement() async {
    final systolicController = TextEditingController(text: '120');
    final diastolicController = TextEditingController(text: '80');
    final pulseController = TextEditingController(text: '70');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Замер показателей'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: systolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Систолическое (верхнее)', suffixText: 'мм рт.ст.'),
            ),
            TextField(
              controller: diastolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Диастолическое (нижнее)', suffixText: 'мм рт.ст.'),
            ),
            TextField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Пульс', suffixText: 'уд/мин'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              await _dbService.insertMeasurement(Measurement(
                patientId: widget.patient.id!,
                pressureSystolic: double.tryParse(systolicController.text) ?? 120.0,
                pressureDiastolic: double.tryParse(diastolicController.text) ?? 80.0,
                pulse: int.tryParse(pulseController.text) ?? 70,
                painLevel: 0,
                timestamp: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  _addMood() async {
    final commentController = TextEditingController();
    double currentScore = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Дневник настроения'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Как вы себя чувствуете? (1-5)'),
              Slider(
                value: currentScore,
                min: 1,
                max: 5,
                divisions: 4,
                label: currentScore.toInt().toString(),
                onChanged: (val) => setDialogState(() => currentScore = val),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Опишите ваши мысли и состояние...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                String comment = commentController.text;
                if (comment.isEmpty) comment = "Без комментария";
                
                await _dbService.insertMoodEntry(MoodEntry(
                  patientId: widget.patient.id!,
                  score: currentScore.toInt(),
                  comment: comment,
                  timestamp: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
                  sentiment: AIService.analyzeSentiment(comment),
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPatientView) {
      return _buildPatientProfile();
    }
    return _buildDoctorView();
  }

  Widget _buildPatientProfile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(),
              const SizedBox(height: 24),
              Text('Мои показатели давления (Верхнее и нижнее)', style: Theme.of(context).textTheme.titleLarge),
              _buildChart(),
              const SizedBox(height: 10),
              _buildMeasurementsDetails(),
              const SizedBox(height: 24),
              Text('Мой календарь мероприятий', style: Theme.of(context).textTheme.titleLarge),
              _buildAppointmentsList(),
              const SizedBox(height: 24),
              Text('Рекомендации врача', style: Theme.of(context).textTheme.titleLarge),
              _buildAICard(),
              const SizedBox(height: 24),
              Text('История настроения', style: Theme.of(context).textTheme.titleLarge),
              _buildMoodList(),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'mood',
            onPressed: _addMood,
            label: const Text('Дневник'),
            icon: const Icon(Icons.mood),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'measure',
            onPressed: _addMeasurement,
            label: const Text('Замер давления'),
            icon: const Icon(Icons.add_chart),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пациент: ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunicationScreen(
                patientId: widget.patient.id!,
                isPatientView: false,
              )),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorControls(),
              const SizedBox(height: 20),
              Text('Аналитика ИИ и Прогноз', style: Theme.of(context).textTheme.titleLarge),
              _buildAICard(),
              const SizedBox(height: 20),
              Text('График давления', style: Theme.of(context).textTheme.titleLarge),
              _buildChart(),
              const SizedBox(height: 10),
              _buildMeasurementsDetails(),
              const SizedBox(height: 20),
              Text('План мероприятий', style: Theme.of(context).textTheme.titleLarge),
              _buildAppointmentsList(),
              const SizedBox(height: 20),
              Text('Психологический профиль', style: Theme.of(context).textTheme.titleLarge),
              _buildMoodList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeasurement,
        label: const Text('Добавить замер'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(widget.patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Дата рождения: ${widget.patient.birthDate}'),
      ),
    );
  }

  Widget _buildDoctorControls() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: _addAppointment,
          icon: const Icon(Icons.event),
          label: const Text('Назначить мероприятие'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => QuestionnaireScreen())
          ).then((_) => _loadData()),
          icon: const Icon(Icons.assignment),
          label: const Text('Назначить опросник'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
        ),
        ElevatedButton.icon(
          onPressed: _addMood,
          icon: const Icon(Icons.edit_note),
          label: const Text('Сделать пометку'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50),
        ),
      ],
    );
  }

  Widget _buildAICard() {
    return Card(
      elevation: 4,
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.indigo),
                SizedBox(width: 10),
                Text('Прогноз динамики:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(_trend, style: TextStyle(color: Colors.indigo.shade900)),
            ),
            const Divider(),
            const Text('Интеллектуальные рекомендации:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('• Рекомендуется увеличить время ЛФК на 15 мин.', style: TextStyle(fontSize: 13)),
            const Text('• Положительная реакция на дыхательные практики.', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_measurements.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('Нет данных для визуализации')));
    
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 20, right: 20, bottom: 10),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureSystolic)).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureDiastolic)).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Сист.', Colors.red),
              const SizedBox(width: 20),
              _buildLegendItem('Диаст.', Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMeasurementsDetails() {
    if (_measurements.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: _measurements.reversed.take(3).map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.timestamp.substring(11, 16), style: const TextStyle(color: Colors.grey)),
                  Text('${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text('${m.pulse}'),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) return const Card(child: ListTile(title: Text('Мероприятий не запланировано')));
    
    return Column(
      children: _appointments.map((app) {
        final date = DateTime.parse(app.time);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAppTypeColor(app.type),
              child: Icon(_getAppTypeIcon(app.type), color: Colors.white, size: 20),
            ),
            title: Text(app.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${app.type} • Каб. ${app.room} • ${app.doctor}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}.${date.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getAppTypeColor(String type) {
    if (type.contains('ЛФК')) return Colors.green;
    if (type.contains('Прием')) return Colors.blue;
    if (type.contains('Процедура')) return Colors.orange;
    return Colors.purple;
  }

  IconData _getAppTypeIcon(String type) {
    if (type.contains('ЛФК')) return Icons.directions_run;
    if (type.contains('Прием')) return Icons.medical_services;
    if (type.contains('Процедура')) return Icons.vaccines;
    return Icons.event;
  }

  Widget _buildMoodList() {
    if (_moods.isEmpty) return const Center(child: Text('Дневник настроения пуст'));
    final displayMoods = _moods.reversed.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayMoods.length > 5 ? 5 : displayMoods.length,
      itemBuilder: (context, index) {
        final m = displayMoods[index];
        return Card(
          child: ListTile(
            leading: Icon(
              m.sentiment == 'Negative' ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: m.sentiment == 'Negative' ? Colors.orange : Colors.green,
            ),
            title: Text(m.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('Оценка: ${m.score} | Анализ: ${m.sentiment ?? '...'} | ${m.timestamp.substring(11, 16)}'),
          ),
        );
      },
    );
  }
}
