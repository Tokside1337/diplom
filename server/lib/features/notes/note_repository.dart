import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'note_model.dart';

class NoteRepository {
  final DatabaseService _db;
  NoteRepository(this._db);

  Future<List<NoteModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('''
        SELECT n.*, d.name as doctor_name, n.created_at as timestamp 
        FROM medical_notes n
        LEFT JOIN doctors d ON n.author_id = d.id
        WHERE n.patient_id = @id 
        ORDER BY n.created_at DESC
      '''),
      parameters: {'id': patientId},
    );
    return result.map((r) {
      final map = r.toColumnMap();
      map['author'] = map['doctor_name'] ?? 'Система';
      return NoteModel.fromMap(map);
    }).toList();
  }

  Future<void> create(NoteModel n) async {
    await _db.pool.execute(
      Sql.named('''
        INSERT INTO medical_notes (patient_id, author_id, content, created_at) 
        VALUES (@pId, (SELECT id FROM doctors WHERE name = @a LIMIT 1), @c, CAST(@ts AS TIMESTAMPTZ))
      '''),
      parameters: {
        'pId': n.patientId,
        'a': n.author,
        'c': n.content,
        'ts': n.timestamp,
      },
    );
  }
}
