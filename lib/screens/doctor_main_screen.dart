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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Пациенты'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'График'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology_rounded), label: 'ИИ Помощник'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services_rounded), label: 'Профиль'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Настройки'),
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
      final doctorName = widget.doctor.name;
      final schedule = await _dbService.getDoctorSchedule(doctorName);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('График приемов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_rounded, size: 64, color: colorScheme.outline),
                              const SizedBox(height: 16),
                              const Text('Назначенных мероприятий пока нет'),
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
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withAlpha(102),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.event_rounded, color: colorScheme.primary),
                            ),
                            title: Text(
                              item['title'] as String, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Пациент: ${_formatNameShort(item['patient_name'] as String)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'Кабинет: ${item['room']} • ${item['type']}',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedDate, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    formattedTime, 
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer, 
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ИИ Помощник врача'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                final m = _messages[index];
                final isAi = m['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAi ? colorScheme.secondaryContainer : colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAi ? 4 : 16),
                        bottomRight: Radius.circular(isAi ? 16 : 4),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(m['content']!, style: TextStyle(color: isAi ? colorScheme.onSecondaryContainer : colorScheme.onPrimary)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller, 
                    decoration: InputDecoration(
                      hintText: 'Введите запрос...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  )
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60, 
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.medical_services_rounded, size: 60, color: colorScheme.onPrimaryContainer)
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
            ),
            child: Column(
              children: [
                _buildInfoTile(context, 'ФИО', doctor.name, Icons.badge_outlined),
                _buildDivider(colorScheme),
                _buildInfoTile(context, 'Специализация', doctor.specialization, Icons.assignment_ind_outlined),
                _buildDivider(colorScheme),
                _buildInfoTile(context, 'Телефон', doctor.phone ?? 'Не указан', Icons.phone_outlined),
                _buildDivider(colorScheme),
                _buildInfoTile(context, 'Кабинет', doctor.cabinet ?? 'Не указан', Icons.meeting_room_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) => Divider(indent: 56, endIndent: 16, height: 1, color: colorScheme.outlineVariant.withAlpha(76));

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _DoctorSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSettingsHeader('Внешний вид'),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: colorScheme.primary),
            title: const Text('Темная тема'),
            value: settings.isDarkMode, 
            onChanged: (v) => settings.toggleTheme(v),
          ),
          ListTile(
            leading: Icon(Icons.format_size_rounded, color: colorScheme.primary),
            title: const Text('Размер шрифта'),
            subtitle: Slider(
              value: settings.fontSizeMultiplier,
              min: 0.8, max: 1.5, divisions: 7,
              label: '${(settings.fontSizeMultiplier * 100).toInt()}%',
              onChanged: (v) => settings.setFontSizeMultiplier(v),
            ),
          ),
          const Divider(height: 32),
          _buildSettingsHeader('Аккаунт'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('О приложении'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
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

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }
}
