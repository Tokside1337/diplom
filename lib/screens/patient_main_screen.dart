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
    final bool isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1200,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: MediaQuery.of(context).size.width > 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Главная')),
                NavigationRailDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book_rounded), label: Text('Дневник')),
                NavigationRailDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology_rounded), label: Text('ИИ Чат')),
                NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: Text('Профиль')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: Text('Настройки')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book_rounded), label: 'Дневник'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology_rounded), label: 'ИИ Чат'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Профиль'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Настройки'),
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
    final colorScheme = Theme.of(context).colorScheme;

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
              Text('Последние замеры', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...measurements.reversed.take(5).map((m) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                  ),
                  title: Text('${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()} мм рт.ст.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Пульс: ${m.pulse} | ${m.timestamp.substring(11, 16)}'),
                ),
              )),
              const SizedBox(height: 24),
              Text('Записи настроения', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...moods.reversed.take(5).map((m) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: Icon(
                    m.sentiment == 'Positive' ? Icons.sentiment_very_satisfied_rounded : Icons.sentiment_neutral_rounded,
                    color: m.sentiment == 'Positive' ? Colors.green : Colors.orange,
                  ),
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
          _messages.add({'role': 'ai', 'content': 'Извините, произошла ошибка.'});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с ИИ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                final m = _messages[index];
                final isAi = m['role'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAi ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAi ? 4 : 16),
                        bottomRight: Radius.circular(isAi ? 16 : 4),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(m['content']!, style: TextStyle(color: isAi ? colorScheme.onSurfaceVariant : colorScheme.onPrimary)),
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
                      hintText: 'Спросите ИИ...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded)),
              ],
            ),
          ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Мой профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection(context, 'ЛИЧНЫЕ ДАННЫЕ', [
            _ProfileItem(Icons.badge_outlined, 'ФИО', patient.name),
            _ProfileItem(Icons.cake_outlined, 'Дата рождения', patient.birthDate),
            _ProfileItem(Icons.wc_rounded, 'Пол', patient.gender ?? 'Не указан'),
            _ProfileItem(Icons.fingerprint_rounded, 'СНИЛС', patient.snils ?? 'Не указан'),
            _ProfileItem(Icons.description_outlined, 'Паспорт', patient.passportData ?? 'Не указан'),
            _ProfileItem(Icons.phone_android_rounded, 'Телефон', patient.phone ?? 'Не указан'),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection(context, 'САНАТОРНО-КУРОРТНАЯ КАРТА', [
            _ProfileItem(Icons.history_edu_rounded, 'Номер СКК', patient.skkNumber ?? '—'),
            _ProfileItem(Icons.calendar_month_rounded, 'Дата выдачи', patient.skkDate ?? '—'),
            _ProfileItem(Icons.account_balance_rounded, 'Кем выдана', patient.issuedByLpu ?? '—'),
            _ProfileItem(Icons.medical_services_rounded, 'Диагноз (МКБ)', patient.mainDiagnosisMkb ?? '—'),
            _ProfileItem(Icons.restaurant_rounded, 'Диет. стол', patient.dietTable ?? 'Стандарт'),
            _ProfileItem(Icons.directions_run_rounded, 'Режим', patient.mobilityRegime ?? 'Общий'),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection(context, 'РАЗМЕЩЕНИЕ', [
            _ProfileItem(Icons.apartment_rounded, 'Корпус / Этаж', '${patient.building ?? '—'} / ${patient.floor ?? '—'}'),
            _ProfileItem(Icons.meeting_room_rounded, 'Номер палаты', patient.roomNumber ?? '—'),
            _ProfileItem(Icons.hotel_class_rounded, 'Категория', patient.roomCategory ?? '—'),
            _ProfileItem(Icons.login_rounded, 'Заезд (план)', patient.plannedArrival ?? '—'),
            _ProfileItem(Icons.logout_rounded, 'Выезд (план)', patient.plannedDeparture ?? '—'),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection(context, 'ДОПОЛНИТЕЛЬНО', [
            _ProfileItem(Icons.family_restroom_rounded, 'Контакт близких', patient.relativeContact),
            _ProfileItem(Icons.supervisor_account_rounded, 'Сопровождающий', patient.companionData ?? 'Нет'),
            _ProfileItem(Icons.credit_card_rounded, 'Источник фин.', patient.fundingSource ?? '—'),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<_ProfileItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: 1.1)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: colorScheme.primary, size: 20),
                    title: Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    subtitle: Text(item.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                  if (idx < items.length - 1) Divider(indent: 56, endIndent: 16, height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;
  _ProfileItem(this.icon, this.label, this.value);
}

class _SettingsTab extends StatelessWidget {
  void _showAbout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety_rounded, size: 64, color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Система РеСтарт',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Дипломный проект по системе мониторинга состояния пациентов и поддержки принятия врачебных решений.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Разработано в рамках ВКР, 2026',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
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
