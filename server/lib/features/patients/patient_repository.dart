import 'package:postgres/postgres.dart';
import '../../core/database/database_service.dart';
import 'patient_model.dart';

class PatientRepository {
  final DatabaseService _db;
  PatientRepository(this._db);

  String get _baseSelect => '''
    SELECT 
      p.id, p.name, p.birth_date, p.gender::text, p.snils, p.passport_data, p.phone, 
      p.relative_contact, p.representative_data, p.photo_path, p.benefit_category, p.egisz_id,
      s.status::text, s.planned_arrival, s.planned_departure, s.actual_arrival, s.actual_departure,
      s.bed_days_count, s.building, s.floor, s.room_number, s.room_category,
      s.arrival_purpose, s.funding_source, s.sanatorium_profile, s.voucher_type, s.fss_referral_id,
      s.skk_number, s.skk_date, s.issued_by_lpu, s.cultural_participation, s.extra_services, s.companion_data,
      s.doctor_id,
      m.main_diagnosis_mkb, m.secondary_diagnoses_mkb, m.checkin_examination, m.health_group,
      m.diet_table, m.diet_type, m.forbidden_procedures, m.mobility_regime, m.lfk_group, m.special_needs,
      m.is_egisz_activated, m.treatment_efficiency, m.treatment_duration_category, m.dynamics,
      e.diagnoses as diagnosis, e.contraindications, e.treatment_goals, e.final_recommendations
    FROM patients p
    LEFT JOIN LATERAL (SELECT * FROM stay_records WHERE patient_id = p.id ORDER BY created_at DESC LIMIT 1) s ON true
    LEFT JOIN LATERAL (SELECT * FROM medical_profiles WHERE stay_id = s.id ORDER BY created_at DESC LIMIT 1) m ON true
    LEFT JOIN emk e ON e.patient_id = p.id
  ''';

