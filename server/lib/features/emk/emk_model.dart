class EmkModel {
  final String? id;
  final int patientId;
  final String status;
  final String? diagnoses;
  final String? contraindications;
  final String? treatmentGoals;
  final String? dailyLogs;
  final String? stageReviews;
  final String? finalRecommendations;
  final String? createdAt;
  final String? updatedAt;

  EmkModel({
    this.id,
    required this.patientId,
    this.status = 'active',
    this.diagnoses,
    this.contraindications,
    this.treatmentGoals,
    this.dailyLogs,
    this.stageReviews,
    this.finalRecommendations,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'status': status,
      'diagnoses': diagnoses,
      'contraindications': contraindications,
      'treatment_goals': treatmentGoals,
      'daily_logs': dailyLogs,
      'stage_reviews': stageReviews,
      'final_recommendations': finalRecommendations,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static String _formatDate(dynamic val) {
    if (val == null) return '';
    if (val is DateTime) return val.toIso8601String();
    return val.toString();
  }

  factory EmkModel.fromMap(Map<String, dynamic> map) {
    return EmkModel(
      id: map['id']?.toString(),
      patientId: map['patient_id'],
      status: map['status'] ?? 'active',
      diagnoses: map['diagnoses'],
      contraindications: map['contraindications'],
      treatmentGoals: map['treatment_goals'],
      dailyLogs: map['daily_logs'],
      stageReviews: map['stage_reviews'],
      finalRecommendations: map['final_recommendations'],
      createdAt: _formatDate(map['created_at']),
      updatedAt: _formatDate(map['updated_at']),
    );
  }
}
