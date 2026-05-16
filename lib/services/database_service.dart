import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/user.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/doctor.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  // --- USERS ---
  Future<User?> loginUser(String login, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: jsonEncode({'login': login, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return User(
          id: d['id'],
          login: d['login'],
          password: d['password'],
          role: UserRole.values.firstWhere((e) => e.name == d['role']),
          patientId: d['patient_id'],
          doctorId: d['doctor_id'],
        );
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('loginUser error: $e');
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/users'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((u) => User(
          id: u['id'],
          login: u['login'],
          password: u['password'],
          role: UserRole.values.firstWhere((e) => e.name == u['role']),
          patientId: u['patient_id'],
          doctorId: u['doctor_id']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getAllUsers error: $e');
    }
    return [];
  }

  Future<void> registerUser(User user) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/register'),
        body: jsonEncode({
          'login': user.login,
          'password': user.password,
          'role': user.role.name,
          'patient_id': user.patientId,
          'doctor_id': user.doctorId
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('registerUser error: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/users'),
        body: jsonEncode({
          'id': user.id,
          'login': user.login,
          'password': user.password,
          'role': user.role.name,
          'patient_id': user.patientId,
          'doctor_id': user.doctorId
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('updateUser error: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/users/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deleteUser error: $e');
    }
  }

  // --- DOCTORS ---
  Future<List<Doctor>> getDoctors() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/doctors'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((i) => Doctor(
          id: i['id'],
          name: i['name'],
          specialization: i['specialization'],
          phone: i['phone'],
          cabinet: i['cabinet']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getDoctors error: $e');
    }
    return [];
  }

  Future<Doctor?> getDoctorById(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/doctors/$id'));
      if (res.statusCode == 200) {
        final i = jsonDecode(res.body);
        return Doctor(
          id: i['id'],
          name: i['name'],
          specialization: i['specialization'],
          phone: i['phone'],
          cabinet: i['cabinet']
        );
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getDoctorById error: $e');
    }
    return null;
  }

  Future<int> insertDoctor(Doctor doctor) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/doctors'),
        body: jsonEncode({
          'name': doctor.name,
          'specialization': doctor.specialization,
          'phone': doctor.phone,
          'cabinet': doctor.cabinet
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) return jsonDecode(res.body)['id'];
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertDoctor error: $e');
    }
    return 0;
  }

  Future<void> updateDoctor(Doctor d) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/doctors'),
        body: jsonEncode({
          'id': d.id,
          'name': d.name,
          'specialization': d.specialization,
          'phone': d.phone,
          'cabinet': d.cabinet
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('updateDoctor error: $e');
    }
  }

  Future<void> deleteDoctor(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/doctors/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deleteDoctor error: $e');
    }
  }

  // --- PATIENTS ---
  Future<List<Patient>> getPatients() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((i) => Patient(
          id: i['id'],
          name: i['name'],
          birthDate: i['birthDate'],
          photoPath: i['photoPath'],
          relativeContact: i['relativeContact'],
          doctorId: i['doctorId']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getPatients error: $e');
    }
    return [];
  }

  Future<Patient?> getPatientById(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patients/$id'));
      if (res.statusCode == 200) {
        final i = jsonDecode(res.body);
        return Patient(
          id: i['id'],
          name: i['name'],
          birthDate: i['birthDate'],
          photoPath: i['photoPath'],
          relativeContact: i['relativeContact'],
          doctorId: i['doctorId']
        );
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getPatientById error: $e');
    }
    return null;
  }

  Future<int> insertPatient(Patient p) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patients'),
        body: jsonEncode({
          'name': p.name,
          'birthDate': p.birthDate,
          'photoPath': p.photoPath,
          'relativeContact': p.relativeContact,
          'doctorId': p.doctorId
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) return jsonDecode(res.body)['id'];
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertPatient error: $e');
    }
    return 0;
  }

  Future<void> updatePatient(Patient p) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/patients'),
        body: jsonEncode({
          'id': p.id,
          'name': p.name,
          'birthDate': p.birthDate,
          'photoPath': p.photoPath,
          'relativeContact': p.relativeContact,
          'doctorId': p.doctorId
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('updatePatient error: $e');
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/patients/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deletePatient error: $e');
    }
  }

  // --- OTHERS ---
  Future<List<Measurement>> getMeasurements(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/measurements/$id'));
      if (res.statusCode == 200) {
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
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getMeasurements error: $e');
    }
    return [];
  }

  Future<void> insertMeasurement(Measurement m) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/measurements'),
        body: jsonEncode({
          'patientId': m.patientId,
          'pressureSystolic': m.pressureSystolic,
          'pressureDiastolic': m.pressureDiastolic,
          'pulse': m.pulse,
          'painLevel': m.painLevel,
          'timestamp': m.timestamp
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertMeasurement error: $e');
    }
  }

  Future<List<MoodEntry>> getMoodEntries(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/mood/$id'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((i) => MoodEntry(
          id: i['id'],
          patientId: i['patientId'],
          score: i['score'],
          comment: i['comment'],
          timestamp: i['timestamp'],
          sentiment: i['sentiment']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getMoodEntries error: $e');
    }
    return [];
  }

  Future<void> insertMoodEntry(MoodEntry m) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/mood'),
        body: jsonEncode({
          'patientId': m.patientId,
          'score': m.score,
          'comment': m.comment,
          'timestamp': m.timestamp,
          'sentiment': m.sentiment
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertMoodEntry error: $e');
    }
  }

  Future<void> deleteMoodEntry(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/mood/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deleteMoodEntry error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotes(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/notes/$id'));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getNotes error: $e');
    }
    return [];
  }

  Future<void> insertNote(int patientId, String author, String content) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/notes'),
        body: jsonEncode({
          'patientId': patientId,
          'author': author,
          'content': content,
          'timestamp': DateTime.now().toUtc().add(const Duration(hours: 3)).toString()
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertNote error: $e');
    }
  }

  Future<List<Appointment>> getAppointments(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/appointments/$id'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((i) => Appointment(
          id: i['id'],
          patientId: i['patientId'],
          type: i['type'],
          title: i['title'],
          time: i['time'],
          room: i['room'],
          doctor: i['doctor'],
          status: i['status']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getAppointments error: $e');
    }
    return [];
  }

  Future<void> insertAppointment(Appointment a) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/appointments'),
        body: jsonEncode({
          'patientId': a.patientId,
          'type': a.type,
          'title': a.title,
          'time': a.time,
          'room': a.room,
          'doctor': a.doctor,
          'status': a.status
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertAppointment error: $e');
    }
  }

  Future<void> deleteAppointment(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/appointments/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deleteAppointment error: $e');
    }
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/appointments/status'),
        body: jsonEncode({'id': id, 'status': status}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('updateAppointmentStatus error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorSchedule(String doctorName) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/schedule/${Uri.encodeComponent(doctorName)}'));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getDoctorSchedule error: $e');
    }
    return [];
  }

  Future<List<QuestionnaireResult>> getQuestionnaireResults(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/questionnaires/$id'));
      if (res.statusCode == 200) {
        final List d = jsonDecode(res.body);
        return d.map((i) => QuestionnaireResult(
          id: i['id'],
          patientId: i['patientId'],
          title: i['title'],
          totalScore: i['totalScore'],
          date: i['date']
        )).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getQuestionnaireResults error: $e');
    }
    return [];
  }

  Future<void> insertQuestionnaireResult(QuestionnaireResult q) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/questionnaires'),
        body: jsonEncode({
          'patientId': q.patientId,
          'title': q.title,
          'totalScore': q.totalScore,
          'date': q.date
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertQuestionnaireResult error: $e');
    }
  }

  Future<void> deleteQuestionnaireResult(int id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/questionnaires/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('deleteQuestionnaireResult error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHospitalizations(int id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/hospitalizations/$id'));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getHospitalizations error: $e');
    }
    return [];
  }

  Future<void> insertHospitalization(int pId, String a, String d, String r, String dep) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/hospitalizations'),
        body: jsonEncode({
          'patientId': pId,
          'admission_date': a,
          'discharge_date': d,
          'reason': r,
          'department': dep
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('insertHospitalization error: $e');
    }
  }

  // --- REMINDERS ---
  Future<void> sendReminder(int patientId, int doctorId, String message) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/reminders'),
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // ignore: avoid_print
      debugPrint('sendReminder error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadReminders(int patientId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/reminders/unread/$patientId'));
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getUnreadReminders error: $e');
    }
    return [];
  }

  Future<void> markReminderAsRead(int id) async {
    try {
      await http.put(Uri.parse('$_baseUrl/reminders/read/$id'));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('markReminderAsRead error: $e');
    }
  }
}
