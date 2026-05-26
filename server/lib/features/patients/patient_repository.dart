import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'patient_model.dart';

class PatientRepository {
  final DatabaseService _db;
  PatientRepository(this._db);

  Future<List<PatientModel>> findAll({int limit = 100, int offset = 0}) async {
    final result = await _db.pool.execute(
      Sql.named('SELECT * FROM patients ORDER BY id LIMIT @limit OFFSET @offset'),
      parameters: {'limit': limit, 'offset': offset},
    );
    return result.map((r) => PatientModel.fromMap(r.toColumnMap())).toList();
  }

  Future<PatientModel?> findById(int id) async {
    final result = await _db.execute(
      'SELECT * FROM patients WHERE id = @id',
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return PatientModel.fromMap(result.first.toColumnMap());
  }

  Future<int> create(PatientModel p) async {
    final result = await _db.execute(
      '''INSERT INTO patients (name, birth_date, gender, snils, passport_data, phone, relative_contact, representative_data, photo_path, skk_number, skk_date, issued_by_lpu, main_diagnosis_mkb, secondary_diagnoses_mkb, checkin_examination, health_group, diet_table, forbidden_procedures, mobility_regime, arrival_purpose, funding_source, sanatorium_profile, planned_arrival, planned_departure, actual_arrival, actual_departure, room_number, building, floor, doctor_id, bed_days_count, room_category, diet_type, special_needs, lfk_group, cultural_participation, voucher_type, extra_services, companion_data, status, treatment_efficiency, treatment_duration_category, benefit_category, egisz_id, fss_referral_id, is_egisz_activated, diagnosis, contraindications, treatment_goals, dynamics, final_recommendations) 
        VALUES (@name, @birth_date, @gender, @snils, @passport_data, @phone, @relative_contact, @representative_data, @photo_path, @skk_number, @skk_date, @issued_by_lpu, @main_diagnosis_mkb, @secondary_diagnoses_mkb, @checkin_examination, @health_group, @diet_table, @forbidden_procedures, @mobility_regime, @arrival_purpose, @funding_source, @sanatorium_profile, @planned_arrival, @planned_departure, @actual_arrival, @actual_departure, @room_number, @building, @floor, @doctor_id, @bed_days_count, @room_category, @diet_type, @special_needs, @lfk_group, @cultural_participation, @voucher_type, @extra_services, @companion_data, @status, @treatment_efficiency, @treatment_duration_category, @benefit_category, @egisz_id, @fss_referral_id, @is_egisz_activated, @diagnosis, @contraindications, @treatment_goals, @dynamics, @final_recommendations) RETURNING id''',
      parameters: p.toMap()..remove('id'),
    );
    return result.first[0] as int;
  }

  Future<void> update(PatientModel p) async {
    await _db.execute(
      '''UPDATE patients SET name=@name, birth_date=@birth_date, gender=@gender, snils=@snils, passport_data=@passport_data, phone=@phone, relative_contact=@relative_contact, representative_data=@representative_data, photo_path=@photo_path, skk_number=@skk_number, skk_date=@skk_date, issued_by_lpu=@issued_by_lpu, main_diagnosis_mkb=@main_diagnosis_mkb, secondary_diagnoses_mkb=@secondary_diagnoses_mkb, checkin_examination=@checkin_examination, health_group=@health_group, diet_table=@diet_table, forbidden_procedures=@forbidden_procedures, mobility_regime=@mobility_regime, arrival_purpose=@arrival_purpose, funding_source=@funding_source, sanatorium_profile=@sanatorium_profile, planned_arrival=@planned_arrival, planned_departure=@planned_departure, actual_arrival=@actual_arrival, actual_departure=@actual_departure, room_number=@room_number, building=@building, floor=@floor, doctor_id=@doctor_id, bed_days_count=@bed_days_count, room_category=@room_category, diet_type=@diet_type, special_needs=@special_needs, lfk_group=@lfk_group, cultural_participation=@cultural_participation, voucher_type=@voucher_type, extra_services=@extra_services, companion_data=@companion_data, status=@status, treatment_efficiency=@treatment_efficiency, treatment_duration_category=@treatment_duration_category, benefit_category=@benefit_category, egisz_id=@egisz_id, fss_referral_id=@fss_referral_id, is_egisz_activated=@is_egisz_activated, diagnosis=@diagnosis, contraindications=@contraindications, treatment_goals=@treatment_goals, dynamics=@dynamics, final_recommendations=@final_recommendations WHERE id=@id''',
      parameters: p.toMap(),
    );
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM patients WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
