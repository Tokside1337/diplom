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
    {'q': 'Трудности с концентрацией внимания?', 'score': 0},
    {'q': 'Повышенная раздражительность или вспышки гнева?', 'score': 0},
    {'q': 'Чрезмерная настороженность или пугливость?', 'score': 0},
  ];

  final List<String> _options = [
    'Совсем нет',
    'Немного',
    'Умеренно',
    'Сильно',
    'Очень сильно'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Опросник состояния'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildHeader(colorScheme),
              const SizedBox(height: 24),
              ...List.generate(_questions.length, (index) => _buildQuestionCard(index, colorScheme)),
              const SizedBox(height: 32),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveResults,
                    child: const Text('Завершить опрос', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Оцените, насколько указанные проблемы беспокоили вас за последнюю неделю.',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildQuestionCard(int index, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вопрос ${index + 1}',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _questions[index]['q'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(5, (optionIdx) {
              final isSelected = _questions[index]['score'] == optionIdx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _questions[index]['score'] = optionIdx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? colorScheme.primary : colorScheme.outline,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_options[optionIdx], style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResults() async {
    try {
      int total = _questions.fold(0, (sum, item) => sum + (item['score'] as int));
      await _dbService.insertQuestionnaireResult(QuestionnaireResult(
        patientId: widget.patientId,
        title: 'Опросник состояния',
        totalScore: total,
        date: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
      ));

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Результат сохранен'),
          content: Text('Общий балл: $total'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                Navigator.pop(context);
              },
              child: const Text('ОК'),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