  dynamic _toSqlDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      // Handle DD.MM.YYYY
      if (date.contains('.')) {
        final parts = date.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  Future<List<PatientModel>> findAll({int limit = 100, int offset = 0}) async {
    final result = await _db.pool.execute(
      Sql.named('$_baseSelect ORDER BY p.id LIMIT @limit OFFSET @offset'),
      parameters: {'limit': limit, 'offset': offset},
    );
    return result.map((r) => PatientModel.fromMap(r.toColumnMap())).toList();
  }

  Future<PatientModel?> findById(int id) async {
    final result = await _db.pool.execute(
      Sql.named('$_baseSelect WHERE p.id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return PatientModel.fromMap(result.first.toColumnMap());
  }

  String? _mapGender(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    final g = gender.toLowerCase();
    if (g.contains('муж') || g == 'male') return 'male';
    if (g.contains('жен') || g == 'female') return 'female';
    return 'other';
  }

  String _mapAdmissionStatus(String? status) {
    switch (status) {
      case 'planned':
      case 'wait_checkin':
      case 'waiting':
        return 'planned';
      case 'active':
      case 'isolated':
        return 'active';
      case 'discharged':
      case 'completed':
      case 'early_checkout':
        return 'discharged';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return 'planned';
    }
  }

  Future<int> create(PatientModel p) async {
    return await _db.pool.withConnection((conn) async {
      return await conn.runTx((ctx) async {
        // 1. Patients
        final pRes = await ctx.execute(
          Sql.named(
            '''INSERT INTO patients (name, birth_date, gender, snils, passport_data, phone, relative_contact, representative_data, photo_path, benefit_category, egisz_id)
            VALUES (@name, CAST(@birth_date AS DATE), CAST(@gender AS gender_type), @snils, @passport_data, @phone, @relative_contact, @representative_data, @photo_path, @benefit_category, @egisz_id) RETURNING id''',
          ),
          parameters: {
            'name': p.name,
            'birth_date': _toSqlDate(p.birthDate),
            'gender': _mapGender(p.gender),
            'snils': p.snils,
            'passport_data': p.passportData,
            'phone': p.phone,
            'relative_contact': p.relativeContact,
            'representative_data': p.representativeData,
            'photo_path': p.photoPath,
            'benefit_category': p.benefitCategory,
            'egisz_id': p.egiszId,
          },
        );
        final patientId = (pRes.first[0] as num).toInt();

        // 2. Stay Records
        final sRes = await ctx.execute(
          Sql.named(
            '''INSERT INTO stay_records (patient_id, doctor_id, status, planned_arrival, planned_departure, actual_arrival, actual_departure, bed_days_count, building, floor, room_number, room_category, arrival_purpose, funding_source, sanatorium_profile, voucher_type, fss_referral_id, skk_number, skk_date, issued_by_lpu, cultural_participation, extra_services, companion_data)
            VALUES (@patient_id, @doctor_id, CAST(@status AS admission_status), @planned_arrival, @planned_departure, @actual_arrival, @actual_departure, @bed_days_count, @building, @floor, @room_number, @room_category, @arrival_purpose, @funding_source, @sanatorium_profile, @voucher_type, @fss_referral_id, @skk_number, @skk_date, @issued_by_lpu, @cultural_participation, @extra_services, @companion_data) RETURNING id''',
          ),
          parameters: {
            'patient_id': patientId,
            'doctor_id': p.doctorId,
            'status': _mapAdmissionStatus(p.status),
            'planned_arrival': _toSqlDate(p.plannedArrival),
            'planned_departure': _toSqlDate(p.plannedDeparture),
            'actual_arrival': _toSqlDate(p.actualArrival),
            'actual_departure': _toSqlDate(p.actualDeparture),
            'bed_days_count': p.bedDaysCount,
            'building': p.building,
            'floor': p.floor,
            'room_number': p.roomNumber,
            'room_category': p.roomCategory,
            'arrival_purpose': p.arrivalPurpose,
            'funding_source': p.fundingSource,
            'sanatorium_profile': p.sanatoriumProfile,
            'voucher_type': p.voucherType,
            'fss_referral_id': p.fssReferralId,
            'skk_number': p.skkNumber,
            'skk_date': _toSqlDate(p.skkDate),
            'issued_by_lpu': p.issuedByLpu,
            'cultural_participation': p.culturalParticipation,
            'extra_services': p.extraServices,
            'companion_data': p.companionData,
          },
        );
        final stayId = (sRes.first[0] as num).toInt();

        // 3. Medical Profile
        await ctx.execute(
          Sql.named(
            '''INSERT INTO medical_profiles (patient_id, stay_id, main_diagnosis_mkb, secondary_diagnoses_mkb, checkin_examination, health_group, diet_table, diet_type, forbidden_procedures, mobility_regime, lfk_group, special_needs, is_egisz_activated, treatment_efficiency, treatment_duration_category, dynamics)
            VALUES (@patient_id, @stay_id, @main_diagnosis_mkb, @secondary_diagnoses_mkb, @checkin_examination, @health_group, @diet_table, @diet_type, @forbidden_procedures, @mobility_regime, @lfk_group, @special_needs, @is_egisz_activated, @treatment_efficiency, @treatment_duration_category, @dynamics)''',
          ),
          parameters: {
            'patient_id': patientId,
            'stay_id': stayId,
            'main_diagnosis_mkb': p.mainDiagnosisMkb,
            'secondary_diagnoses_mkb': p.secondaryDiagnosesMkb,
            'checkin_examination': p.checkinExamination,
            'health_group': p.healthGroup,
            'diet_table': p.dietTable,
            'diet_type': p.dietType,
            'forbidden_procedures': p.forbiddenProcedures,
            'mobility_regime': p.mobilityRegime,
            'lfk_group': p.lfkGroup,
            'special_needs': p.specialNeeds,
            'is_egisz_activated': p.isEgiszActivated ?? false,
            'treatment_efficiency': p.treatmentEfficiency,
            'treatment_duration_category': p.treatmentDurationCategory,
            'dynamics': p.dynamics,
          },
        );

        return patientId;
      });
    });
  }

  Future<void> update(PatientModel p) async {
    if (p.id == null) return;

    await _db.pool.withConnection((conn) async {
      await conn.runTx((ctx) async {
        // Update Patient
        await ctx.execute(
          Sql.named(
            '''UPDATE patients SET name=@name, birth_date=CAST(@birth_date AS DATE), gender=CAST(@gender AS gender_type), snils=@snils, passport_data=@passport_data, phone=@phone, relative_contact=@relative_contact, representative_data=@representative_data, photo_path=@photo_path, benefit_category=@benefit_category, egisz_id=@egisz_id WHERE id=@id''',
          ),
          parameters: {
            'id': p.id,
            'name': p.name,
            'birth_date': _toSqlDate(p.birthDate),
            'gender': _mapGender(p.gender),
            'snils': p.snils,
            'passport_data': p.passportData,
            'phone': p.phone,
            'relative_contact': p.relativeContact,
            'representative_data': p.representativeData,
            'photo_path': p.photoPath,
            'benefit_category': p.benefitCategory,
            'egisz_id': p.egiszId,
          },
        );

        // Find latest stay
        final sRes = await ctx.execute(
          Sql.named(
            'SELECT id FROM stay_records WHERE patient_id = @id ORDER BY created_at DESC LIMIT 1',
          ),
          parameters: {'id': p.id},
        );

        if (sRes.isNotEmpty) {
          final stayId = sRes.first[0] as int;
          // Update Stay
          await ctx.execute(
            Sql.named(
              '''UPDATE stay_records SET doctor_id=@doctor_id, status=CAST(@status AS admission_status), planned_arrival=@planned_arrival, planned_departure=@planned_departure, actual_arrival=@actual_arrival, actual_departure=@actual_departure, bed_days_count=@bed_days_count, building=@building, floor=@floor, room_number=@room_number, room_category=@room_category, arrival_purpose=@arrival_purpose, funding_source=@funding_source, sanatorium_profile=@sanatorium_profile, voucher_type=@voucher_type, fss_referral_id=@fss_referral_id, skk_number=@skk_number, skk_date=@skk_date, issued_by_lpu=@issued_by_lpu, cultural_participation=@cultural_participation, extra_services=@extra_services, companion_data=@companion_data WHERE id=@stay_id''',
            ),
            parameters: {
              'stay_id': stayId,
              'doctor_id': p.doctorId,
              'status': _mapAdmissionStatus(p.status),
              'planned_arrival': _toSqlDate(p.plannedArrival),
              'planned_departure': _toSqlDate(p.plannedDeparture),
              'actual_arrival': _toSqlDate(p.actualArrival),
              'actual_departure': _toSqlDate(p.actualDeparture),
              'bed_days_count': p.bedDaysCount,
              'building': p.building,
              'floor': p.floor,
              'room_number': p.roomNumber,
              'room_category': p.roomCategory,
              'arrival_purpose': p.arrivalPurpose,
              'funding_source': p.fundingSource,
              'sanatorium_profile': p.sanatoriumProfile,
              'voucher_type': p.voucherType,
              'fss_referral_id': p.fssReferralId,
              'skk_number': p.skkNumber,
              'skk_date': _toSqlDate(p.skkDate),
              'issued_by_lpu': p.issuedByLpu,
              'cultural_participation': p.culturalParticipation,
              'extra_services': p.extraServices,
              'companion_data': p.companionData,
            },
          );

          // Update Medical Profile
          await ctx.execute(
            Sql.named(
              '''UPDATE medical_profiles SET main_diagnosis_mkb=@main_diagnosis_mkb, secondary_diagnoses_mkb=@secondary_diagnoses_mkb, checkin_examination=@checkin_examination, health_group=@health_group, diet_table=@diet_table, diet_type=@diet_type, forbidden_procedures=@forbidden_procedures, mobility_regime=@mobility_regime, lfk_group=@lfk_group, special_needs=@special_needs, is_egisz_activated=@is_egisz_activated, treatment_efficiency=@treatment_efficiency, treatment_duration_category=@treatment_duration_category, dynamics=@dynamics WHERE stay_id=@stay_id''',
            ),
            parameters: {
              'stay_id': stayId,
              'main_diagnosis_mkb': p.mainDiagnosisMkb,
              'secondary_diagnoses_mkb': p.secondaryDiagnosesMkb,
              'checkin_examination': p.checkinExamination,
              'health_group': p.healthGroup,
              'diet_table': p.dietTable,
              'diet_type': p.dietType,
              'forbidden_procedures': p.forbiddenProcedures,
              'mobility_regime': p.mobilityRegime,
              'lfk_group': p.lfkGroup,
              'special_needs': p.specialNeeds,
              'is_egisz_activated': p.isEgiszActivated ?? false,
              'treatment_efficiency': p.treatmentEfficiency,
              'treatment_duration_category': p.treatmentDurationCategory,
              'dynamics': p.dynamics,
            },
          );
        }
      });
    });
  }

  Future<void> delete(int id) async {
    await _db.execute(
      'DELETE FROM patients WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
