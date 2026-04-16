import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CommunicationScreen extends StatefulWidget {
  final int patientId;
  final bool isPatientView;
  
  CommunicationScreen({required this.patientId, this.isPatientView = false});

  @override
  _CommunicationScreenState createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _noteController = TextEditingController();
  String _selectedAuthor = 'Врач';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Консилиум и Заметки')),
      body: Column(
        children: [
          if (!widget.isPatientView) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedAuthor,
                    items: ['Врач', 'Психолог', 'Инструктор ЛФК'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAuthor = val!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(hintText: 'Введите заметку...'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      if (_noteController.text.isNotEmpty) {
                        await _dbService.insertNote(widget.patientId, _selectedAuthor, _noteController.text);
                        _noteController.clear();
                        setState(() {});
                      }
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _dbService.getNotes(widget.patientId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  if (snapshot.data!.isEmpty) return Center(child: Text('Заметок пока нет'));
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final note = snapshot.data![index];
                      return ListTile(
                        title: Text(note['author'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(note['content']),
                        trailing: Text(note['timestamp'].toString().substring(11, 16)),
                      );
                    },
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Раздел "Заметки консилиума"\nдоступен только медицинскому персоналу',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('Общий календарь мероприятий'),
            subtitle: Text('Групповая терапия: Завтра в 10:00'),
            onTap: () {
              // В прототипе просто показываем заглушку
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Переход к календарю...')));
            },
          )
        ],
      ),
    );
  }
}
