import '../../core/database/database_service.dart';
import 'questionnaire_model.dart';

class QuestionnaireRepository {
  final DatabaseService _db;
  QuestionnaireRepository(this._db);

  Future<List<QuestionnaireModel>> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM questionnaire_results WHERE patient_id = @id ORDER BY date DESC',
      parameters: {'id': patientId},
    );
    return result.map((r) => QuestionnaireModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(QuestionnaireModel q) async {
    await _db.execute(
      'INSERT INTO questionnaire_results (patient_id, title, total_score, date) VALUES (@pId, @t, @s, @d)',
      parameters: {
        'pId': q.patientId,
        't': q.title,
        's': q.totalScore,
        'd': q.date,
      },
    );
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM questionnaire_results WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
