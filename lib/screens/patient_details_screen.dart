import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import '../models/medical_models.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'questionnaire_screen.dart';
import 'communication_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  PatientDetailsScreen({required this.patient});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
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
    await _dbService.insertMeasurement(Measurement(
      patientId: widget.patient.id!,
      pressureSystolic: 110 + (DateTime.now().second % 30).toDouble(),
      pressureDiastolic: 70 + (DateTime.now().second % 20).toDouble(),
      pulse: 60 + (DateTime.now().second % 40),
      painLevel: 2,
      timestamp: DateTime.now().toString(),
    ));
    _loadData();
  }

  _addMood() async {
    final commentController = TextEditingController();
    double currentScore = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Дневник настроения'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Как вы себя чувствуете? (1-5)'),
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
                decoration: InputDecoration(
                  hintText: 'Опишите ваши мысли и состояние...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
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
                Navigator.pop(context);
                _loadData();
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunicationScreen(patientId: widget.patient.id!)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionButtons(),
            SizedBox(height: 20),
            Text('Аналитика ИИ и Рекомендации', style: Theme.of(context).textTheme.titleLarge),
            _buildAICard(),
            SizedBox(height: 20),
            Text('Физические показатели (Давление)', style: Theme.of(context).textTheme.titleLarge),
            _buildChart(),
            SizedBox(height: 20),
            Text('Психологический профиль (Тональность)', style: Theme.of(context).textTheme.titleLarge),
            _buildMoodList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeasurement,
        label: Text('Замер показателей'),
        icon: Icon(Icons.add_chart),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionnaireScreen())),
          icon: Icon(Icons.assignment),
          label: Text('Опросник'),
        ),
        ElevatedButton.icon(
          onPressed: _addMood,
          icon: Icon(Icons.mood),
          label: Text('Дневник'),
        ),
      ],
    );
  }

  Widget _buildAICard() {
    return Card(
      elevation: 4,
      color: Colors.indigo.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            Divider(),
            Text('Интеллектуальные рекомендации:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('• Рекомендуется увеличить время ЛФК на 15 мин.', style: TextStyle(fontSize: 13)),
            Text('• Положительная реакция на дыхательные практики.', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_measurements.isEmpty) return Container(height: 100, child: Center(child: Text('Нет данных для визуализации')));
    
    return Container(
      height: 200,
      padding: EdgeInsets.only(top: 20, right: 20),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureSystolic)).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodList() {
    if (_moods.isEmpty) return Center(child: Text('Дневник настроения пуст'));
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
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
            subtitle: Text('Оценка: ' + m.score.toString() + ' | Анализ: ' + (m.sentiment ?? '...') + ' | ' + m.timestamp.substring(11, 16)),
          ),
        );
      },
    );
  }
}
