import 'package:flutter/material.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/models/medical_models.dart';

class QuestionnaireScreen extends StatefulWidget {
  final int patientId;
  const QuestionnaireScreen({super.key, required this.patientId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final DatabaseService _dbService = DatabaseService();
  final List<Map<String, dynamic>> _questions = [
    {'q': 'Беспокоят ли вас навязчивые воспоминания о событии?', 'score': 0},
    {'q': 'Испытываете ли вы трудности с засыпанием?', 'score': 0},
    {'q': 'Чувствуете ли вы отдаленность от других людей?', 'score': 0},
    {'q': 'Снизился ли интерес к важным для вас занятиям?', 'score': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Опросник PTSD')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _questions[index]['q'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.sentiment_satisfied_rounded, size: 20, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: _questions[index]['score'].toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _questions[index]['score'].toString(),
                          onChanged: (val) {
                            setState(() => _questions[index]['score'] = val.toInt());
                          },
                        ),
                      ),
                      const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 20, color: Colors.redAccent),
                    ],
                  ),
                  Center(
                    child: Text(
                      'Балл: ${_questions[index]['score']}',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            int total = _questions.fold(0, (sum, item) => sum + (item['score'] as int));
            
            await _dbService.insertQuestionnaireResult(QuestionnaireResult(
              patientId: widget.patientId,
              title: 'PTSD-чеклист',
              totalScore: total,
              date: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
            ));

            if (!context.mounted) return;

            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Результат сохранен'),
                content: Text('Общий балл: $total. ${total > 10 ? "Рекомендуется консультация специалиста." : "Показатели в норме."}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pop(context);
                    }, 
                    child: const Text('Понятно')
                  )
                ],
              ),
            );
          },
          child: const Text('Завершить опрос', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
