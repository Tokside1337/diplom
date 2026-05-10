import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/medical_models.dart';
import 'patient_details_screen.dart';
import 'login_screen.dart';
import '../services/database_service.dart';

class PatientMainScreen extends StatefulWidget {
  final Patient patient;
  const PatientMainScreen({super.key, required this.patient});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PatientDetailsScreen(patient: widget.patient, isPatientView: true, hideNavigation: true),
      _DiaryTab(patient: widget.patient),
      _AIChatTab(patient: widget.patient),
      _ProfileTab(patient: widget.patient),
      _SettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Дневник'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'ИИ Чат'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}

class _DiaryTab extends StatelessWidget {
  final Patient patient;
  const _DiaryTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник здоровья')),
      body: FutureBuilder(
        future: Future.wait([
          db.getMeasurements(patient.id!),
          db.getMoodEntries(patient.id!),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final measurements = snapshot.data![0] as List<Measurement>;
          final moods = snapshot.data![1] as List<MoodEntry>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Последние замеры', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ...measurements.reversed.take(5).map((m) => Card(
                child: ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text('${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()} мм рт.ст.'),
                  subtitle: Text('Пульс: ${m.pulse} | ${m.timestamp.substring(11, 16)}'),
                ),
              )),
              const SizedBox(height: 24),
              Text('Записи настроения', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              ...moods.reversed.take(5).map((m) => Card(
                child: ListTile(
                  leading: Icon(Icons.mood, color: _getMoodColor(m.score)),
                  title: Text(m.comment),
                  subtitle: Text('Оценка: ${m.score} | ${m.timestamp.substring(11, 16)}'),
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Color _getMoodColor(int score) {
    if (score >= 4) return Colors.green;
    if (score == 3) return Colors.orange;
    return Colors.red;
  }
}

class _AIChatTab extends StatefulWidget {
  final Patient patient;
  const _AIChatTab({required this.patient});

  @override
  State<_AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<_AIChatTab> {
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'content': 'Здравствуйте! Я ваш ИИ-консультант. Как вы себя чувствуете сегодня?'}
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': _controller.text});
      _messages.add({'role': 'ai', 'content': 'Я проанализировал ваш запрос. Рекомендую придерживаться плана реабилитации и не забывать про отдых.'});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат с ИИ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isAi = m['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.grey[200] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    child: Text(m['content']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Спросите ИИ...'))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Patient patient;
  const _ProfileTab({required this.patient});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: FutureBuilder(
        future: Future.wait([
          db.getHospitalizations(patient.id!),
          // Здесь можно добавить получение диагнозов, если будет метод в БД
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final hospitalizations = snapshot.hasData ? snapshot.data![0] as List<Map<String, dynamic>> : [];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Center(
                child: Stack(
                  children: [
                    CircleAvatar(radius: 60, child: Icon(Icons.person, size: 60)),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.blue, radius: 18, child: Icon(Icons.edit, color: Colors.white, size: 18))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoTile('ФИО', patient.name, Icons.badge),
              _buildInfoTile('Дата рождения', patient.birthDate, Icons.cake),
              _buildInfoTile('Контакт близких', patient.relativeContact, Icons.family_restroom),
              const Divider(height: 40),
              Text('История госпитализаций', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (hospitalizations.isEmpty)
                const Card(child: ListTile(title: Text('Записей о госпитализациях не найдено')))
              else
                ...hospitalizations.map((h) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_hospital, color: Colors.redAccent),
                    title: Text(h['reason'] ?? 'Причина не указана'),
                    subtitle: Text('${h['admission_date']} — ${h['discharge_date']}\nОтделение: ${h['department']}'),
                    isThreeLine: true,
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Язык'),
            subtitle: const Text('Русский'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Темная тема'),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          ),
        ],
      ),
    );
  }
}
