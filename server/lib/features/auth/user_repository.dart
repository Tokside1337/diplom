import '../../core/database/database_service.dart';
import 'user_model.dart';

class UserRepository {
  final DatabaseService _db;
  UserRepository(this._db);

  Future<UserModel?> findByLogin(String login) async {
    final result = await _db.execute(
      'SELECT id, login, password, role, patient_id, doctor_id FROM users WHERE login = @l',
      parameters: {'l': login},
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first.toColumnMap());
  }

  Future<List<UserModel>> findAll() async {
    final result = await _db.execute('SELECT id, login, password, role, patient_id, doctor_id FROM users ORDER BY id');
    return result.map((r) => UserModel.fromMap(r.toColumnMap())).toList();
  }

  Future<void> create(UserModel user) async {
    await _db.execute(
      'INSERT INTO users (login, password, role, patient_id, doctor_id) VALUES (@l, @p, @r, @pId, @dId)',
      parameters: {
        'l': user.login,
        'p': user.password,
        'r': user.role,
        'pId': (user.patientId == 0) ? null : user.patientId,
        'dId': (user.doctorId == 0) ? null : user.doctorId,
      },
    );
  }

  Future<void> update(UserModel user) async {
    await _db.execute(
      'UPDATE users SET login=@l, password=@p, role=@r, patient_id=@pId, doctor_id=@dId WHERE id=@id',
      parameters: {
        'id': user.id,
        'l': user.login,
        'p': user.password,
        'r': user.role,
        'pId': (user.patientId == 0) ? null : user.patientId,
        'dId': (user.doctorId == 0) ? null : user.doctorId,
      },
    );
  }

  Future<Map<String, dynamic>?> findRoleInfo(int id) async {
    final res = await _db.execute(
      'SELECT role, patient_id, doctor_id FROM users WHERE id = @id',
      parameters: {'id': id},
    );
    if (res.isEmpty) return null;
    return res.first.toColumnMap();
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM users WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
