import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const String _dbHost = 'localhost';
const int _dbPort = 5432;
const String _dbName = 'rehab_db';
const String _dbUser = 'postgres';
const String _dbPass = '12345';
const String _aiApiKey = 'AIzaSyDAz3E57uUFa1wGarxoBa0GMPAdP5bbq00';

late Connection conn;

void main() async {
  try {
    conn = await Connection.open(
      Endpoint(host: _dbHost, port: _dbPort, database: _dbName, username: _dbUser, password: _dbPass),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    stdout.writeln('Сервер подключен к PostgreSQL');
    await _setupDatabase();
  } catch (e) {
    stderr.writeln('Ошибка БД: $e');
    return;
  }

  final router = Router();

  // --- AI CHAT ---
  router.post('/ai/chat', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final message = body['message'] as String;
      final patientId = body['patientId'] as int;
      final isDoctor = body['isDoctor'] as bool? ?? false;

      String contextData = '';
      if (patientId > 0) {
        final pRes = await conn.execute(Sql.named('SELECT name, birth_date, diagnosis FROM patients WHERE id = @id'), parameters: {'id': patientId});
        if (pRes.isNotEmpty) {
          final p = pRes.first;
          final mRes = await conn.execute(Sql.named('SELECT pressure_systolic, pressure_diastolic FROM measurements WHERE patient_id = @id ORDER BY timestamp DESC LIMIT 5'), parameters: {'id': patientId});
          final moodRes = await conn.execute(Sql.named('SELECT comment FROM mood_entries WHERE patient_id = @id ORDER BY timestamp DESC LIMIT 3'), parameters: {'id': patientId});

          contextData = 'Контекст пациента:\n'
              'Имя: ${p[0]}\n'
              'Диагноз: ${p[2] ?? "Не указан"}\n'
              'Последние замеры давления: ${mRes.map((m) => "${_toDouble(m[0]) ?? 0.0}/${_toDouble(m[1]) ?? 0.0}").join(", ")}\n'
              'Последние записи настроения: ${moodRes.map((m) => m[0]).join("; ")}\n';
        }
      }

      final systemPrompt = isDoctor ? _doctorPrompt : _patientPrompt;
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _aiApiKey,
        systemInstruction: Content.system(systemPrompt),
      );

      final prompt = contextData.isNotEmpty ? '$contextData\n\nЗапрос: $message' : message;
      final response = await model.generateContent([Content.text(prompt)]);
      
      return Response.ok(jsonEncode({'text': response.text ?? 'Не удалось получить ответ.'}));
    } catch (e) {
      stderr.writeln('AI Chat Error: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // --- USERS ---
  router.post('/login', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final res = await conn.execute(
      Sql.named('SELECT id, login, password, role, patient_id, doctor_id FROM users WHERE login = @l AND password = @p'),
      parameters: {'l': body['login'], 'p': body['password']},
    );
    if (res.isEmpty) return Response.forbidden('Invalid credentials');
    final r = res.first;
    return Response.ok(jsonEncode({'id': r[0], 'login': r[1], 'password': r[2], 'role': r[3], 'patient_id': r[4], 'doctor_id': r[5]}));
  });

  router.get('/users', (Request req) async {
    final res = await conn.execute('SELECT id, login, password, role, patient_id, doctor_id FROM users ORDER BY id');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'login': r[1], 'password': r[2], 'role': r[3], 'patient_id': r[4], 'doctor_id': r[5]}).toList()));
  });

  router.post('/register', (Request req) async {
    final u = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('INSERT INTO users (login, password, role, patient_id, doctor_id) VALUES (@l, @p, @r, @pId, @dId)'),
      parameters: {
        'l': u['login'], 
        'p': u['password'], 
        'r': u['role'], 
        'pId': (u['patient_id'] == 0) ? null : u['patient_id'], 
        'dId': (u['doctor_id'] == 0) ? null : u['doctor_id']
      },
    );
    return Response.ok('Registered');
  });

  router.put('/users', (Request req) async {
    final u = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('UPDATE users SET login=@l, password=@p, role=@r, patient_id=@pId, doctor_id=@dId WHERE id=@id'),
      parameters: {
        'id': u['id'], 
        'l': u['login'], 
        'p': u['password'], 
        'r': u['role'], 
        'pId': (u['patient_id'] == 0) ? null : u['patient_id'], 
        'dId': (u['doctor_id'] == 0) ? null : u['doctor_id']
      },
    );
    return Response.ok('Updated');
  });

  router.delete('/users/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  // --- DOCTORS ---
  router.get('/doctors', (Request req) async {
    final res = await conn.execute('SELECT id, name, specialization, phone, cabinet FROM doctors ORDER BY id');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'name': r[1], 'specialization': r[2], 'phone': r[3], 'cabinet': r[4]}).toList()));
  });

  router.get('/doctors/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, name, specialization, phone, cabinet FROM doctors WHERE id = @id'), parameters: {'id': int.parse(id)});
    if (res.isEmpty) return Response.notFound('Not found');
    final r = res.first;
    return Response.ok(jsonEncode({'id': r[0], 'name': r[1], 'specialization': r[2], 'phone': r[3], 'cabinet': r[4]}));
  });

  router.post('/doctors', (Request req) async {
    final d = jsonDecode(await req.readAsString());
    final res = await conn.execute(
      Sql.named('INSERT INTO doctors (name, specialization, phone, cabinet) VALUES (@n, @s, @p, @c) RETURNING id'),
      parameters: {'n': d['name'], 's': d['specialization'], 'p': d['phone'], 'c': d['cabinet']},
    );
    return Response.ok(jsonEncode({'id': res.first[0]}));
  });

  router.put('/doctors', (Request req) async {
    final d = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('UPDATE doctors SET name=@n, specialization=@s, phone=@p, cabinet=@c WHERE id=@id'),
      parameters: {'id': d['id'], 'n': d['name'], 's': d['specialization'], 'p': d['phone'], 'c': d['cabinet']},
    );
    return Response.ok('Updated');
  });

  router.delete('/doctors/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM doctors WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  // --- PATIENTS ---
  router.get('/patients', (Request req) async {
    final res = await conn.execute('SELECT id, name, birth_date, gender, snils, passport_data, phone, relative_contact, representative_data, photo_path, skk_number, skk_date, issued_by_lpu, main_diagnosis_mkb, secondary_diagnoses_mkb, checkin_examination, health_group, diet_table, forbidden_procedures, mobility_regime, arrival_purpose, funding_source, sanatorium_profile, planned_arrival, planned_departure, actual_arrival, actual_departure, room_number, building, floor, doctor_id, bed_days_count, room_category, diet_type, special_needs, lfk_group, cultural_participation, voucher_type, extra_services, companion_data, status, treatment_efficiency, treatment_duration_category, benefit_category, egisz_id, fss_referral_id, is_egisz_activated, diagnosis, contraindications, treatment_goals, dynamics, final_recommendations FROM patients ORDER BY id');
    return Response.ok(jsonEncode(res.map((r) => {
      'id': r[0], 'name': r[1], 'birth_date': r[2], 'gender': r[3], 'snils': r[4], 'passport_data': r[5], 'phone': r[6], 'relative_contact': r[7], 'representative_data': r[8], 'photo_path': r[9], 
      'skk_number': r[10], 'skk_date': r[11], 'issued_by_lpu': r[12], 'main_diagnosis_mkb': r[13], 'secondary_diagnoses_mkb': r[14], 'checkin_examination': r[15], 'health_group': r[16], 'diet_table': r[17], 'forbidden_procedures': r[18], 'mobility_regime': r[19], 
      'arrival_purpose': r[20], 'funding_source': r[21], 'sanatorium_profile': r[22], 'planned_arrival': r[23], 'planned_departure': r[24], 'actual_arrival': r[25], 'actual_departure': r[26], 'room_number': r[27], 'building': r[28], 'floor': r[29], 
      'doctor_id': r[30], 'bed_days_count': r[31], 'room_category': r[32], 'diet_type': r[33], 'special_needs': r[34], 'lfk_group': r[35], 'cultural_participation': r[36], 'voucher_type': r[37], 'extra_services': r[38], 'companion_data': r[39], 
      'status': r[40], 'treatment_efficiency': r[41], 'treatment_duration_category': r[42], 'benefit_category': r[43], 'egisz_id': r[44], 'fss_referral_id': r[45], 'is_egisz_activated': r[46], 
      'diagnosis': r[47], 'contraindications': r[48], 'treatment_goals': r[49], 'dynamics': r[50], 'final_recommendations': r[51]
    }).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.get('/patients/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, name, birth_date, gender, snils, passport_data, phone, relative_contact, representative_data, photo_path, skk_number, skk_date, issued_by_lpu, main_diagnosis_mkb, secondary_diagnoses_mkb, checkin_examination, health_group, diet_table, forbidden_procedures, mobility_regime, arrival_purpose, funding_source, sanatorium_profile, planned_arrival, planned_departure, actual_arrival, actual_departure, room_number, building, floor, doctor_id, bed_days_count, room_category, diet_type, special_needs, lfk_group, cultural_participation, voucher_type, extra_services, companion_data, status, treatment_efficiency, treatment_duration_category, benefit_category, egisz_id, fss_referral_id, is_egisz_activated, diagnosis, contraindications, treatment_goals, dynamics, final_recommendations FROM patients WHERE id = @id'), parameters: {'id': int.parse(id)});
    if (res.isEmpty) return Response.notFound('Not found');
    final r = res.first;
    return Response.ok(jsonEncode({
      'id': r[0], 'name': r[1], 'birth_date': r[2], 'gender': r[3], 'snils': r[4], 'passport_data': r[5], 'phone': r[6], 'relative_contact': r[7], 'representative_data': r[8], 'photo_path': r[9], 
      'skk_number': r[10], 'skk_date': r[11], 'issued_by_lpu': r[12], 'main_diagnosis_mkb': r[13], 'secondary_diagnoses_mkb': r[14], 'checkin_examination': r[15], 'health_group': r[16], 'diet_table': r[17], 'forbidden_procedures': r[18], 'mobility_regime': r[19], 
      'arrival_purpose': r[20], 'funding_source': r[21], 'sanatorium_profile': r[22], 'planned_arrival': r[23], 'planned_departure': r[24], 'actual_arrival': r[25], 'actual_departure': r[26], 'room_number': r[27], 'building': r[28], 'floor': r[29], 
      'doctor_id': r[30], 'bed_days_count': r[31], 'room_category': r[32], 'diet_type': r[33], 'special_needs': r[34], 'lfk_group': r[35], 'cultural_participation': r[36], 'voucher_type': r[37], 'extra_services': r[38], 'companion_data': r[39], 
      'status': r[40], 'treatment_efficiency': r[41], 'treatment_duration_category': r[42], 'benefit_category': r[43], 'egisz_id': r[44], 'fss_referral_id': r[45], 'is_egisz_activated': r[46], 
      'diagnosis': r[47], 'contraindications': r[48], 'treatment_goals': r[49], 'dynamics': r[50], 'final_recommendations': r[51]
    }, toEncodable: _jsonEncodeDateTime));
  });

  router.post('/patients', (Request req) async {
    final Map<String, dynamic> p = jsonDecode(await req.readAsString());
    p.remove('id'); // Удаляем ID, так как он генерируется БД
    
    final res = await conn.execute(
      Sql.named('''INSERT INTO patients (name, birth_date, gender, snils, passport_data, phone, relative_contact, representative_data, photo_path, skk_number, skk_date, issued_by_lpu, main_diagnosis_mkb, secondary_diagnoses_mkb, checkin_examination, health_group, diet_table, forbidden_procedures, mobility_regime, arrival_purpose, funding_source, sanatorium_profile, planned_arrival, planned_departure, actual_arrival, actual_departure, room_number, building, floor, doctor_id, bed_days_count, room_category, diet_type, special_needs, lfk_group, cultural_participation, voucher_type, extra_services, companion_data, status, treatment_efficiency, treatment_duration_category, benefit_category, egisz_id, fss_referral_id, is_egisz_activated, diagnosis, contraindications, treatment_goals, dynamics, final_recommendations) 
      VALUES (@name, @birth_date, @gender, @snils, @passport_data, @phone, @relative_contact, @representative_data, @photo_path, @skk_number, @skk_date, @issued_by_lpu, @main_diagnosis_mkb, @secondary_diagnoses_mkb, @checkin_examination, @health_group, @diet_table, @forbidden_procedures, @mobility_regime, @arrival_purpose, @funding_source, @sanatorium_profile, @planned_arrival, @planned_departure, @actual_arrival, @actual_departure, @room_number, @building, @floor, @doctor_id, @bed_days_count, @room_category, @diet_type, @special_needs, @lfk_group, @cultural_participation, @voucher_type, @extra_services, @companion_data, @status, @treatment_efficiency, @treatment_duration_category, @benefit_category, @egisz_id, @fss_referral_id, @is_egisz_activated, @diagnosis, @contraindications, @treatment_goals, @dynamics, @final_recommendations) RETURNING id'''),
      parameters: p,
    );
    return Response.ok(jsonEncode({'id': res.first[0]}));
  });

  router.put('/patients', (Request req) async {
    final Map<String, dynamic> p = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('''UPDATE patients SET name=@name, birth_date=@birth_date, gender=@gender, snils=@snils, passport_data=@passport_data, phone=@phone, relative_contact=@relative_contact, representative_data=@representative_data, photo_path=@photo_path, skk_number=@skk_number, skk_date=@skk_date, issued_by_lpu=@issued_by_lpu, main_diagnosis_mkb=@main_diagnosis_mkb, secondary_diagnoses_mkb=@secondary_diagnoses_mkb, checkin_examination=@checkin_examination, health_group=@health_group, diet_table=@diet_table, forbidden_procedures=@forbidden_procedures, mobility_regime=@mobility_regime, arrival_purpose=@arrival_purpose, funding_source=@funding_source, sanatorium_profile=@sanatorium_profile, planned_arrival=@planned_arrival, planned_departure=@planned_departure, actual_arrival=@actual_arrival, actual_departure=@actual_departure, room_number=@room_number, building=@building, floor=@floor, doctor_id=@doctor_id, bed_days_count=@bed_days_count, room_category=@room_category, diet_type=@diet_type, special_needs=@special_needs, lfk_group=@lfk_group, cultural_participation=@cultural_participation, voucher_type=@voucher_type, extra_services=@extra_services, companion_data=@companion_data, status=@status, treatment_efficiency=@treatment_efficiency, treatment_duration_category=@treatment_duration_category, benefit_category=@benefit_category, egisz_id=@egisz_id, fss_referral_id=@fss_referral_id, is_egisz_activated=@is_egisz_activated, diagnosis=@diagnosis, contraindications=@contraindications, treatment_goals=@treatment_goals, dynamics=@dynamics, final_recommendations=@final_recommendations WHERE id=@id'''),
      parameters: p,
    );
    return Response.ok('Updated');
  });

  router.delete('/patients/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM patients WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  // --- MEASUREMENTS ---
  router.get('/measurements/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, timestamp FROM measurements WHERE patient_id = @id ORDER BY timestamp ASC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {
      'id': r[0],
      'patientId': r[1],
      'pressureSystolic': _toDouble(r[2]),
      'pressureDiastolic': _toDouble(r[3]),
      'pulse': _toInt(r[4]),
      'painLevel': _toInt(r[5]),
      'timestamp': r[6]
    }).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/measurements', (Request req) async {
    final m = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO measurements (patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, timestamp) VALUES (@pId, @sys, @dia, @p, @pl, @ts)'), 
      parameters: {'pId': m['patientId'], 'sys': m['pressureSystolic'], 'dia': m['pressureDiastolic'], 'p': m['pulse'], 'pl': m['painLevel'], 'ts': m['timestamp']});
    return Response.ok('Saved');
  });

  router.get('/mood/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, patient_id, score, comment, timestamp, sentiment FROM mood_entries WHERE patient_id = @id ORDER BY timestamp ASC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'patientId': r[1], 'score': r[2], 'comment': r[3], 'timestamp': r[4], 'sentiment': r[5]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/mood', (Request req) async {
    final m = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO mood_entries (patient_id, score, comment, timestamp, sentiment) VALUES (@pId, @s, @c, @ts, @sent)'),
      parameters: {'pId': m['patientId'], 's': m['score'], 'c': m['comment'], 'ts': m['timestamp'], 'sent': m['sentiment']});
    return Response.ok('Saved');
  });

  router.get('/notes/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT author, content, timestamp FROM medical_notes WHERE patient_id = @id ORDER BY timestamp DESC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {'author': r[0], 'content': r[1], 'timestamp': r[2]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/notes', (Request req) async {
    final n = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO medical_notes (patient_id, author, content, timestamp) VALUES (@pId, @a, @c, @ts)'),
      parameters: {'pId': n['patientId'], 'a': n['author'], 'c': n['content'], 'ts': n['timestamp']});
    return Response.ok('Saved');
  });

  router.get('/appointments/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, patient_id, type, title, time, room, doctor, status FROM appointments WHERE patient_id = @id ORDER BY time ASC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'patientId': r[1], 'type': r[2], 'title': r[3], 'time': r[4], 'room': r[5], 'doctor': r[6], 'status': r[7]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/appointments', (Request req) async {
    final a = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO appointments (patient_id, type, title, time, room, doctor, status) VALUES (@pId, @ty, @tl, @tm, @r, @d, @s)'),
      parameters: {'pId': a['patientId'], 'ty': a['type'], 'tl': a['title'], 'tm': a['time'], 'r': a['room'], 'd': a['doctor'], 's': a['status']});
    return Response.ok('Saved');
  });

  router.delete('/appointments/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM appointments WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  router.put('/appointments/status', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('UPDATE appointments SET status = @s WHERE id = @id'),
      parameters: {'s': body['status'], 'id': body['id']},
    );
    return Response.ok('Updated');
  });

  router.get('/schedule/<name>', (Request req, String name) async {
    final doctorName = Uri.decodeComponent(name);
    final res = await conn.execute(
      Sql.named('''
        SELECT a.id, a.type, a.title, a.time, a.room, p.name as patient_name, a.status 
        FROM appointments a 
        JOIN patients p ON a.patient_id = p.id 
        WHERE TRIM(a.doctor) ILIKE TRIM(@doctorName) 
        ORDER BY a.time ASC
      '''),
      parameters: {'doctorName': doctorName},
    );
    return Response.ok(jsonEncode(res.map((r) => {
      'id': r[0], 'type': r[1], 'title': r[2], 'time': r[3], 'room': r[4], 'patient_name': r[5], 'status': r[6]
    }).toList(), toEncodable: _jsonEncodeDateTime));
  });

  // --- REMINDERS ---
  router.post('/reminders', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('INSERT INTO reminders (patient_id, doctor_id, message, timestamp) VALUES (@pId, @dId, @m, @ts)'),
      parameters: {'pId': body['patientId'], 'dId': body['doctorId'], 'm': body['message'], 'ts': body['timestamp']},
    );
    return Response.ok('Sent');
  });

  router.get('/reminders/unread/<id>', (Request req, String id) async {
    final res = await conn.execute(
      Sql.named('SELECT id, doctor_id, message, timestamp FROM reminders WHERE patient_id = @id AND is_read = FALSE'),
      parameters: {'id': int.parse(id)},
    );
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'doctor_id': r[1], 'message': r[2], 'timestamp': r[3]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.put('/reminders/read/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('UPDATE reminders SET is_read = TRUE WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Read');
  });

  // --- EMK ---
  router.get('/emk/<patientId>', (Request req, String patientId) async {
    final res = await conn.execute(
      Sql.named('SELECT id, patient_id, status, diagnoses, contraindications, treatment_goals, daily_logs, stage_reviews, final_recommendations, created_at, updated_at FROM emk WHERE patient_id = @pId'),
      parameters: {'pId': int.parse(patientId)},
    );
    if (res.isEmpty) return Response.notFound('Not found');
    final r = res.first;
    return Response.ok(jsonEncode({
      'id': r[0], 'patient_id': r[1], 'status': r[2], 'diagnoses': r[3], 'contraindications': r[4], 
      'treatment_goals': r[5], 'daily_logs': r[6], 'stage_reviews': r[7], 'final_recommendations': r[8],
      'created_at': r[9], 'updated_at': r[10]
    }));
  });

  router.post('/emk', (Request req) async {
    final e = jsonDecode(await req.readAsString());
    final res = await conn.execute(
      Sql.named('''
        INSERT INTO emk (patient_id, status, diagnoses, contraindications, treatment_goals, daily_logs, stage_reviews, final_recommendations, created_at, updated_at) 
        VALUES (@pId, @s, @diag, @cont, @goals, @logs, @steps, @final, @cAt, @uAt) RETURNING id
      '''),
      parameters: {
        'pId': e['patient_id'], 's': e['status'], 'diag': e['diagnoses'], 'cont': e['contraindications'], 
        'goals': e['treatment_goals'], 'logs': e['daily_logs'], 'steps': e['stage_reviews'], 
        'final': e['final_recommendations'], 'cAt': e['created_at'], 'uAt': e['updated_at']
      },
    );
    return Response.ok(jsonEncode({'id': res.first[0]}));
  });

  router.put('/emk', (Request req) async {
    final e = jsonDecode(await req.readAsString());
    await conn.execute(
      Sql.named('''
        UPDATE emk SET status=@s, diagnoses=@diag, contraindications=@cont, treatment_goals=@goals, 
        daily_logs=@logs, stage_reviews=@steps, final_recommendations=@final, updated_at=@uAt 
        WHERE patient_id=@pId
      '''),
      parameters: {
        'pId': e['patient_id'], 's': e['status'], 'diag': e['diagnoses'], 'cont': e['contraindications'], 
        'goals': e['treatment_goals'], 'logs': e['daily_logs'], 'steps': e['stage_reviews'], 
        'final': e['final_recommendations'], 'uAt': e['updated_at']
      },
    );
    return Response.ok('Updated');
  });

  // --- DELETE METHODS ---
  router.delete('/mood/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM mood_entries WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  router.delete('/questionnaires/<id>', (Request req, String id) async {
    await conn.execute(Sql.named('DELETE FROM questionnaire_results WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok('Deleted');
  });

  router.get('/questionnaires/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT id, patient_id, title, total_score, date FROM questionnaire_results WHERE patient_id = @id ORDER BY date DESC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'patientId': r[1], 'title': r[2], 'totalScore': r[3], 'date': r[4]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/questionnaires', (Request req) async {
    final q = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO questionnaire_results (patient_id, title, total_score, date) VALUES (@pId, @t, @s, @d)'),
      parameters: {'pId': q['patientId'], 't': q['title'], 's': q['totalScore'], 'd': q['date']});
    return Response.ok('Saved');
  });

  router.get('/hospitalizations/<id>', (Request req, String id) async {
    final res = await conn.execute(Sql.named('SELECT admission_date, discharge_date, reason, department FROM hospitalizations WHERE patient_id = @id ORDER BY admission_date DESC'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode(res.map((r) => {'admission_date': r[0], 'discharge_date': r[1], 'reason': r[2], 'department': r[3]}).toList(), toEncodable: _jsonEncodeDateTime));
  });

  router.post('/hospitalizations', (Request req) async {
    final h = jsonDecode(await req.readAsString());
    await conn.execute(Sql.named('INSERT INTO hospitalizations (patient_id, admission_date, discharge_date, reason, department) VALUES (@pId, @a, @d, @r, @dep)'),
      parameters: {'pId': h['patientId'], 'a': h['admission_date'], 'd': h['discharge_date'], 'r': h['reason'], 'dep': h['department']});
    return Response.ok('Saved');
  });

  final handler = Pipeline().addMiddleware(logRequests()).addMiddleware(_corsMiddleware).addHandler(router.call);
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  stdout.writeln('API сервер запущен на: http://${server.address.address}:${server.port}');
}

/// Вспомогательная функция для сериализации DateTime в JSON
Object? _jsonEncodeDateTime(Object? item) {
  if (item is DateTime) return item.toIso8601String();
  return item;
}

/// Безопасное преобразование в double
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Безопасное преобразование в int
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

Future<void> _setupDatabase() async {
  // Ensure UUID extension for gen_random_uuid()
  await conn.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

  // 1. Doctors
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS doctors(
      id SERIAL PRIMARY KEY,
      name TEXT,
      specialization TEXT,
      phone TEXT,
      cabinet TEXT
    )
  ''');

  // 2. Patients (Full Sanatorium EMR version)
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS patients(
      id SERIAL PRIMARY KEY,
      name TEXT,
      birth_date TEXT,
      gender TEXT,
      snils TEXT,
      passport_data TEXT,
      phone TEXT,
      relative_contact TEXT,
      representative_data TEXT,
      photo_path TEXT,
      skk_number TEXT,
      skk_date TEXT,
      issued_by_lpu TEXT,
      main_diagnosis_mkb TEXT,
      secondary_diagnoses_mkb TEXT,
      checkin_examination TEXT,
      health_group TEXT,
      diet_table TEXT,
      forbidden_procedures TEXT,
      mobility_regime TEXT,
      arrival_purpose TEXT,
      funding_source TEXT,
      sanatorium_profile TEXT,
      planned_arrival TEXT,
      planned_departure TEXT,
      actual_arrival TEXT,
      actual_departure TEXT,
      room_number TEXT,
      building TEXT,
      floor TEXT,
      doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL,
      bed_days_count INTEGER DEFAULT 0,
      room_category TEXT,
      diet_type TEXT,
      special_needs TEXT,
      lfk_group TEXT,
      cultural_participation TEXT,
      voucher_type TEXT,
      extra_services TEXT,
      companion_data TEXT,
      status TEXT DEFAULT 'active',
      treatment_efficiency TEXT,
      treatment_duration_category TEXT,
      benefit_category TEXT,
      egisz_id TEXT,
      fss_referral_id TEXT,
      is_egisz_activated BOOLEAN DEFAULT FALSE,
      diagnosis TEXT,
      contraindications TEXT,
      treatment_goals TEXT,
      dynamics TEXT,
      final_recommendations TEXT
    )
  ''');

  // Automatic Migration for existing DB
  try {
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS gender TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS snils TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS passport_data TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS phone TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS representative_data TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS skk_number TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS skk_date TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS issued_by_lpu TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS main_diagnosis_mkb TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS secondary_diagnoses_mkb TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS checkin_examination TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS health_group TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS diet_table TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS forbidden_procedures TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS mobility_regime TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS arrival_purpose TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS funding_source TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS sanatorium_profile TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS planned_arrival TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS planned_departure TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS actual_arrival TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS actual_departure TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS room_number TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS building TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS floor TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS bed_days_count INTEGER DEFAULT 0");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS room_category TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS diet_type TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS special_needs TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS lfk_group TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS cultural_participation TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS voucher_type TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS extra_services TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS companion_data TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS treatment_efficiency TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS treatment_duration_category TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS benefit_category TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS egisz_id TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS fss_referral_id TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS is_egisz_activated BOOLEAN DEFAULT FALSE");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS contraindications TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS treatment_goals TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS dynamics TEXT");
    await conn.execute("ALTER TABLE patients ADD COLUMN IF NOT EXISTS final_recommendations TEXT");
  } catch (e) {
    stdout.writeln('Migration notice: $e');
  }

  // 3. Diagnoses
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS diagnoses(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      description TEXT,
      date TEXT
    )
  ''');

  // 4. Hospitalizations
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS hospitalizations(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      admission_date TEXT,
      discharge_date TEXT,
      reason TEXT,
      department TEXT
    )
  ''');

  // 5. Questionnaire results
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS questionnaire_results(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      title TEXT,
      total_score INTEGER,
      date TEXT
    )
  ''');

  // 6. Appointments
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS appointments(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      type TEXT,
      title TEXT,
      time TEXT,
      room TEXT,
      doctor TEXT,
      status TEXT DEFAULT 'pending'
    )
  ''');

  // 7. Measurements
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS measurements(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      pressure_systolic REAL,
      pressure_diastolic REAL,
      pulse INTEGER,
      pain_level INTEGER,
      timestamp TEXT
    )
  ''');

  // 8. Mood Entries
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS mood_entries(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      score INTEGER,
      comment TEXT,
      timestamp TEXT,
      sentiment TEXT
    )
  ''');

  // 9. Medical Notes
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS medical_notes(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      author TEXT,
      content TEXT,
      timestamp TEXT
    )
  ''');

  // 10. Users
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS users(
      id SERIAL PRIMARY KEY,
      login TEXT UNIQUE,
      password TEXT,
      role TEXT,
      patient_id INTEGER REFERENCES patients(id) ON DELETE SET NULL,
      doctor_id INTEGER REFERENCES doctors(id) ON DELETE SET NULL
    )
  ''');

  // 11. Reminders
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS reminders(
      id SERIAL PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      doctor_id INTEGER REFERENCES doctors(id) ON DELETE CASCADE,
      message TEXT,
      is_read BOOLEAN DEFAULT FALSE,
      timestamp TEXT
    )
  ''');

  // 12. EMK
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS emk(
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
      status TEXT DEFAULT 'active',
      diagnoses TEXT,
      contraindications TEXT,
      treatment_goals TEXT,
      daily_logs TEXT,
      stage_reviews TEXT,
      final_recommendations TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ''');

  // Default Admin User
  final adminCheck = await conn.execute(
    Sql.named('SELECT id FROM users WHERE login = @login'),
    parameters: {'login': 'admin'},
  );

  if (adminCheck.isEmpty) {
    await conn.execute(
      Sql.named('INSERT INTO users (login, password, role) VALUES (@login, @password, @role)'),
      parameters: {
        'login': 'admin',
        'password': '1337', // Default admin password
        'role': 'admin',
      },
    );
    stdout.writeln('Создан пользователь admin по умолчанию');
  }
}

