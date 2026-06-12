import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'questionnaire_model.dart';

class QuestionnaireRepository {
  final DatabaseService _db;
  QuestionnaireRepository(this._db);

  Future<List<QuestionnaireModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT *, completed_at as date FROM questionnaire_results WHERE patient_id = @id ORDER BY completed_at DESC'),
      parameters: {'id': patientId},
    );
    return result.map((r) => QuestionnaireModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(QuestionnaireModel q) async {
    await _db.pool.execute(
      Sql.named('INSERT INTO questionnaire_results (patient_id, title, total_score, completed_at) VALUES (@pId, @t, @s, CAST(@d AS TIMESTAMPTZ))'),
      parameters: {
        'pId': q.patientId,
        't': q.title,
        's': q.totalScore,
        'd': q.date,
      },
    );
  }

  Future<void> delete(int id) async {
    await _db.pool.execute(
      Sql.named('DELETE FROM questionnaire_results WHERE id = @id'),
      parameters: {'id': id},
    );
  }
}
