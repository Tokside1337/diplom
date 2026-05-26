import '../../core/database/database_service.dart';
import 'emk_model.dart';

class EmkRepository {
  final DatabaseService _db;
  EmkRepository(this._db);

  Future<EmkModel?> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM emk WHERE patient_id = @pId',
      parameters: {'pId': patientId},
    );
    if (result.isEmpty) return null;
    return EmkModel.fromMap(result.first.toColumnMap());
  }

  Future<void> create(EmkModel e) async {
    await _db.execute(
      '''
        INSERT INTO emk (patient_id, status, diagnoses, contraindications, treatment_goals, daily_logs, stage_reviews, final_recommendations, created_at, updated_at) 
        VALUES (@pId, @s, @diag, @cont, @goals, @logs, @steps, @final, @cAt, @uAt)
      ''',
      parameters: {
        'pId': e.patientId,
        's': e.status,
        'diag': e.diagnoses,
        'cont': e.contraindications,
        'goals': e.treatmentGoals,
        'logs': e.dailyLogs,
        'steps': e.stageReviews,
        'final': e.finalRecommendations,
        'cAt': e.createdAt,
        'uAt': e.updatedAt,
      },
    );
  }

  Future<void> update(EmkModel e) async {
    await _db.execute(
      '''
        UPDATE emk SET status=@s, diagnoses=@diag, contraindications=@cont, treatment_goals=@goals, 
        daily_logs=@logs, stage_reviews=@steps, final_recommendations=@final, updated_at=@uAt 
        WHERE patient_id=@pId
      ''',
      parameters: {
        'pId': e.patientId,
        's': e.status,
        'diag': e.diagnoses,
        'cont': e.contraindications,
        'goals': e.treatmentGoals,
        'logs': e.dailyLogs,
        'steps': e.stageReviews,
        'final': e.finalRecommendations,
        'uAt': e.updatedAt,
      },
    );
  }
}
