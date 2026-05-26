class PatientModel {
  final int? id;
  final String name;
  final String birthDate;
  final String? gender;
  final String? snils;
  final String? passportData;
  final String? phone;
  final String? relativeContact;
  final String? representativeData;
  final String? photoPath;
  final String? skkNumber;
  final String? skkDate;
  final String? issuedByLpu;
  final String? mainDiagnosisMkb;
  final String? secondaryDiagnosesMkb;
  final String? checkinExamination;
  final String? healthGroup;
  final String? dietTable;
  final String? forbiddenProcedures;
  final String? mobilityRegime;
  final String? arrivalPurpose;
  final String? fundingSource;
  final String? sanatoriumProfile;
  final String? plannedArrival;
  final String? plannedDeparture;
  final String? actualArrival;
  final String? actualDeparture;
  final String? roomNumber;
  final String? building;
  final String? floor;
  final int? doctorId;
  final int? bedDaysCount;
  final String? roomCategory;
  final String? dietType;
  final String? specialNeeds;
  final String? lfkGroup;
  final String? culturalParticipation;
  final String? voucherType;
  final String? extraServices;
  final String? companionData;
  final String? status;
  final String? treatmentEfficiency;
  final String? treatmentDurationCategory;
  final String? benefitCategory;
  final String? egiszId;
  final String? fssReferralId;
  final bool? isEgiszActivated;
  final String? diagnosis;
  final String? contraindications;
  final String? treatmentGoals;
  final String? dynamics;
  final String? finalRecommendations;

  PatientModel({
    this.id,
    required this.name,
    required this.birthDate,
    this.gender,
    this.snils,
    this.passportData,
    this.phone,
    this.relativeContact,
    this.representativeData,
    this.photoPath,
    this.skkNumber,
    this.skkDate,
    this.issuedByLpu,
    this.mainDiagnosisMkb,
    this.secondaryDiagnosesMkb,
    this.checkinExamination,
    this.healthGroup,
    this.dietTable,
    this.forbiddenProcedures,
    this.mobilityRegime,
    this.arrivalPurpose,
    this.fundingSource,
    this.sanatoriumProfile,
    this.plannedArrival,
    this.plannedDeparture,
    this.actualArrival,
    this.actualDeparture,
    this.roomNumber,
    this.building,
    this.floor,
    this.doctorId,
    this.bedDaysCount,
    this.roomCategory,
    this.dietType,
    this.specialNeeds,
    this.lfkGroup,
    this.culturalParticipation,
    this.voucherType,
    this.extraServices,
    this.companionData,
    this.status,
    this.treatmentEfficiency,
    this.treatmentDurationCategory,
    this.benefitCategory,
    this.egiszId,
    this.fssReferralId,
    this.isEgiszActivated,
    this.diagnosis,
    this.contraindications,
    this.treatmentGoals,
    this.dynamics,
    this.finalRecommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'snils': snils,
      'passport_data': passportData,
      'phone': phone,
      'relative_contact': relativeContact,
      'representative_data': representativeData,
      'photo_path': photoPath,
      'skk_number': skkNumber,
      'skk_date': skkDate,
      'issued_by_lpu': issuedByLpu,
      'main_diagnosis_mkb': mainDiagnosisMkb,
      'secondary_diagnoses_mkb': secondaryDiagnosesMkb,
      'checkin_examination': checkinExamination,
      'health_group': healthGroup,
      'diet_table': dietTable,
      'forbidden_procedures': forbiddenProcedures,
      'mobility_regime': mobilityRegime,
      'arrival_purpose': arrivalPurpose,
      'funding_source': fundingSource,
      'sanatorium_profile': sanatoriumProfile,
      'planned_arrival': plannedArrival,
      'planned_departure': plannedDeparture,
      'actual_arrival': actualArrival,
      'actual_departure': actualDeparture,
      'room_number': roomNumber,
      'building': building,
      'floor': floor,
      'doctor_id': doctorId,
      'bed_days_count': bedDaysCount,
      'room_category': roomCategory,
      'diet_type': dietType,
      'special_needs': specialNeeds,
      'lfk_group': lfkGroup,
      'cultural_participation': culturalParticipation,
      'voucher_type': voucherType,
      'extra_services': extraServices,
      'companion_data': companionData,
      'status': status,
      'treatment_efficiency': treatmentEfficiency,
      'treatment_duration_category': treatmentDurationCategory,
      'benefit_category': benefitCategory,
      'egisz_id': egiszId,
      'fss_referral_id': fssReferralId,
      'is_egisz_activated': isEgiszActivated,
      'diagnosis': diagnosis,
      'contraindications': contraindications,
      'treatment_goals': treatmentGoals,
      'dynamics': dynamics,
      'final_recommendations': finalRecommendations,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'],
      name: map['name'] ?? '',
      birthDate: _formatDate(map['birth_date']),
      gender: map['gender'],
      snils: map['snils'],
      passportData: map['passport_data'],
      phone: map['phone'],
      relativeContact: map['relative_contact'],
      representativeData: map['representative_data'],
      photoPath: map['photo_path'],
      skkNumber: map['skk_number'],
      skkDate: _formatDate(map['skk_date']),
      issuedByLpu: map['issued_by_lpu'],
      mainDiagnosisMkb: map['main_diagnosis_mkb'],
      secondaryDiagnosesMkb: map['secondary_diagnoses_mkb'],
      checkinExamination: map['checkin_examination'],
      healthGroup: map['health_group'],
      dietTable: map['diet_table'],
      forbiddenProcedures: map['forbidden_procedures'],
      mobilityRegime: map['mobility_regime'],
      arrivalPurpose: map['arrival_purpose'],
      fundingSource: map['funding_source'],
      sanatoriumProfile: map['sanatorium_profile'],
      plannedArrival: _formatDate(map['planned_arrival']),
      plannedDeparture: _formatDate(map['planned_departure']),
      actualArrival: _formatDate(map['actual_arrival']),
      actualDeparture: _formatDate(map['actual_departure']),
      roomNumber: map['room_number'],
      building: map['building'],
      floor: map['floor'],
      doctorId: map['doctor_id'],
      bedDaysCount: map['bed_days_count'],
      roomCategory: map['room_category'],
      dietType: map['diet_type'],
      specialNeeds: map['special_needs'],
      lfkGroup: map['lfk_group'],
      culturalParticipation: map['cultural_participation'],
      voucherType: map['voucher_type'],
      extraServices: map['extra_services'],
      companionData: map['companion_data'],
      status: map['status'],
      treatmentEfficiency: map['treatment_efficiency'],
      treatmentDurationCategory: map['treatment_duration_category'],
      benefitCategory: map['benefit_category'],
      egiszId: map['egisz_id'],
      fssReferralId: map['fss_referral_id'],
      isEgiszActivated: map['is_egisz_activated'],
      diagnosis: map['diagnosis'],
      contraindications: map['contraindications'],
      treatmentGoals: map['treatment_goals'],
      dynamics: map['dynamics'],
      finalRecommendations: map['final_recommendations'],
    );
  }
}
