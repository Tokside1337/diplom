import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'hospitalization_model.dart';

class HospitalizationRepository {
  final DatabaseService _db;
  HospitalizationRepository(this._db);

  Future<List<HospitalizationModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT * FROM hospitalizations WHERE patient_id = @id ORDER BY admission_date DESC'),
      parameters: {'id': patientId},
    );
    return result.map((r) => HospitalizationModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(HospitalizationModel h) async {
    await _db.pool.execute(
      Sql.named('INSERT INTO hospitalizations (patient_id, admission_date, discharge_date, reason, department) VALUES (@pId, CAST(@a AS TIMESTAMPTZ), CAST(@d AS TIMESTAMPTZ), @r, @dep)'),
      parameters: {
        'pId': h.patientId,
        'a': h.admissionDate,
        'd': h.dischargeDate,
        'r': h.reason,
        'dep': h.department,
      },
    );
  }
}
