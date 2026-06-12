import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'appointment_model.dart';

class AppointmentRepository {
  final DatabaseService _db;
  AppointmentRepository(this._db);

  String _mapAppointmentStatus(String? status) {
    switch (status) {
      case 'pending':
      case 'waiting':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
      case 'completed':
        return 'completed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      case 'no_show':
      case 'missed':
        return 'no_show';
      default:
        return 'pending';
    }
  }

  Future<List<AppointmentModel>> findByPatientId(int patientId) async {
    final result = await _db.pool.execute(
      Sql.named('''
        SELECT a.id, a.patient_id, a.type, a.title, a.scheduled_at, a.room, a.status::text, a.duration_minutes,
               d.name as doctor_name, p.name as patient_name
        FROM appointments a
        LEFT JOIN doctors d ON a.doctor_id = d.id
        LEFT JOIN patients p ON a.patient_id = p.id
        WHERE a.patient_id = @id 
        ORDER BY a.scheduled_at ASC
      '''),
      parameters: {'id': patientId},
    );
    return result.map((r) {
      final map = r.toColumnMap();
      // Map database columns to model fields
      map['time'] = map['scheduled_at'];
      map['doctor'] = map['doctor_name'];
      return AppointmentModel.fromMap(map);
    }).toList();
  }

  Future<void> create(AppointmentModel a) async {
    // We might need to find doctor_id by name if the frontend sends a name,
    // or update the frontend to send doctor_id.
    // For now, let's assume we can try to match the name if doctor_id is missing.

    await _db.pool.execute(
      Sql.named('''
        INSERT INTO appointments (patient_id, type, title, scheduled_at, room, doctor_id, status) 
        VALUES (@pId, @ty, @tl, CAST(@tm AS TIMESTAMPTZ), @r, (SELECT id FROM doctors WHERE name = @d LIMIT 1), CAST(@s AS appointment_status))
      '''),
      parameters: {
        'pId': a.patientId,
        'ty': a.type,
        'tl': a.title,
        'tm': a.time,
        'r': a.room,
        'd': a.doctor,
        's': _mapAppointmentStatus(a.status),
      },
    );
  }

  Future<void> updateStatus(int id, String status) async {
    await _db.pool.execute(
      Sql.named(
        'UPDATE appointments SET status = CAST(@s AS appointment_status) WHERE id = @id',
      ),
      parameters: {'s': _mapAppointmentStatus(status), 'id': id},
    );
  }

  Future<void> delete(int id) async {
    await _db.pool.execute(
      Sql.named('DELETE FROM appointments WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<List<AppointmentModel>> findByDoctorName(String name) async {
    final result = await _db.pool.execute(
      Sql.named('''
        SELECT a.id, a.patient_id, a.type, a.title, a.scheduled_at, a.room, a.status::text, a.duration_minutes,
               p.name as patient_name, d.name as doctor_name
        FROM appointments a 
        JOIN patients p ON a.patient_id = p.id 
        JOIN doctors d ON a.doctor_id = d.id
        WHERE d.name ILIKE @n 
        ORDER BY a.scheduled_at ASC
      '''),
      parameters: {'n': '%$name%'},
    );
    return result.map((r) {
      final map = r.toColumnMap();
      map['time'] = map['scheduled_at'];
      map['doctor'] = map['doctor_name'];
      return AppointmentModel.fromMap(map);
    }).toList();
  }
}
