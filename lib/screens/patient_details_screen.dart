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
  String _trend = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final m = await _dbService.getMeasurements(widget.patient.id!);
    final mood = await _dbService.getMoodEntries(widget.patient.id!);
    setState(() {
      _measurements = m;
      _moods = mood;
      _trend = AIService.analyzeTrend(m);
    });
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
                timestamp: DateTime.now().toString(),
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
                  timestamp: DateTime.now().toString(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(),
            const SizedBox(height: 24),
            Text('Мои показатели (Давление)', style: Theme.of(context).textTheme.titleLarge),
            _buildChart(),
            const SizedBox(height: 24),
            Text('Рекомендации врача', style: Theme.of(context).textTheme.titleLarge),
            _buildAICard(),
            const SizedBox(height: 24),
            Text('История настроения', style: Theme.of(context).textTheme.titleLarge),
            _buildMoodList(),
          ],
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
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorControls(),
            const SizedBox(height: 20),
            Text('Аналитика ИИ и Прогноз', style: Theme.of(context).textTheme.titleLarge),
            _buildAICard(),
            const SizedBox(height: 20),
            Text('График состояния', style: Theme.of(context).textTheme.titleLarge),
            _buildChart(),
            const SizedBox(height: 20),
            Text('Психологический профиль', style: Theme.of(context).textTheme.titleLarge),
            _buildMoodList(),
          ],
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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionnaireScreen())),
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
      height: 200,
      padding: const EdgeInsets.only(top: 20, right: 20),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureSystolic)).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodList() {
    if (_moods.isEmpty) return const Center(child: Text('Дневник настроения пуст'));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _moods.length > 5 ? 5 : _moods.length,
      itemBuilder: (context, index) {
        final m = _moods[index];
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
