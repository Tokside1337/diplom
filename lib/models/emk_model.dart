import 'dart:convert';

class EMK {
  final String? id;
  final int patientId;
  final String status; // active, completed, archived
  final Map<String, dynamic> diagnoses;
  final Map<String, dynamic> contraindications;
  final Map<String, dynamic> treatmentGoals;
  final List<dynamic> dailyLogs;
  final List<dynamic> stageReviews;
  final Map<String, dynamic> finalRecommendations;
  final String createdAt;
  final String? updatedAt;

  EMK({
    this.id,
    required this.patientId,
    this.status = 'active',
    Map<String, dynamic>? diagnoses,
    Map<String, dynamic>? contraindications,
    Map<String, dynamic>? treatmentGoals,
    List<dynamic>? dailyLogs,
    List<dynamic>? stageReviews,
    Map<String, dynamic>? finalRecommendations,
    required this.createdAt,
    this.updatedAt,
  })  : diagnoses = diagnoses ?? {},
        contraindications = contraindications ?? {},
        treatmentGoals = treatmentGoals ?? {},
        dailyLogs = dailyLogs ?? [],
        stageReviews = stageReviews ?? [],
        finalRecommendations = finalRecommendations ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'status': status,
      'diagnoses': jsonEncode(diagnoses),
      'contraindications': jsonEncode(contraindications),
      'treatment_goals': jsonEncode(treatmentGoals),
      'daily_logs': jsonEncode(dailyLogs),
      'stage_reviews': jsonEncode(stageReviews),
      'final_recommendations': jsonEncode(finalRecommendations),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory EMK.fromMap(Map<String, dynamic> map) {
    return EMK(
      id: map['id']?.toString(),
      patientId: map['patient_id'],
      status: map['status'],
      diagnoses: _parseJson(map['diagnoses']),
      contraindications: _parseJson(map['contraindications']),
      treatmentGoals: _parseJson(map['treatment_goals']),
      dailyLogs: _parseList(map['daily_logs']),
      stageReviews: _parseList(map['stage_reviews']),
      finalRecommendations: _parseJson(map['final_recommendations']),
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  static Map<String, dynamic> _parseJson(dynamic source) {
    if (source == null) return {};
    if (source is Map<String, dynamic>) return source;
    try {
      return jsonDecode(source as String);
    } catch (_) {
      return {};
    }
  }

  static List<dynamic> _parseList(dynamic source) {
    if (source == null) return [];
    if (source is List) return source;
    try {
      return jsonDecode(source as String);
    } catch (_) {
      return [];
    }
  }
}
