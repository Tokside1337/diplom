import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/models/emk_model.dart';

/// Базовая логика сетевых запросов
mixin ApiClient {
  String? _token;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  Map<String, String> get headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  void setToken(String? token) => _token = token;

  Future<http.Response?> _safeRequest(Future<http.Response> Function() request, String label) async {
    try {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      debugPrint('API Error [$label]: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Network Error [$label]: $e');
    }
    return null;
  }
}

/// Сервис для работы с базой данных через Backend API
class DatabaseService with ApiClient {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // --- USERS ---
  Future<User?> loginUser(String login, String password) async {
    final res = await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'login': login, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      ),
      'loginUser',
    );
    if (res == null) return null;
    
    final data = jsonDecode(res.body);
    final String? token = data['accessToken'];
    final Map<String, dynamic>? userData = data['user'];

    if (token != null && userData != null) {
      setToken(token);
      return User(
        id: userData['id'],
        login: userData['login'] ?? '',
        password: '', 
        role: UserRole.values.firstWhere((e) => e.name == userData['role']),
        patientId: userData['patient_id'],
        doctorId: userData['doctor_id'],
      );
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/users'), headers: headers), 'getAllUsers');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((u) => User(
      id: u['id'],
      login: u['login'],
      password: u['password'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == u['role']),
      patientId: u['patient_id'],
      doctorId: u['doctor_id']
    )).toList();
  }

  Future<void> registerUser(User u) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        body: jsonEncode({
          'login': u.login, 'password': u.password, 'role': u.role.name,
          'patient_id': u.patientId, 'doctor_id': u.doctorId
        }),
        headers: headers,
      ),
      'registerUser',
    );
  }

  Future<void> updateUser(User u) async {
    await _safeRequest(
      () => http.put(
        Uri.parse('$baseUrl/users'),
        body: jsonEncode({
          'id': u.id, 'login': u.login, 'password': u.password, 'role': u.role.name,
          'patient_id': u.patientId, 'doctor_id': u.doctorId
        }),
        headers: headers,
      ),
      'updateUser',
    );
  }

  Future<void> deleteUser(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/users/$id'), headers: headers), 'deleteUser');

  // --- DOCTORS ---
  Future<List<Doctor>> getDoctors() async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/doctors'), headers: headers), 'getDoctors');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => Doctor(
      id: i['id'], name: i['name'], specialization: i['specialization'],
      phone: i['phone'], cabinet: i['cabinet']
    )).toList();
  }

  Future<Doctor?> getDoctorById(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/doctors/$id'), headers: headers), 'getDoctorById');
    if (res == null) return null;
    final i = jsonDecode(res.body);
    return Doctor(
      id: i['id'], name: i['name'], specialization: i['specialization'],
      phone: i['phone'], cabinet: i['cabinet']
    );
  }

  Future<int?> insertDoctor(Doctor d) async {
    final res = await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/doctors'),
        body: jsonEncode({
          'name': d.name, 'specialization': d.specialization,
          'phone': d.phone, 'cabinet': d.cabinet
        }),
        headers: headers,
      ),
      'insertDoctor',
    );
    return res != null ? jsonDecode(res.body)['id'] : null;
  }

  Future<void> updateDoctor(Doctor d) async {
    await _safeRequest(
      () => http.put(
        Uri.parse('$baseUrl/doctors'),
        body: jsonEncode({
          'id': d.id, 'name': d.name, 'specialization': d.specialization,
          'phone': d.phone, 'cabinet': d.cabinet
        }),
        headers: headers,
      ),
      'updateDoctor',
    );
  }

  Future<void> deleteDoctor(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/doctors/$id'), headers: headers), 'deleteDoctor');

  // --- PATIENTS ---
  Future<List<Patient>> getPatients() async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/patients'), headers: headers), 'getPatients');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => Patient.fromMap(i)).toList();
  }

  Future<Patient?> getPatientById(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/patients/$id'), headers: headers), 'getPatientById');
    return res != null ? Patient.fromMap(jsonDecode(res.body)) : null;
  }

  Future<int?> insertPatient(Patient p) async {
    final res = await _safeRequest(
      () => http.post(Uri.parse('$baseUrl/patients'), body: jsonEncode(p.toMap()), headers: headers),
      'insertPatient',
    );
    return res != null ? jsonDecode(res.body)['id'] : null;
  }

  Future<void> updatePatient(Patient p) async => 
      await _safeRequest(() => http.put(Uri.parse('$baseUrl/patients'), body: jsonEncode(p.toMap()), headers: headers), 'updatePatient');

  Future<void> deletePatient(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/patients/$id'), headers: headers), 'deletePatient');

  // --- EMK ---
  Future<EMK?> getEMK(int patientId) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/emk/$patientId'), headers: headers), 'getEMK');
    return res != null ? EMK.fromMap(jsonDecode(res.body)) : null;
  }

  Future<void> saveEMK(EMK emk) async {
    final existing = await getEMK(emk.patientId);
    final url = Uri.parse('$baseUrl/emk');
    final body = jsonEncode(emk.toMap());
    
    if (existing == null) {
      await _safeRequest(() => http.post(url, body: body, headers: headers), 'createEMK');
    } else {
      await _safeRequest(() => http.put(url, body: body, headers: headers), 'updateEMK');
    }
  }

  // --- MEASUREMENTS ---
  Future<List<Measurement>> getMeasurements(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/measurements/$id'), headers: headers), 'getMeasurements');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => Measurement(
      id: i['id'],
      patientId: i['patientId'],
      pressureSystolic: (i['pressureSystolic'] as num).toDouble(),
      pressureDiastolic: (i['pressureDiastolic'] as num).toDouble(),
      pulse: i['pulse'],
      painLevel: i['painLevel'],
      timestamp: i['timestamp']
    )).toList();
  }

  Future<void> insertMeasurement(Measurement m) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/measurements'),
        body: jsonEncode({
          'patientId': m.patientId, 'pressureSystolic': m.pressureSystolic,
          'pressureDiastolic': m.pressureDiastolic, 'pulse': m.pulse,
          'painLevel': m.painLevel, 'timestamp': m.timestamp
        }),
        headers: headers,
      ),
      'insertMeasurement',
    );
  }

  // --- MOOD & NOTES ---
  Future<List<MoodEntry>> getMoodEntries(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/mood/$id'), headers: headers), 'getMoodEntries');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => MoodEntry(
      id: i['id'], patientId: i['patientId'], score: i['score'],
      comment: i['comment'], timestamp: i['timestamp'], sentiment: i['sentiment']
    )).toList();
  }

  Future<void> insertMoodEntry(MoodEntry m) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/mood'),
        body: jsonEncode({
          'patientId': m.patientId, 'score': m.score, 'comment': m.comment,
          'timestamp': m.timestamp, 'sentiment': m.sentiment
        }),
        headers: headers,
      ),
      'insertMoodEntry',
    );
  }

  Future<void> deleteMoodEntry(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/mood/$id'), headers: headers), 'deleteMoodEntry');

  Future<List<Map<String, dynamic>>> getNotes(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/notes/$id'), headers: headers), 'getNotes');
    return res != null ? List<Map<String, dynamic>>.from(jsonDecode(res.body)) : [];
  }

  Future<void> insertNote(int patientId, String author, String content) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/notes'),
        body: jsonEncode({
          'patientId': patientId, 'author': author, 'content': content,
          'timestamp': DateTime.now().toUtc().add(const Duration(hours: 3)).toString()
        }),
        headers: headers,
      ),
      'insertNote',
    );
  }

  // --- APPOINTMENTS & SCHEDULE ---
  Future<List<Appointment>> getAppointments(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/appointments/$id'), headers: headers), 'getAppointments');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => Appointment(
      id: i['id'], patientId: i['patientId'], type: i['type'],
      title: i['title'], time: i['time'], room: i['room'],
      doctor: i['doctor'], status: i['status']
    )).toList();
  }

  Future<void> insertAppointment(Appointment a) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/appointments'),
        body: jsonEncode({
          'patientId': a.patientId, 'type': a.type, 'title': a.title,
          'time': a.time, 'room': a.room, 'doctor': a.doctor, 'status': a.status
        }),
        headers: headers,
      ),
      'insertAppointment',
    );
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    await _safeRequest(
      () => http.put(
        Uri.parse('$baseUrl/appointments/status'),
        body: jsonEncode({'id': id, 'status': status}),
        headers: headers,
      ),
      'updateAppointmentStatus',
    );
  }

  Future<void> deleteAppointment(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/appointments/$id'), headers: headers), 'deleteAppointment');

  Future<List<Map<String, dynamic>>> getDoctorSchedule(String doctorName) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/schedule/${Uri.encodeComponent(doctorName)}'), headers: headers), 'getDoctorSchedule');
    return res != null ? List<Map<String, dynamic>>.from(jsonDecode(res.body)) : [];
  }

  // --- QUESTIONNAIRES & HOSPITALIZATIONS ---
  Future<List<QuestionnaireResult>> getQuestionnaireResults(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/questionnaires/$id'), headers: headers), 'getQuestionnaires');
    if (res == null) return [];
    final List d = jsonDecode(res.body);
    return d.map((i) => QuestionnaireResult(
      id: i['id'], patientId: i['patientId'], title: i['title'],
      totalScore: i['totalScore'], date: i['date']
    )).toList();
  }

  Future<void> insertQuestionnaireResult(QuestionnaireResult q) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/questionnaires'),
        body: jsonEncode({
          'patientId': q.patientId, 'title': q.title,
          'totalScore': q.totalScore, 'date': q.date
        }),
        headers: headers,
      ),
      'insertQuestionnaire',
    );
  }

  Future<void> deleteQuestionnaireResult(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/questionnaires/$id'), headers: headers), 'deleteQuestionnaire');

  Future<List<Map<String, dynamic>>> getHospitalizations(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/hospitalizations/$id'), headers: headers), 'getHospitalizations');
    return res != null ? List<Map<String, dynamic>>.from(jsonDecode(res.body)) : [];
  }

  Future<void> insertHospitalization(int pId, String a, String d, String r, String dep) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/hospitalizations'),
        body: jsonEncode({
          'patientId': pId, 'admission_date': a, 'discharge_date': d,
          'reason': r, 'department': dep
        }),
        headers: headers,
      ),
      'insertHospitalization',
    );
  }

  // --- REMINDERS ---
  Future<void> sendReminder(int patientId, int doctorId, String message) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/reminders'),
        body: jsonEncode({
          'patient_id': patientId, 'doctor_id': doctorId, 'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: headers,
      ),
      'sendReminder',
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadReminders(int patientId) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/reminders/unread/$patientId'), headers: headers), 'getReminders');
    return res != null ? List<Map<String, dynamic>>.from(jsonDecode(res.body)) : [];
  }

  Future<void> markReminderAsRead(int id) async => 
      await _safeRequest(() => http.put(Uri.parse('$baseUrl/reminders/read/$id'), headers: headers), 'markReminderRead');
}
