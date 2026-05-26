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
      return response; // Return even error response for status check
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
    
    if (res == null || res.statusCode != 200) return null;
    
    try {
      final data = jsonDecode(res.body);
      final String? token = data['accessToken'];
      final Map<String, dynamic>? userData = data['user'];

      if (token != null && userData != null) {
        setToken(token);
        return User.fromMap(userData);
      }
    } catch (e) {
      debugPrint('loginUser parse error: $e');
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/users'), headers: headers), 'getAllUsers');
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((u) => User.fromMap(u)).toList();
    } catch (e) {
      debugPrint('getAllUsers error: $e');
    }
    return [];
  }

  Future<void> registerUser(User u) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        body: jsonEncode(u.toMap()),
        headers: headers,
      ),
      'registerUser',
    );
  }

  Future<void> updateUser(User u) async {
    await _safeRequest(
      () => http.put(
        Uri.parse('$baseUrl/users'),
        body: jsonEncode(u.toMap()),
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
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => Doctor.fromMap(i)).toList();
    } catch (e) {
      debugPrint('getDoctors parse error: $e');
    }
    return [];
  }

  Future<Doctor?> getDoctorById(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/doctors/$id'), headers: headers), 'getDoctorById');
    if (res == null || res.statusCode != 200) return null;
    try {
      return Doctor.fromMap(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getDoctorById parse error: $e');
    }
    return null;
  }

  Future<int?> insertDoctor(Doctor d) async {
    final res = await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/doctors'),
        body: jsonEncode(d.toMap()),
        headers: headers,
      ),
      'insertDoctor',
    );
    if (res != null && res.statusCode == 200) {
      return jsonDecode(res.body)['id'];
    }
    return null;
  }

  Future<void> updateDoctor(Doctor d) async {
    await _safeRequest(
      () => http.put(
        Uri.parse('$baseUrl/doctors'),
        body: jsonEncode(d.toMap()),
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
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => Patient.fromMap(i)).toList();
    } catch (e) {
      debugPrint('getPatients parse error: $e');
    }
    return [];
  }

  Future<Patient?> getPatientById(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/patients/$id'), headers: headers), 'getPatientById');
    if (res == null || res.statusCode != 200) return null;
    try {
      return Patient.fromMap(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getPatientById parse error: $e');
    }
    return null;
  }

  Future<int?> insertPatient(Patient p) async {
    final res = await _safeRequest(
      () => http.post(Uri.parse('$baseUrl/patients'), body: jsonEncode(p.toMap()), headers: headers),
      'insertPatient',
    );
    if (res != null && res.statusCode == 200) {
      return jsonDecode(res.body)['id'];
    }
    return null;
  }

  Future<void> updatePatient(Patient p) async => 
      await _safeRequest(() => http.put(Uri.parse('$baseUrl/patients'), body: jsonEncode(p.toMap()), headers: headers), 'updatePatient');

  Future<void> deletePatient(int id) async => 
      await _safeRequest(() => http.delete(Uri.parse('$baseUrl/patients/$id'), headers: headers), 'deletePatient');

  // --- EMK ---
  Future<EMK?> getEMK(int patientId) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/emk/$patientId'), headers: headers), 'getEMK');
    if (res == null || res.statusCode != 200) return null;
    try {
      return EMK.fromMap(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getEMK parse error: $e');
    }
    return null;
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
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => Measurement(
        id: i['id'],
        patientId: i['patient_id'] ?? i['patientId'],
        pressureSystolic: (i['pressure_systolic'] ?? i['pressureSystolic'] as num).toDouble(),
        pressureDiastolic: (i['pressure_diastolic'] ?? i['pressureDiastolic'] as num).toDouble(),
        pulse: i['pulse'] ?? 0,
        painLevel: i['pain_level'] ?? i['painLevel'] ?? 0,
        timestamp: i['timestamp'] ?? ''
      )).toList();
    } catch (e) {
      debugPrint('getMeasurements parse error: $e');
    }
    return [];
  }

  Future<void> insertMeasurement(Measurement m) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/measurements'),
        body: jsonEncode({
          'patient_id': m.patientId, 
          'pressure_systolic': m.pressureSystolic,
          'pressure_diastolic': m.pressureDiastolic, 
          'pulse': m.pulse,
          'pain_level': m.painLevel, 
          'timestamp': m.timestamp
        }),
        headers: headers,
      ),
      'insertMeasurement',
    );
  }

  // --- MOOD & NOTES ---
  Future<List<MoodEntry>> getMoodEntries(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/mood/$id'), headers: headers), 'getMoodEntries');
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => MoodEntry(
        id: i['id'], 
        patientId: i['patient_id'] ?? i['patientId'] ?? 0, 
        score: i['score'] ?? 0,
        comment: i['comment'] ?? '', 
        timestamp: i['timestamp'] ?? '', 
        sentiment: i['sentiment']
      )).toList();
    } catch (e) {
      debugPrint('getMoodEntries error: $e');
    }
    return [];
  }

  Future<void> insertMoodEntry(MoodEntry m) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/mood'),
        body: jsonEncode({
          'patient_id': m.patientId, 
          'score': m.score, 
          'comment': m.comment,
          'timestamp': m.timestamp, 
          'sentiment': m.sentiment
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
    if (res == null || res.statusCode != 200) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getNotes parse error: $e');
    }
    return [];
  }

  Future<void> insertNote(int patientId, String author, String content) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/notes'),
        body: jsonEncode({
          'patient_id': patientId, 
          'author': author, 
          'content': content,
          'timestamp': DateTime.now().toUtc().add(const Duration(hours: 3)).toIso8601String()
        }),
        headers: headers,
      ),
      'insertNote',
    );
  }

  // --- APPOINTMENTS & SCHEDULE ---
  Future<List<Appointment>> getAppointments(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/appointments/$id'), headers: headers), 'getAppointments');
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => Appointment(
        id: i['id'], 
        patientId: i['patient_id'] ?? i['patientId'] ?? 0, 
        type: i['type'] ?? '',
        title: i['title'] ?? '', 
        time: i['time'] ?? '', 
        room: i['room'] ?? '',
        doctor: i['doctor'] ?? '', 
        status: i['status'] ?? 'pending'
      )).toList();
    } catch (e) {
      debugPrint('getAppointments error: $e');
    }
    return [];
  }

  Future<void> insertAppointment(Appointment a) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/appointments'),
        body: jsonEncode({
          'patient_id': a.patientId, 
          'type': a.type, 
          'title': a.title,
          'time': a.time, 
          'room': a.room, 
          'doctor': a.doctor, 
          'status': a.status
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
    if (res == null || res.statusCode != 200) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getDoctorSchedule error: $e');
    }
    return [];
  }

  // --- QUESTIONNAIRES & HOSPITALIZATIONS ---
  Future<List<QuestionnaireResult>> getQuestionnaireResults(int id) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/questionnaires/$id'), headers: headers), 'getQuestionnaires');
    if (res == null || res.statusCode != 200) return [];
    try {
      final List d = jsonDecode(res.body);
      return d.map((i) => QuestionnaireResult(
        id: i['id'], 
        patientId: i['patient_id'] ?? i['patientId'] ?? 0, 
        title: i['title'] ?? '',
        totalScore: i['total_score'] ?? i['totalScore'] ?? 0, 
        date: i['date'] ?? ''
      )).toList();
    } catch (e) {
      debugPrint('getQuestionnaireResults error: $e');
    }
    return [];
  }

  Future<void> insertQuestionnaireResult(QuestionnaireResult q) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/questionnaires'),
        body: jsonEncode({
          'patient_id': q.patientId, 
          'title': q.title,
          'total_score': q.totalScore, 
          'date': q.date
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
    if (res == null || res.statusCode != 200) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getHospitalizations error: $e');
    }
    return [];
  }

  Future<void> insertHospitalization(int pId, String a, String d, String r, String dep) async {
    await _safeRequest(
      () => http.post(
        Uri.parse('$baseUrl/hospitalizations'),
        body: jsonEncode({
          'patient_id': pId, 
          'admission_date': a, 
          'discharge_date': d,
          'reason': r, 
          'department': dep
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
          'patient_id': patientId, 
          'doctor_id': doctorId, 
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: headers,
      ),
      'sendReminder',
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadReminders(int patientId) async {
    final res = await _safeRequest(() => http.get(Uri.parse('$baseUrl/reminders/unread/$patientId'), headers: headers), 'getReminders');
    if (res == null || res.statusCode != 200) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('getUnreadReminders parse error: $e');
    }
    return [];
  }

  Future<void> markReminderAsRead(int id) async => 
      await _safeRequest(() => http.put(Uri.parse('$baseUrl/reminders/read/$id'), headers: headers), 'markReminderRead');
}
