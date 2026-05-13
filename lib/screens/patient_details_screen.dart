import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/services/ai_service.dart';
import 'package:diplom/screens/questionnaire_screen.dart';
import 'package:diplom/screens/communication_screen.dart';
import 'package:diplom/screens/login_screen.dart';

// Модель для рекомендаций
class Recommendation {
  final String text;
  final String priority; // 'high', 'medium', 'low'
  final IconData icon;

  Recommendation({
    required this.text,
    required this.priority,
    required this.icon,
  });
}

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  final bool isPatientView;
  final bool hideNavigation;
  final Doctor? doctor;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
    this.isPatientView = false,
    this.hideNavigation = false,
    this.doctor,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Measurement> _measurements = [];
  List<MoodEntry> _moods = [];
  List<Appointment> _appointments = [];
  List<QuestionnaireResult> _qResults = [];
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
      final qres = await _dbService.getQuestionnaireResults(widget.patient.id!);
      if (mounted) {
        setState(() {
          _measurements = m;
          _moods = mood;
          _appointments = appts;
          _qResults = qres;
          _trend = AIService.analyzeTrend(m);
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  Future<void> _addAppointment() async {
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

  Future<void> _addMeasurement() async {
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

  Future<void> _addMood() async {
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

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPatientProfile() {
    return Scaffold(
      appBar: widget.hideNavigation ? null : AppBar(
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
              _buildSectionTitle('Мои показатели давления (Верхнее и нижнее)'),
              _buildChart(),
              const SizedBox(height: 10),
              _buildMeasurementsDetails(),
              const SizedBox(height: 24),
              _buildSectionTitle('Мой календарь мероприятий'),
              _buildAppointmentsList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Рекомендации врача'),
              _buildAICard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Результаты опросников'),
              _buildQuestionnaireResults(),
              const SizedBox(height: 24),
              _buildSectionTitle('История настроения'),
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
                doctor: widget.doctor,
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
              _buildSectionTitle('Аналитика ИИ и Прогноз'),
              _buildAICard(),
              const SizedBox(height: 20),
              _buildSectionTitle('График давления'),
              _buildChart(),
              const SizedBox(height: 10),
              _buildMeasurementsDetails(),
              const SizedBox(height: 20),
              _buildSectionTitle('План мероприятий'),
              _buildAppointmentsList(),
              const SizedBox(height: 20),
              _buildSectionTitle('Результаты опросников'),
              _buildQuestionnaireResults(),
              const SizedBox(height: 20),
              _buildSectionTitle('Психологический профиль'),
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
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(
          widget.patient.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          'Дата рождения: ${widget.patient.birthDate}',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
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
              MaterialPageRoute(builder: (context) => QuestionnaireScreen(patientId: widget.patient.id!))
          ).then((_) => _loadData()),
          icon: const Icon(Icons.assignment),
          label: const Text('Назначить опросник'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50),
        ),
      ],
    );
  }

  String? _checkCriticalPressure() {
    if (_measurements.isEmpty) return null;

    final lastMeasurement = _measurements.last;
    final systolic = lastMeasurement.pressureSystolic;
    final diastolic = lastMeasurement.pressureDiastolic;

    if (systolic >= 180 || diastolic >= 120) {
      return '🔴 КРИТИЧЕСКИ ОПАСНО: Очень высокое давление (${systolic.toInt()}/${diastolic.toInt()} мм рт.ст.)! НЕМЕДЛЕННО вызовите скорую помощь (103)!';
    }
    if (systolic >= 160 || diastolic >= 100) {
      return '⚠️ ОПАСНО: Давление критически высокое (${systolic.toInt()}/${diastolic.toInt()} мм рт.ст.). Требуется срочная консультация врача.';
    }
    if (systolic > 140 || diastolic > 90) {
      return '📈 Повышенное давление (${systolic.toInt()}/${diastolic.toInt()} мм рт.ст.). Рекомендуется отдых и ограничение соли.';
    }
    if (systolic < 70 || diastolic < 40) {
      return '🔴 КРИТИЧЕСКИ ОПАСНО: Экстремально низкое давление (${systolic.toInt()}/${diastolic.toInt()} мм рт.ст.)! Вызовите скорую помощь!';
    }
    if (systolic < 90 || diastolic < 60) {
      return '⚠️ ОПАСНО: Низкое давление (${systolic.toInt()}/${diastolic.toInt()} мм рт.ст.). Возможны головокружение и слабость.';
    }
    return null;
  }

  List<Recommendation> _generateDynamicRecommendations() {
    final recommendations = <Recommendation>[];

    final criticalPressureMessage = _checkCriticalPressure();
    if (criticalPressureMessage != null) {
      final isCritical = criticalPressureMessage.contains('КРИТИЧЕСКИ');
      recommendations.add(Recommendation(
        text: criticalPressureMessage,
        priority: isCritical ? 'high' : 'medium',
        icon: isCritical ? Icons.warning_amber_rounded : Icons.warning,
      ));
    }

    if (_measurements.isNotEmpty && criticalPressureMessage == null) {
      final lastMeasurements = _measurements.reversed.take(3).toList();
      final avgSystolic = lastMeasurements.map((m) => m.pressureSystolic).reduce((a, b) => a + b) / lastMeasurements.length;
      final avgDiastolic = lastMeasurements.map((m) => m.pressureDiastolic).reduce((a, b) => a + b) / lastMeasurements.length;

      if (avgSystolic > 135 || avgDiastolic > 85) {
        recommendations.add(Recommendation(
          text: '⚠️ Внимание: Повышенное давление в среднем (${avgSystolic.toInt()}/${avgDiastolic.toInt()}).',
          priority: 'medium',
          icon: Icons.warning,
        ));
      }

      if (_measurements.length >= 5) {
        final recent5 = _measurements.reversed.take(5).toList();
        final systolicTrend = recent5[0].pressureSystolic - recent5[4].pressureSystolic;
        if (systolicTrend > 15) {
          recommendations.add(Recommendation(
            text: '📈 Тревожный тренд: давление повышается.',
            priority: 'high',
            icon: Icons.trending_up,
          ));
        } else if (systolicTrend < -10) {
          recommendations.add(Recommendation(
            text: '📉 Положительная динамика: давление снижается.',
            priority: 'low',
            icon: Icons.trending_down,
          ));
        }
      }
    }

    if (_measurements.isNotEmpty) {
      final lastPulse = _measurements.last.pulse;
      if (lastPulse > 100) {
        recommendations.add(Recommendation(
          text: '❤️ Учащенный пульс ($lastPulse уд/мин). Практикуйте дыхательные упражнения.',
          priority: 'medium',
          icon: Icons.favorite,
        ));
      }
    }

    if (_moods.isNotEmpty) {
      final lastMoods = _moods.reversed.take(5).toList();
      final avgMood = lastMoods.map((m) => m.score).reduce((a, b) => a + b) / lastMoods.length;

      if (avgMood < 2.5) {
        recommendations.add(Recommendation(
          text: '😟 Низкий эмоциональный фон. Рекомендуется психологическая поддержка.',
          priority: 'high',
          icon: Icons.mood_bad,
        ));
      } else if (avgMood > 4) {
        recommendations.add(Recommendation(
          text: '😊 Отличное настроение! Это положительно влияет на восстановление.',
          priority: 'low',
          icon: Icons.celebration,
        ));
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(Recommendation(
        text: '✅ Продолжайте регулярно измерять давление и вести дневник.',
        priority: 'low',
        icon: Icons.check_circle,
      ));
    }

    return recommendations.take(4).toList();
  }

  Color _getRecommendationColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildAICard() {
    final recommendations = _generateDynamicRecommendations();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? Colors.indigo.shade900.withValues(alpha: 0.3)
        : Colors.indigo.shade50;

    final textColor = isDark ? Colors.indigo.shade100 : Colors.indigo.shade900;
    final iconColor = isDark ? Colors.indigo.shade200 : Colors.indigo;

    return Card(
      elevation: 4,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  'Анализ и рекомендации:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(_trend, style: TextStyle(color: textColor)),
            ),
            const Divider(),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rec.icon, size: 16, color: _getRecommendationColor(rec.priority)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rec.text, style: TextStyle(fontSize: 13, color: textColor)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_measurements.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('Нет данных')));

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
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureDiastolic)).toList(),
                    isCurved: true,
                    color: Colors.blue,
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
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: _measurements.reversed.take(3).map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.timestamp.substring(11, 16), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  Text('${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    if (_appointments.isEmpty) return Card(child: ListTile(title: Text('Нет мероприятий', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))));

    return Column(
      children: _appointments.map((app) {
        final date = DateTime.parse(app.time);
        return Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAppTypeColor(app.type),
              child: Icon(_getAppTypeIcon(app.type), color: Colors.white, size: 20),
            ),
            title: Text(app.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${app.type} • Каб. ${app.room}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${date.day}.${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                if (!widget.isPatientView)
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDeleteAppointment(app.id!)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDeleteAppointment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Удалить это мероприятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _dbService.deleteAppointment(id);
      _loadData();
    }
  }

  Color _getAppTypeColor(String type) {
    if (type.contains('ЛФК')) return Colors.green;
    if (type.contains('Прием')) return Colors.blue;
    return Colors.orange;
  }

  IconData _getAppTypeIcon(String type) {
    if (type.contains('ЛФК')) return Icons.directions_run;
    if (type.contains('Прием')) return Icons.medical_services;
    return Icons.event;
  }

  Widget _buildMoodList() {
    if (_moods.isEmpty) return const Center(child: Text('Дневник пуст'));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _moods.length > 5 ? 5 : _moods.length,
      itemBuilder: (context, index) {
        final m = _moods.reversed.toList()[index];
        return Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: Icon(
              m.sentiment == 'Positive' ? Icons.sentiment_very_satisfied : Icons.sentiment_neutral,
              color: m.sentiment == 'Positive' ? Colors.green : Colors.orange,
            ),
            title: Text(m.comment),
            subtitle: Text('Оценка: ${m.score} | ${m.timestamp.substring(11, 16)}'),
          ),
        );
      },
    );
  }

  Widget _buildQuestionnaireResults() {
    if (_qResults.isEmpty) return const Card(child: ListTile(title: Text('Нет данных')));
    return Column(
      children: _qResults.map((res) => Card(
        color: Theme.of(context).cardColor,
        child: ListTile(
          leading: const Icon(Icons.assignment_turned_in, color: Colors.blue),
          title: Text(res.title),
          subtitle: Text('Балл: ${res.totalScore} | ${res.date.substring(0, 10)}'),
        ),
      )).toList(),
    );
  }
}
