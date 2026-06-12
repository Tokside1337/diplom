import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'mood_model.dart';

class MoodRepository {
  final DatabaseService _db;
  MoodRepository(this._db);

  Future<List<MoodModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT id, patient_id, score, comment, sentiment::text, measured_at as timestamp FROM mood_entries WHERE patient_id = @id ORDER BY measured_at ASC'),
      parameters: {'id': patientId},
    );
    return result.map((r) => MoodModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(MoodModel m) async {
    await _db.pool.execute(
      Sql.named('INSERT INTO mood_entries (patient_id, score, comment, measured_at, sentiment) VALUES (@pId, @s, @c, CAST(@ts AS TIMESTAMPTZ), CAST(@sent AS sentiment_type))'),
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
    await _db.pool.execute(
      Sql.named('DELETE FROM mood_entries WHERE id = @id'),
      parameters: {'id': id},
    );
  }
}
