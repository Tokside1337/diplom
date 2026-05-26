import '../../core/database/database_service.dart';
import 'reminder_model.dart';

class ReminderRepository {
  final DatabaseService _db;
  ReminderRepository(this._db);

  Future<List<ReminderModel>> findUnreadByPatientId(int patientId) async {
    final result = await _db.execute(
      'SELECT * FROM reminders WHERE patient_id = @id AND is_read = FALSE',
      parameters: {'id': patientId},
    );
    return result.map((r) => ReminderModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> markAsRead(int id) async {
    await _db.execute(
      'UPDATE reminders SET is_read = TRUE WHERE id = @id',
      parameters: {'id': id},
    );
  }

  Future<void> create(ReminderModel r) async {
    await _db.execute(
      'INSERT INTO reminders (patient_id, doctor_id, message, timestamp) VALUES (@pId, @dId, @m, @ts)',
      parameters: {
        'pId': r.patientId,
        'dId': r.doctorId,
        'm': r.message,
        'ts': r.timestamp,
      },
    );
  }
}
