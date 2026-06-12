import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'doctor_model.dart';

class DoctorRepository {
  final DatabaseService _db;
  DoctorRepository(this._db);

  Future<List<DoctorModel>> findAll() async {
    final result = await _db.pool.execute(Sql.named('SELECT * FROM doctors ORDER BY id'));
    return result.map((r) => DoctorModel.fromMap(r.toColumnMap())).toList();
  }

  Future<DoctorModel?> findById(int id) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT * FROM doctors WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return DoctorModel.fromMap(result.first.toColumnMap());
  }

  Future<int> create(DoctorModel doctor) async {
    final result = await _db.pool.execute(
      Sql.named('INSERT INTO doctors (name, specialization, phone, cabinet) VALUES (@n, @s, @p, @c) RETURNING id'),
      parameters: {
        'n': doctor.name,
        's': doctor.specialization,
        'p': doctor.phone,
        'c': doctor.cabinet,
      },
    );
    return result.first[0] as int;
  }

  Future<void> update(DoctorModel doctor) async {
    await _db.pool.execute(
      Sql.named('UPDATE doctors SET name=@n, specialization=@s, phone=@p, cabinet=@c WHERE id=@id'),
      parameters: {
        'id': doctor.id,
        'n': doctor.name,
        's': doctor.specialization,
        'p': doctor.phone,
        'c': doctor.cabinet,
      },
    );
  }

  Future<void> delete(int id) async {
    await _db.pool.execute(
      Sql.named('DELETE FROM doctors WHERE id = @id'),
      parameters: {'id': id},
    );
  }
}
