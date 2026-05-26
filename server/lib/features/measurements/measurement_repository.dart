import '../../core/database/database_service.dart';
import 'measurement_model.dart';

class MeasurementRepository {
  final DatabaseService _db;
  MeasurementRepository(this._db);

  Future<List<MeasurementModel>> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM measurements WHERE patient_id = @id ORDER BY timestamp ASC',
      parameters: {'id': patientId},
    );
    return result.map((r) => MeasurementModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(MeasurementModel m) async {
    await _db.execute(
      'INSERT INTO measurements (patient_id, pressure_systolic, pressure_diastolic, pulse, pain_level, timestamp) VALUES (@pId, @sys, @dia, @p, @pl, @ts)',
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
