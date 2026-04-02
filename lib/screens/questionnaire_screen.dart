import 'package:flutter/material.dart';

class QuestionnaireScreen extends StatefulWidget {
  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final List<Map<String, dynamic>> _questions = [
    {'q': 'Беспокоят ли вас навязчивые воспоминания о событии?', 'score': 0},
    {'q': 'Испытываете ли вы трудности с засыпанием?', 'score': 0},
    {'q': 'Чувствуете ли вы отдаленность от других людей?', 'score': 0},
    {'q': 'Снизился ли интерес к важным для вас занятиям?', 'score': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Опросник PTSD-чеклист')),
      body: ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_questions[index]['q'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Slider(
                  value: _questions[index]['score'].toDouble(),
                  min: 0, max: 5, divisions: 5,
                  label: _questions[index]['score'].toString(),
                  onChanged: (val) {
                    setState(() => _questions[index]['score'] = val.toInt());
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            int total = _questions.fold(0, (sum, item) => sum + (item['score'] as int));
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('Результат'),
                content: Text('Общий балл: $total. ${total > 10 ? "Рекомендуется консультация психолога." : "Показатели в норме."}'),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('OK'))],
              ),
            );
          },
          child: Text('Завершить опрос'),
        ),
      ),
    );
  }
}