Middleware _corsMiddleware = (Handler innerHandler) {
  return (Request request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS', 'Access-Control-Allow-Headers': 'Origin, Content-Type'});
    }
    final response = await innerHandler(request);
    return response.change(headers: {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS', 'Access-Control-Allow-Headers': 'Origin, Content-Type'});
  };
};

const String _patientPrompt = '''
Вы — дружелюбный и поддерживающий ИИ-ассистент по реабилитации "РеСтарт". 
ВАША РОЛЬ: Помогать пациенту следить за здоровьем, мотивировать его и объяснять простыми словами медицинские показатели.
ВАША ЗАДАЧА: Отвечать на вопросы пациента, давать советы по образу жизни и режиму дня.
ОГРАНИЧЕНИЯ: 
1. НИКОГДА не назначайте лекарства и дозировки.
2. Не ставьте окончательные диагнозы. 
3. Если вопрос касается серьезных жалоб, всегда рекомендуйте обратиться к лечащему врачу.
4. Избегайте сложной медицинской терминологии.
ФОРМАТ: Дружелюбный, эмпатичный, короткие абзацы. Используйте эмодзи.
''';

const String _doctorPrompt = '''
Вы — высококвалифицированный медицинский ИИ-эксперт, ассистент врача в системе "РеСтарт".
ВАША РОЛЬ: Помощь в клиническом анализе данных пациента и предоставление справочной информации по протоколам реабилитации.
ВАША ЗАДАЧА: Анализировать тренды показателей, подсвечивать аномалии и предлагать возможные варианты коррекции терапии на основе доказательной медицины.
ОГРАНИЧЕНИЯ: 
1. Напоминайте, что окончательное решение принимает только врач.
2. Будьте объективны и точны.
ФОРМАТ: Профессиональный, лаконичный. Используйте списки (bullet points). Допускается использование медицинской терминологии.
''';
