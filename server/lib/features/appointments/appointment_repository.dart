import '../../core/database/database_service.dart';
import 'appointment_model.dart';

class AppointmentRepository {
  final DatabaseService _db;
  AppointmentRepository(this._db);

  Future<List<AppointmentModel>> findByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM appointments WHERE patient_id = @id ORDER BY time ASC',
      parameters: {'id': patientId},
    );
    return result.map((r) => AppointmentModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(AppointmentModel a) async {
    await _db.execute(
      'INSERT INTO appointments (patient_id, type, title, time, room, doctor, status) VALUES (@pId, @ty, @tl, @tm, @r, @d, @s)',
      parameters: {
        'pId': a.patientId,
        'ty': a.type,
        'tl': a.title,
        'tm': a.time,
        'r': a.room,
        'd': a.doctor,
        's': a.status,
      },
    );
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.execute(
      'UPDATE appointments SET status = @s WHERE id = @id',
      parameters: {'s': status, 'id': id},
    );
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM appointments WHERE id = @id',
      parameters: {'id': id},
    );
  }

  Future<List<AppointmentModel>> findByDoctorName(String name) async {
    final result = await _db.execute(
      '''
        SELECT a.*, p.name as patient_name 
        FROM appointments a 
        JOIN patients p ON a.patient_id = p.id 
        WHERE a.doctor ILIKE @n 
        ORDER BY a.time ASC
      ''',
      parameters: {'n': name},
    );
    return result.map((r) => AppointmentModel.fromMap(r.toColumnMap())).toList();
  }
}
