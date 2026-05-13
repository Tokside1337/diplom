import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/screens/patient_list_screen.dart';
import 'package:diplom/screens/login_screen.dart';
import 'package:diplom/providers/settings_provider.dart';
import 'package:diplom/services/ai_service.dart';
import 'package:diplom/services/database_service.dart';

class DoctorMainScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorMainScreen({super.key, required this.doctor});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PatientListScreen(hideAppBar: true, doctor: widget.doctor),
      _DoctorScheduleTab(doctor: widget.doctor),
      _DoctorAIChatTab(),
      _DoctorProfileTab(doctor: widget.doctor),
      _DoctorSettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(title: const Text('Список пациентов')) : null,
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Пациенты'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'График'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'ИИ Помощник'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}

class _DoctorScheduleTab extends StatefulWidget {
  final Doctor doctor;
  const _DoctorScheduleTab({required this.doctor});

  @override
  State<_DoctorScheduleTab> createState() => _DoctorScheduleTabState();
}

class _DoctorScheduleTabState extends State<_DoctorScheduleTab> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  String _formatNameShort(String fullName) {
    if (fullName.isEmpty) return "";
    if (fullName.contains('.')) return fullName;
    List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      return "${parts[0]} ${parts[1][0]}.${parts[2][0]}.";
    } else if (parts.length == 2) {
      return "${parts[0]} ${parts[1][0]}.";
    }
    return fullName;
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Ищем мероприятия по краткому имени врача (как они сохраняются в базе)
      final formattedDoctorName = _formatNameShort(widget.doctor.name);
      final schedule = await _dbService.getDoctorSchedule(formattedDoctorName);
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки графика: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('График приемов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedule,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedule,
              child: _schedule.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Назначенных мероприятий пока нет'),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedule.length,
                      itemBuilder: (context, index) {
                        final item = _schedule[index];
                        final dateTime = DateTime.parse(item['time'] as String);
                        final formattedDate = "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}";
                        final formattedTime = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          color: isDark ? Colors.grey[900] : Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade100,
                              child: Icon(Icons.event, color: isDark ? Colors.blue[300] : Colors.blue.shade800),
                            ),
                            title: Text(
                              item['title'] as String, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Пациент: ${_formatNameShort(item['patient_name'] as String)}',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[300] : Colors.black87, 
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                                Text(
                                  'Кабинет: ${item['room']} • ${item['type']}',
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedDate, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[300] : Colors.black87,
                                  )
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formattedTime, 
                                    style: TextStyle(
                                      color: isDark ? Colors.blue[300] : Colors.blue, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _DoctorAIChatTab extends StatefulWidget {
  @override
  State<_DoctorAIChatTab> createState() => _DoctorAIChatTabState();
}

class _DoctorAIChatTabState extends State<_DoctorAIChatTab> {
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'content': 'Здравствуйте, коллега! Чем я могу помочь вам в анализе данных пациентов?'}
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
      final aiResponse = await AIService.chatWithAI(userMessage, 0, isDoctor: true);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': aiResponse});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Ошибка связи с ИИ-помощником.'});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ИИ Помощник врача')),
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
                          ? (isDark ? Colors.blueGrey[800] : Colors.blue.shade50)
                          : (isDark ? Colors.teal[900] : Colors.green.shade50),
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
                      hintText: 'Введите запрос...',
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

class _DoctorProfileTab extends StatelessWidget {
  final Doctor doctor;
  const _DoctorProfileTab({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(radius: 60, child: Icon(Icons.medical_services, size: 60)),
          ),
          const SizedBox(height: 24),
          _buildInfoTile(context, 'ФИО', doctor.name, Icons.badge),
          _buildInfoTile(context, 'Специализация', doctor.specialization, Icons.assignment_ind),
          _buildInfoTile(context, 'Телефон', doctor.phone ?? 'Не указан', Icons.phone),
          _buildInfoTile(context, 'Кабинет', doctor.cabinet ?? 'Не указан', Icons.meeting_room),
        ],
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

class _DoctorSettingsTab extends StatelessWidget {
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
                        'Система Реабилитации (Врач)',
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
