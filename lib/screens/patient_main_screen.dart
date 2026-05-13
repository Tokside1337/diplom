import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/screens/patient_details_screen.dart';
import 'package:diplom/screens/login_screen.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/services/ai_service.dart';
import 'package:diplom/providers/settings_provider.dart';

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
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;
    
    final userMessage = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final aiResponse = await AIService.chatWithAI(userMessage, widget.patient.id!);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': aiResponse});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Извините, произошла ошибка при связи с ИИ.'});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с ИИ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                
                final m = _messages[index];
                final isAi = m['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAi 
                          ? (isDark ? Colors.grey[800] : Colors.grey[200])
                          : (isDark ? Colors.blue[900] : Colors.blue[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    child: Text(
                      m['content']!,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller, 
                    decoration: const InputDecoration(
                      hintText: 'Спросите ИИ...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue), 
                  onPressed: _sendMessage
                ),
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
              _buildInfoTile(context, 'ФИО', patient.name, Icons.badge),
              _buildInfoTile(context, 'Дата рождения', patient.birthDate, Icons.cake),
              _buildInfoTile(context, 'Контакт близких', patient.relativeContact, Icons.family_restroom),
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

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Внешний вид', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Темная тема'),
            trailing: Switch(
              value: settings.isDarkMode, 
              onChanged: (v) => settings.toggleTheme(v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Размер шрифта', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.format_size, size: 16),
                Expanded(
                  child: Slider(
                    value: settings.fontSizeMultiplier,
                    min: 0.8,
                    max: 2.0,
                    divisions: 6,
                    label: '${(settings.fontSizeMultiplier * 100).toInt()}%',
                    onChanged: (v) => settings.setFontSizeMultiplier(v),
                  ),
                ),
                const Icon(Icons.format_size, size: 28),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Аккаунт', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('О приложении'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services, color: Colors.blue, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Система Реабилитации',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text('Версия: 1.0.0'),
                      SizedBox(height: 16),
                      Text(
                        'Цифровая платформа для мониторинга и сопровождения процесса реабилитации пациентов.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
