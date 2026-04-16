import 'package:postgres/postgres.dart';
import '../models/patient.dart';
import '../models/medical_models.dart';
import '../models/user.dart';

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
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );

      await _ensureTablesExist(conn);
      return conn;
    } catch (e) {
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
      CREATE TABLE IF NOT EXISTS diagnoses(
        id SERIAL PRIMARY KEY,
        patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
        description TEXT,
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
        patient_id INTEGER REFERENCES patients(id) ON DELETE SET NULL
      )
    ''');
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

  // Users
  Future<void> registerUser(User user) async {
    final conn = await connection;
    await conn.execute(
      Sql.named('INSERT INTO users (login, password, role, patient_id) VALUES (@login, @password, @role, @patientId)'),
      parameters: {
        'login': user.login,
        'password': user.password,
        'role': user.role.name,
        'patientId': user.patientId,
      },
    );
  }

  Future<User?> loginUser(String login, String password) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named('SELECT id, login, password, role, patient_id FROM users WHERE login = @login AND password = @password'),
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
    );
  }
}
