import 'package:postgres/postgres.dart';
import 'package:diplom/models/patient.dart';
import 'package:diplom/models/doctor.dart';
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;

  // Настройки подключения к PostgreSQL
  // ВНИМАНИЕ: Для Android эмулятора используйте '10.0.2.2' вместо 'localhost'
  final String _host = '10.0.2.2';
  final int _port = 5432;
  final String _databaseName = 'rehab_db';
  final String _username = 'postgres';
  final String _password = '1337';

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) return _connection!;
    _connection = await _initDatabase();
    return _connection!;
  }

  Future<Connection> _initDatabase() async {
    try {
      final conn = await Connection.open(
        Endpoint(
          host: _host,
          port: _port,
          database: _databaseName,
          username: _username,
          password: _password,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      await _ensureTablesExist(conn);
      return conn;
    } catch (e) {
      // ignore: avoid_print
      print('Ошибка подключения к PostgreSQL: \$e');
      rethrow;
    }
  }

  Future<void> _ensureTablesExist(Connection conn) async {
    // 1. Модуль пациентов
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS patients(
        id SERIAL PRIMARY KEY,
        name TEXT,
        birth_date TEXT,
        photo_path TEXT,
        relative_contact TEXT
      )
    ''');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS doctors(
        id SERIAL PRIMARY KEY,
        name TEXT,
        specialization TEXT,
        phone TEXT,
        cabinet TEXT
      )
    ''');
    
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS diagnoses(
        id SERIAL PRIMARY KEY,
        patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
        description TEXT,
        date TEXT
      )
    ''');

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

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS questionnaire_results(
        id SERIAL PRIMARY KEY,
        patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
        title TEXT,
        total_score INTEGER,
        date TEXT
      )
    ''');

    // 2. Модуль медицинской реабилитации
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS appointments(
        id SERIAL PRIMARY KEY,
        patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
        type TEXT,
        title TEXT,
        time TEXT,
        room TEXT,
        doctor TEXT
      )
    ''');

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

    // 3. Модуль психологической реабилитации
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

    // 5. Модуль коммуникации
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS medical_notes(
        id SERIAL PRIMARY KEY,
        patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
        author TEXT,
        content TEXT,
        timestamp TEXT
      )
    ''');

    // 6. Пользователи
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

    // Проверка наличия администратора по умолчанию
    final adminCheck = await conn.execute(
      Sql.named('SELECT id FROM users WHERE login = @login'),
      parameters: {'login': 'admin'},
    );

    if (adminCheck.isEmpty) {
      await conn.execute(
        Sql.named('INSERT INTO users (login, password, role) VALUES (@login, @password, @role)'),
        parameters: {
          'login': 'admin',
          'password': '1234', // В реальном приложении пароль должен быть захеширован
          'role': 'admin',
        },
      );
    }
  }

  // Doctor CRUD
  Future<int> insertDoctor(Doctor doctor) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('INSERT INTO doctors (name, specialization, phone, cabinet) VALUES (@name, @spec, @phone, @cabinet) RETURNING id'),
      parameters: {
        'name': doctor.name,
        'spec': doctor.specialization,
        'phone': doctor.phone,
        'cabinet': doctor.cabinet,
      },
    );
    return result.first[0] as int;
  }

  Future<List<Doctor>> getDoctors() async {
    final conn = await connection;
    final result = await conn.execute('SELECT id, name, specialization, phone, cabinet FROM doctors ORDER BY id');
    
    return result.map((row) => Doctor(
      id: row[0] as int,
      name: row[1] as String,
      specialization: row[2] as String,
      phone: row[3] as String?,
      cabinet: row[4] as String?,
    )).toList();
  }

  // Patient CRUD
  Future<int> insertPatient(Patient patient) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('INSERT INTO patients (name, birth_date, photo_path, relative_contact) VALUES (@name, @birth_date, @photo_path, @relative_contact) RETURNING id'),
      parameters: {
        'name': patient.name,
        'birth_date': patient.birthDate,
        'photo_path': patient.photoPath,
        'relative_contact': patient.relativeContact,
      },
    );
    return result.first[0] as int;
  }

  Future<List<Patient>> getPatients() async {
    final conn = await connection;
    final result = await conn.execute('SELECT id, name, birth_date, photo_path, relative_contact FROM patients ORDER BY id');
    
    return result.map((row) => Patient(
      id: row[0] as int,
      name: row[1] as String,
      birthDate: row[2] as String,
      photoPath: row[3] as String?,
      relativeContact: row[4] as String,
    )).toList();
  }

  Future<void> deletePatient(int id) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('DELETE FROM patients WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // Measurements
  Future<void> insertMeasurement(Measurement m) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO measurements (patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, timestamp) VALUES (@pId, @sys, @dia, @pulse, @pain, @ts)'),
      parameters: {
        'pId': m.patientId,
        'sys': m.pressureSystolic,
        'dia': m.pressureDiastolic,
        'pulse': m.pulse,
        'pain': m.painLevel,
        'ts': m.timestamp,
      },
    );
  }

  Future<List<Measurement>> getMeasurements(int patientId) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT id, patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, timestamp FROM measurements WHERE patient_id = @pId ORDER BY timestamp ASC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => Measurement(
      id: row[0] as int,
      patientId: row[1] as int,
      pressureSystolic: (row[2] as num).toDouble(),
      pressureDiastolic: (row[3] as num).toDouble(),
      pulse: row[4] as int,
      painLevel: row[5] as int,
      timestamp: row[6] as String,
    )).toList();
  }

  // Mood
  Future<void> insertMoodEntry(MoodEntry entry) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO mood_entries (patient_id, score, comment, timestamp, sentiment) VALUES (@pId, @score, @comment, @ts, @sentiment)'),
      parameters: {
        'pId': entry.patientId,
        'score': entry.score,
        'comment': entry.comment,
        'ts': entry.timestamp,
        'sentiment': entry.sentiment,
      },
    );
  }

  Future<List<MoodEntry>> getMoodEntries(int patientId) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT id, patient_id, score, comment, timestamp, sentiment FROM mood_entries WHERE patient_id = @pId ORDER BY timestamp ASC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => MoodEntry(
      id: row[0] as int,
      patientId: row[1] as int,
      score: row[2] as int,
      comment: row[3] as String,
      timestamp: row[4] as String,
      sentiment: row[5] as String?,
    )).toList();
  }

  // Notes
  Future<void> insertNote(int patientId, String author, String content) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO medical_notes (patient_id, author, content, timestamp) VALUES (@pId, @author, @content, @ts)'),
      parameters: {
        'pId': patientId,
        'author': author,
        'content': content,
        'ts': DateTime.now().toUtc().add(const Duration(hours: 3)).toString(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getNotes(int patientId) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT author, content, timestamp FROM medical_notes WHERE patient_id = @pId ORDER BY timestamp DESC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => {
      'author': row[0],
      'content': row[1],
      'timestamp': row[2],
    }).toList();
  }

  // Appointments
  Future<void> insertAppointment(Appointment app) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO appointments (patient_id, type, title, time, room, doctor) VALUES (@pId, @type, @title, @time, @room, @doctor)'),
      parameters: {
        'pId': app.patientId,
        'type': app.type,
        'title': app.title,
        'time': app.time,
        'room': app.room,
        'doctor': app.doctor,
      },
    );
  }

  Future<List<Appointment>> getAppointments(int patientId) async {
    final conn = await connection;
    // Удаляем прошедшие мероприятия перед получением списка
    final now = DateTime.now().toUtc().add(const Duration(hours: 3)).toString();
    await conn.execute(
      Sql.named('DELETE FROM appointments WHERE patient_id = @pId AND time < @now'),
      parameters: {'pId': patientId, 'now': now},
    );

    final result = await conn.execute(
      Sql.named('SELECT id, patient_id, type, title, time, room, doctor FROM appointments WHERE patient_id = @pId ORDER BY time ASC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => Appointment(
      id: row[0] as int,
      patientId: row[1] as int,
      type: row[2] as String,
      title: row[3] as String,
      time: row[4] as String,
      room: row[5] as String,
      doctor: row[6] as String,
    )).toList();
  }

  Future<void> deleteAppointment(int id) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('DELETE FROM appointments WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // Questionnaire Results
  Future<void> insertQuestionnaireResult(QuestionnaireResult res) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO questionnaire_results (patient_id, title, total_score, date) VALUES (@pId, @title, @score, @date)'),
      parameters: {
        'pId': res.patientId,
        'title': res.title,
        'score': res.totalScore,
        'date': res.date,
      },
    );
  }

  Future<List<QuestionnaireResult>> getQuestionnaireResults(int patientId) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT id, patient_id, title, total_score, date FROM questionnaire_results WHERE patient_id = @pId ORDER BY date DESC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => QuestionnaireResult(
      id: row[0] as int,
      patientId: row[1] as int,
      title: row[2] as String,
      totalScore: row[3] as int,
      date: row[4] as String,
    )).toList();
  }

  // Hospitalizations
  Future<void> insertHospitalization(int patientId, String admission, String discharge, String reason, String dept) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO hospitalizations (patient_id, admission_date, discharge_date, reason, department) VALUES (@pId, @adm, @dis, @reason, @dept)'),
      parameters: {
        'pId': patientId,
        'adm': admission,
        'dis': discharge,
        'reason': reason,
        'dept': dept,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getHospitalizations(int patientId) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT admission_date, discharge_date, reason, department FROM hospitalizations WHERE patient_id = @pId ORDER BY admission_date DESC'),
      parameters: {'pId': patientId},
    );
    return result.map((row) => {
      'admission_date': row[0],
      'discharge_date': row[1],
      'reason': row[2],
      'department': row[3],
    }).toList();
  }

  // Users
  Future<void> registerUser(User user) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO users (login, password, role, patient_id, doctor_id) VALUES (@login, @password, @role, @patientId, @doctorId)'),
      parameters: {
        'login': user.login,
        'password': user.password,
        'role': user.role.name,
        'patientId': user.patientId,
        'doctorId': user.doctorId,
      },
    );
  }

  Future<User?> loginUser(String login, String password) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT id, login, password, role, patient_id, doctor_id FROM users WHERE login = @login AND password = @password'),
      parameters: {
        'login': login,
        'password': password,
      },
    );

    if (result.isEmpty) return null;
    final row = result.first;
    return User(
      id: row[0] as int,
      login: row[1] as String,
      password: row[2] as String,
      role: UserRole.values.firstWhere((e) => e.name == row[3]),
      patientId: row[4] as int?,
      doctorId: row[5] as int?,
    );
  }

  Future<List<User>> getAllUsers() async {
    final conn = await connection;
    final result = await conn.execute('SELECT id, login, password, role, patient_id, doctor_id FROM users ORDER BY id');
    return result.map((row) => User(
      id: row[0] as int,
      login: row[1] as String,
      password: row[2] as String,
      role: UserRole.values.firstWhere((e) => e.name == row[3]),
      patientId: row[4] as int?,
      doctorId: row[5] as int?,
    )).toList();
  }

  Future<void> updateUser(User user) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('UPDATE users SET login = @login, password = @password, role = @role, patient_id = @pId, doctor_id = @dId WHERE id = @id'),
      parameters: {
        'login': user.login,
        'password': user.password,
        'role': user.role.name,
        'pId': user.patientId,
        'dId': user.doctorId,
        'id': user.id,
      },
    );
  }

  Future<void> deleteUser(int id) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> updateDoctor(Doctor doctor) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('UPDATE doctors SET name = @name, specialization = @spec, phone = @phone, cabinet = @cabinet WHERE id = @id'),
      parameters: {
        'name': doctor.name,
        'spec': doctor.specialization,
        'phone': doctor.phone,
        'cabinet': doctor.cabinet,
        'id': doctor.id,
      },
    );
  }

  Future<void> deleteDoctor(int id) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('DELETE FROM doctors WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> updatePatient(Patient patient) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('UPDATE patients SET name = @name, birth_date = @birth, photo_path = @photo, relative_contact = @contact WHERE id = @id'),
      parameters: {
        'name': patient.name,
        'birth': patient.birthDate,
        'photo': patient.photoPath,
        'contact': patient.relativeContact,
        'id': patient.id,
      },
    );
  }
}
