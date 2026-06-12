import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'measurement_model.dart';

class MeasurementRepository {
  final DatabaseService _db;
  MeasurementRepository(this._db);

  Future<List<MeasurementModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT *, measured_at as timestamp FROM measurements WHERE patient_id = @id ORDER BY measured_at ASC'),
      parameters: {'id': patientId},
    );
    return result.map((r) => MeasurementModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(MeasurementModel m) async {
    await _db.pool.execute(
      Sql.named('INSERT INTO measurements (patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, measured_at) VALUES (@pId, @sys, @dia, @p, @pl, CAST(@ts AS TIMESTAMPTZ))'),
      parameters: {
        'pId': m.patientId,
        'sys': m.pressureSystolic,
        'dia': m.pressureDiastolic,
        'p': m.pulse,
        'pl': m.painLevel,
        'ts': m.timestamp,
      },
    );
  }
}
