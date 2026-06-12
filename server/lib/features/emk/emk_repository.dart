import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'emk_model.dart';

class EmkRepository {
  final DatabaseService _db;
  EmkRepository(this._db);

  Future<EmkModel?> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT id, patient_id, status::text, diagnoses, contraindications, treatment_goals, daily_logs, stage_reviews, final_recommendations, created_at, updated_at FROM emk WHERE patient_id = @pId'),
      parameters: {'pId': patientId},
    );
    if (result.isEmpty) return null;
    return EmkModel.fromMap(result.first.toColumnMap());
  }

  Future<void> create(EmkModel e) async {
    await _db.pool.execute(
      Sql.named('''
        INSERT INTO emk (patient_id, status, diagnoses, contraindications, treatment_goals, daily_logs, stage_reviews, final_recommendations) 
        VALUES (@pId, CAST(@s AS record_status), @diag, @cont, @goals, @logs, @steps, @final)
      '''),
      parameters: {
        'pId': e.patientId,
        's': e.status,
        'diag': e.diagnoses,
        'cont': e.contraindications,
        'goals': e.treatmentGoals,
        'logs': e.dailyLogs,
        'steps': e.stageReviews,
        'final': e.finalRecommendations,
      },
    );
  }

  Future<void> update(EmkModel e) async {
    await _db.pool.execute(
      Sql.named('''
        UPDATE emk SET status=CAST(@s AS record_status), diagnoses=@diag, contraindications=@cont, treatment_goals=@goals, 
        daily_logs=@logs, stage_reviews=@steps, final_recommendations=@final 
        WHERE patient_id=@pId
      '''),
      parameters: {
        'pId': e.patientId,
        's': e.status,
        'diag': e.diagnoses,
        'cont': e.contraindications,
        'goals': e.treatmentGoals,
        'logs': e.dailyLogs,
        'steps': e.stageReviews,
        'final': e.finalRecommendations,
      },
    );
  }
}
