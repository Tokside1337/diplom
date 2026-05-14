import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/services/database_service.dart';
import 'package:diplom/services/ai_service.dart';
import 'package:diplom/screens/questionnaire_screen.dart';
import 'package:diplom/screens/communication_screen.dart';
import 'package:diplom/screens/login_screen.dart';

class Recommendation {
  final String text;
  final String priority;
  final IconData icon;
  Recommendation({required this.text, required this.priority, required this.icon});
}

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  final bool isPatientView;
  final bool hideNavigation;
  final Doctor? doctor;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
    this.isPatientView = false,
    this.hideNavigation = false,
    this.doctor,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Measurement> _measurements = [];
  List<MoodEntry> _moods = [];
  List<Appointment> _appointments = [];
  List<QuestionnaireResult> _qResults = [];
  List<Doctor> _allDoctors = [];
  String _trend = 'Загрузка...';
  bool _isMoodExpanded = false;
  Doctor? _assignedDoctor;
  List<Map<String, dynamic>> _unreadReminders = [];

  static const List<String> _procedureOptions = [
    'ЭКГ (Электрокардиография)',
    'УЗИ брюшной полости',
    'УЗИ сердца (ЭхоКГ)',
    'МРТ головного мозга',
    'КТ грудной клетки',
    'Общий анализ крови',
    'Биохимический анализ крови',
    'Анализ мочи',
    'Флюорография',
    'Рентген',
    'Гастроскопия',
    'Колоноскопия',
    'Прием кардиолога',
    'Прием терапевта',
    'Прием невролога',
    'Прием офтальмолога',
    'Прием хирурга',
    'Прием ЛОРа',
    'Прием эндокринолога',
    'Прием психотерапевта',
    'Прием врача ЛФК',
    'Прием физиотерапевта',
    'Прием реабилитолога',
    'Прием логопеда',
    'Прием травматолога',
    'Прием гастроэнтеролога',
    'Прием дерматолога',
    'Холтеровское мониторирование',
    'СМАД (измерение давления)',
    'ЭЭГ (Электроэнцефалография)',
    'Спирометрия',
    'Велоэргометрия (ВЭМ)',
    'Перевязка',
    'Инъекция внутримышечная',
    'Капельница',
    'ЛФК (индивидуальное занятие)',
    'ЛФК (групповое занятие)',
    'ЛФК в бассейне',
    'Скандинавская ходьба',
    'Механотерапия',
    'Занятие на тренажерах',
    'Занятие на стабилоплатформе',
    'Дыхательная гимнастика',
    'Массаж спины',
    'Массаж воротниковой зоны',
    'Общий массаж',
    'Лимфодренажный массаж',
    'Электрофорез',
    'Магнитотерапия',
    'Лазеротерапия',
    'УВЧ-терапия',
    'Иглорефлексотерапия',
    'Парафинотерапия',
    'Грязелечение',
    'Занятие с эрготерапевтом',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    try {
      final m = await _dbService.getMeasurements(widget.patient.id!);
      final mood = await _dbService.getMoodEntries(widget.patient.id!);
      final appts = await _dbService.getAppointments(widget.patient.id!);
      final qres = await _dbService.getQuestionnaireResults(widget.patient.id!);
      final docs = await _dbService.getDoctors();
      
      Doctor? assignedDoc;
      if (widget.patient.doctorId != null) {
        try {
          assignedDoc = docs.firstWhere((d) => d.id == widget.patient.doctorId);
        } catch (_) {}
      }

      if (widget.isPatientView) {
        final reminders = await _dbService.getUnreadReminders(widget.patient.id!);
        if (mounted && reminders.isNotEmpty) {
          setState(() {
            _unreadReminders = reminders;
          });
          _showReminders();
        }
      }
      
      if (mounted) {
        setState(() {
          _measurements = m;
          _moods = mood;
          _appointments = appts;
          _qResults = qres;
          _allDoctors = docs;
          _assignedDoctor = assignedDoc;
          _trend = AIService.analyzeTrend(m);
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _showReminders() {
    if (_unreadReminders.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var reminder in _unreadReminders) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.notification_important_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Text('Напоминание'),
              ],
            ),
            content: Text(reminder['message']),
            actions: [
              TextButton(
                onPressed: () async {
                  await _dbService.markReminderAsRead(reminder['id']);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      }
      setState(() {
        _unreadReminders = [];
      });
    });
  }

  String _getAppointmentType(String title) {
    final t = title.toLowerCase();
    if (t.contains('анализ') || t.contains('кров') || t.contains('моч')) return 'Анализ';
    if (t.contains('прием') || t.contains('консультация') || t.contains('осмотр') || t.contains('обход') || t.contains('занятие с')) return 'Осмотр';
    if (t.contains('узи') || t.contains('экг') || t.contains('мрт') || t.contains('кт') || 
        t.contains('рентген') || t.contains('флюоро') || t.contains('холтер') || t.contains('смад') || 
        t.contains('эхокг') || t.contains('ээг') || t.contains('спирометр') || t.contains('вэм')) {
      return 'Диагностика';
    }
    if (t.contains('перевяз') || t.contains('инъекц') || t.contains('капельн') || t.contains('укол') || 
        t.contains('массаж') || t.contains('терапия') || t.contains('лфк') || t.contains('ходьба') || 
        t.contains('механо') || t.contains('тренажер') || t.contains('стабило') || t.contains('гимнастика') || 
        t.contains('электрофорез') || t.contains('магнито') || t.contains('лазер') || t.contains('увч') || 
        t.contains('игло') || t.contains('грязе') || t.contains('парафин')) {
      return 'Процедура';
    }
    return 'Процедура';
  }

  Future<void> _deleteAppointment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление мероприятия'),
        content: const Text('Вы уверены, что хотите удалить это мероприятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteAppointment(id);
      _loadData();
    }
  }

  Future<void> _deleteMood(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление записи'),
        content: const Text('Удалить эту запись из дневника настроения?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteMoodEntry(id);
      _loadData();
    }
  }

  Future<void> _deleteQuestionnaireResult(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление результата'),
        content: const Text('Вы уверены, что хотите удалить этот результат опросника?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteQuestionnaireResult(id);
      _loadData();
    }
  }

  void _showMoodDetails(MoodEntry mood) {
    Color scoreColor;
    if (mood.score >= 4) {
      scoreColor = Colors.green;
    } else if (mood.score == 3) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.psychology_rounded, color: scoreColor),
            const SizedBox(width: 12),
            const Text('Запись в дневнике'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Дата: ${mood.timestamp.substring(0, 16)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: scoreColor.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: Text('Оценка ИИ: ${mood.score}/5', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(mood.comment, style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _addAppointment() async {
    final titleController = TextEditingController();
    final typeController = TextEditingController(text: 'Процедура');
    final roomController = TextEditingController();
    final doctorController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Icon(Icons.event_available_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Назначение'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return _procedureOptions.where((option) =>
                          option.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      titleController.text = selection;
                      setDialogState(() {
                        typeController.text = _getAppointmentType(selection);
                      });
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (value) {
                          titleController.text = value;
                          setDialogState(() {
                            typeController.text = _getAppointmentType(value);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Название мероприятия',
                          prefixIcon: const Icon(Icons.title_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Тип',
                      prefixIcon: const Icon(Icons.category_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: roomController,
                    decoration: InputDecoration(
                      labelText: 'Кабинет',
                      prefixIcon: const Icon(Icons.meeting_room_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      final names = _allDoctors.map((d) => d.name).toList();
                      return names.where((option) =>
                          option.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      doctorController.text = selection;
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (value) => doctorController.text = value,
                        decoration: InputDecoration(
                          labelText: 'Врач',
                          prefixIcon: const Icon(Icons.person_search_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text("Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate)}"),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date != null) setDialogState(() => selectedDate = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded),
                    title: Text("Время: ${selectedTime.format(context)}"),
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) setDialogState(() => selectedTime = time);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final doctor = doctorController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название мероприятия')));
                  return;
                }

                final fullDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                await _dbService.insertAppointment(Appointment(
                  patientId: widget.patient.id!,
                  type: typeController.text,
                  title: title,
                  time: fullDateTime.toString(),
                  room: roomController.text,
                  doctor: doctor,
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Назначить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMeasurement() async {
    final systolicController = TextEditingController(text: '120');
    final diastolicController = TextEditingController(text: '80');
    final pulseController = TextEditingController(text: '70');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.add_chart_rounded, color: colorScheme.secondary),
            const SizedBox(width: 12),
            const Text('Новый замер'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: systolicController, 
                    keyboardType: TextInputType.number, 
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Сист.', 
                      hintText: '120',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300))),
                Expanded(
                  child: TextField(
                    controller: diastolicController, 
                    keyboardType: TextInputType.number, 
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Диаст.', 
                      hintText: '80',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pulseController, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(
                labelText: 'Пульс', 
                prefixIcon: const Icon(Icons.favorite_rounded, color: Colors.red),
                suffixText: 'уд/мин',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              await _dbService.insertMeasurement(Measurement(
                patientId: widget.patient.id!,
                pressureSystolic: double.tryParse(systolicController.text) ?? 120.0,
                pressureDiastolic: double.tryParse(diastolicController.text) ?? 80.0,
                pulse: int.tryParse(pulseController.text) ?? 70,
                painLevel: 0,
                timestamp: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMood() async {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Дневник настроения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Опишите ваше самочувствие, и ИИ определит ваше состояние'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController, 
              maxLines: 4, 
              decoration: InputDecoration(
                hintText: 'Например: Сегодня чувствую себя бодро, выспался и готов к прогулке...', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пожалуйста, напишите что-нибудь')));
                return;
              }

              final calculatedScore = AIService.calculateMoodScore(comment);
              final sentiment = AIService.analyzeSentiment(comment);

              await _dbService.insertMoodEntry(MoodEntry(
                patientId: widget.patient.id!, 
                score: calculatedScore, 
                comment: comment,
                timestamp: DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
                sentiment: sentiment,
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPressureReminder() async {
    if (widget.doctor == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Напоминание'),
        content: const Text('Отправить пациенту уведомление с просьбой измерить давление?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.sendReminder(
        widget.patient.id!, 
        widget.doctor!.id!, 
        'Ваш лечащий врач просит вас измерить артериальное давление.'
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Напоминание отправлено')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPatientView) return _buildPatientProfile();
    return _buildDoctorView();
  }

  Widget _buildSectionTitle(String title, {double bottomMargin = 12}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPatientProfile() {
    return Scaffold(
      appBar: widget.hideNavigation ? null : AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle('Рекомендации и Анализ ИИ'),
              _buildAICard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Мои показатели давления'),
              _buildChart(),
              const SizedBox(height: 12),
              _buildMeasurementsDetails(),
              const SizedBox(height: 24),
              _buildSectionTitle('План мероприятий'),
              _buildAppointmentsList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Результаты опросников'),
              _buildQuestionnaireResults(),
              const SizedBox(height: 24),
              _buildSectionTitle('Дневник настроения'),
              _buildMoodList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildGlassFab([
        _ActionItem(Icons.mood_rounded, 'Дневник', Theme.of(context).colorScheme.primary, _addMood),
        _ActionItem(Icons.add_chart_rounded, 'Замер', Theme.of(context).colorScheme.secondary, _addMeasurement),
      ]),
    );
  }

  Widget _buildDoctorView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Пациент: ${_formatNameShort(widget.patient.name)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CommunicationScreen(patientId: widget.patient.id!, isPatientView: false, doctor: widget.doctor))).then((_) => _loadData()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Аналитика ИИ и Прогноз'),
              _buildAICard(centeredTitle: true),
              const SizedBox(height: 24),
              _buildSectionTitle('График давления'),
              _buildChart(),
              const SizedBox(height: 12),
              _buildMeasurementsDetails(),
              const SizedBox(height: 24),
              _buildSectionTitle('План мероприятий'),
              _buildAppointmentsList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Результаты опросников'),
              _buildQuestionnaireResults(),
              const SizedBox(height: 24),
              _buildSectionTitle('Психологический профиль'),
              _buildMoodList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildGlassFab([
        _ActionItem(Icons.notification_add_rounded, 'Давление', Colors.red, _sendPressureReminder),
        _ActionItem(Icons.event_rounded, 'Мероприятие', Colors.orange, _addAppointment),
        _ActionItem(Icons.assignment_rounded, 'Опросник', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuestionnaireScreen(patientId: widget.patient.id!))).then((_) => _loadData())),
      ]),
    );
  }

  Widget _buildGlassFab(List<_ActionItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Expanded(
                  child: Row(
                    children: [
                      if (idx > 0) VerticalDivider(width: 1, thickness: 1, indent: 20, endIndent: 20, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      Expanded(
                        child: InkWell(
                          onTap: item.onTap,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.icon, color: item.color, size: 22),
                                const SizedBox(width: 8),
                                Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(backgroundColor: colorScheme.primaryContainer, child: Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer)),
            title: Text(_formatNameShort(widget.patient.name), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Дата рождения: ${widget.patient.birthDate}'),
          ),
          if (_assignedDoctor != null) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            ListTile(
              dense: true,
              leading: Icon(Icons.medical_services_outlined, color: colorScheme.secondary, size: 20),
              title: Text('Ваш врач: ${_assignedDoctor!.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('${_assignedDoctor!.specialization}${_assignedDoctor!.cabinet != null ? ' • Каб. ${_assignedDoctor!.cabinet}' : ''}', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAICard({bool centeredTitle = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark ? colorScheme.primaryContainer.withValues(alpha: 0.1) : colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded, color: colorScheme.primary), 
                  const SizedBox(width: 12), 
                  Text(centeredTitle ? 'ИИ помощник' : 'Анализ ИИ', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_trend, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_measurements.isEmpty) return const SizedBox();
    return Container(
      height: 220,
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4))),
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles()),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureSystolic)).toList(), color: Colors.red, dotData: const FlDotData(show: true), isCurved: true),
          LineChartBarData(spots: _measurements.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.pressureDiastolic)).toList(), color: Colors.blue, dotData: const FlDotData(show: true), isCurved: true),
        ],
      )),
    );
  }

  Widget _buildMeasurementsDetails() {
    if (_measurements.isEmpty) return const SizedBox();
    return Column(
      children: _measurements.reversed.take(3).map((m) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
        child: ListTile(dense: true, leading: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20), title: Text('${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()} мм рт.ст.', style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(m.timestamp.substring(11, 16))),
      )).toList(),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) return const Card(child: ListTile(title: Text('Мероприятий нет')));
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: _appointments.map((app) {
        Color? statusColor;
        IconData? statusIcon;
        
        if (app.status == 'completed') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_rounded;
        } else if (app.status == 'missed') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel_rounded;
        } else if (app.status == 'waiting') {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time_filled_rounded;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: statusColor?.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(
              color: statusColor?.withValues(alpha: 0.4) ?? colorScheme.outlineVariant.withValues(alpha: 0.4)
            )
          ),
          child: ListTile(
            title: Text(app.title, style: const TextStyle(fontWeight: FontWeight.bold)), 
            subtitle: Text('${app.doctor} • Каб. ${app.room}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) 
                  Icon(statusIcon, color: statusColor, size: 20),
                if (!widget.isPatientView) 
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _deleteAppointment(app.id!),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodList() {
    if (_moods.isEmpty) return const Card(child: ListTile(title: Text('Дневник пуст')));
    
    final reversedMoods = _moods.reversed.toList();
    final moodsToShow = _isMoodExpanded ? reversedMoods : reversedMoods.take(3).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: Column(
            children: List.generate(moodsToShow.length, (index) {
              final m = moodsToShow[index];
              Color scoreColor;
              IconData moodIcon;
              if (m.score >= 4) {
                scoreColor = Colors.green;
                moodIcon = Icons.sentiment_very_satisfied_rounded;
              } else if (m.score == 3) {
                scoreColor = Colors.orange;
                moodIcon = Icons.sentiment_neutral_rounded;
              } else {
                scoreColor = Colors.red;
                moodIcon = Icons.sentiment_very_dissatisfied_rounded;
              }

              // Эффект затухания для последней карточки в свернутом виде
              final isLastInCollapsed = !_isMoodExpanded && index == 2 && reversedMoods.length > 3;

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: scoreColor.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), 
                      side: BorderSide(color: scoreColor.withValues(alpha: 0.3))
                    ),
                    child: ListTile(
                      onTap: () => _showMoodDetails(m),
                      leading: Icon(moodIcon, color: scoreColor), 
                      title: Text(m.comment, maxLines: 2, overflow: TextOverflow.ellipsis), 
                      subtitle: Text('Оценка: ${m.score} • ${m.timestamp.substring(0, 16)}', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
                      trailing: !widget.isPatientView ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => _deleteMood(m.id!),
                      ) : null,
                    ),
                  ),
                  if (isLastInCollapsed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        if (reversedMoods.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isMoodExpanded = !_isMoodExpanded),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _isMoodExpanded 
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: _isMoodExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isMoodExpanded ? 'СВЕРНУТЬ' : 'ВСЯ ИСТОРИЯ (${reversedMoods.length})',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionnaireResults() {
    if (_qResults.isEmpty) return const Card(child: ListTile(title: Text('Нет результатов')));
    return Column(
      children: _qResults.map((res) {
        Color resultColor;
        if (res.totalScore <= 5) {
          resultColor = Colors.green;
        } else if (res.totalScore <= 10) {
          resultColor = Colors.orange;
        } else {
          resultColor = Colors.red;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: resultColor.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: BorderSide(color: resultColor.withValues(alpha: 0.3))
          ),
          child: ListTile(
            title: Text(res.title), 
            subtitle: Text('Дата: ${res.date.substring(0, 16)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${res.totalScore} баллов', 
                    style: TextStyle(color: resultColor, fontWeight: FontWeight.bold)
                  ),
                ),
                if (!widget.isPatientView) 
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () => _deleteQuestionnaireResult(res.id!),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _ActionItem(this.icon, this.label, this.color, this.onTap);
}
