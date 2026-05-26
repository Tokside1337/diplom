import '../../core/database/database_service.dart';
import 'note_model.dart';

class NoteRepository {
  final DatabaseService _db;
  NoteRepository(this._db);

  Future<List<NoteModel>> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM medical_notes WHERE patient_id = @id ORDER BY timestamp DESC',
      parameters: {'id': patientId},
    );
    return result.map((r) => NoteModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(NoteModel n) async {
    await _db.execute(
      'INSERT INTO medical_notes (patient_id, author, content, timestamp) VALUES (@pId, @a, @c, @ts)',
      parameters: {
        'pId': n.patientId,
        'a': n.author,
        'c': n.content,
        'ts': n.timestamp,
      },
    );
  }
}
