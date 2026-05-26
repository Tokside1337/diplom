import '../../core/database/database_service.dart';
import 'mood_model.dart';

class MoodRepository {
  final DatabaseService _db;
  MoodRepository(this._db);

  Future<List<MoodModel>> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM mood_entries WHERE patient_id = @id ORDER BY timestamp ASC',
      parameters: {'id': patientId},
    );
    return result.map((r) => MoodModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(MoodModel m) async {
    await _db.execute(
      'INSERT INTO mood_entries (patient_id, score, comment, timestamp, sentiment) VALUES (@pId, @s, @c, @ts, @sent)',
      parameters: {
        'pId': m.patientId,
        's': m.score,
        'c': m.comment,
        'ts': m.timestamp,
        'sent': m.sentiment,
      },
    );
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM mood_entries WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
