import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/app_config.dart';
import 'ai_prompts.dart';
import '../patients/patient_repository.dart';
import '../emk/emk_repository.dart';
import '../measurements/measurement_repository.dart';
import '../mood/mood_repository.dart';

class AiService {
  final PatientRepository _patientRepo;
  final EmkRepository _emkRepo;
  final MeasurementRepository _measurementRepo;
  final MoodRepository _moodRepo;

  AiService(this._patientRepo, this._emkRepo, this._measurementRepo, this._moodRepo);

  Future<String> chat(String message, int patientId, bool isDoctor) async {
    String contextData = '';
    if (patientId > 0) {
      final p = await _patientRepo.findById(patientId);
      if (p != null) {
        final emk = await _emkRepo.findByPatientId(patientId);
        String emkStr = emk != null 
            ? 'Диагнозы ЭМК: ${emk.diagnoses ?? "нет"}, Противопоказания: ${emk.contraindications ?? "нет"}, SMART-цели: ${emk.treatmentGoals ?? "не заданы"}'
            : '';

        final measurements = await _measurementRepo.findByPatientId(patientId);
        final moods = await _moodRepo.findByPatientId(patientId);

        contextData = 'КОНТЕКСТ ПАЦИЕНТА:\n'
            'Имя: ${p.name}\n'
            'Основной диагноз: ${p.mainDiagnosisMkb ?? "Не указан"}\n'
            'Группа здоровья: ${p.healthGroup ?? "—"}\n'
            '$emkStr\n'
            'Замеры давления: ${measurements.reversed.take(5).map((m) => "${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()}").join(", ")}\n'
            'Настроение (комменты): ${moods.reversed.take(3).map((m) => m.comment).join("; ")}\n';
      }
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.aiApiKey,
      systemInstruction: Content.system(isDoctor ? AiPrompts.doctorPrompt : AiPrompts.patientPrompt),
    );

    final prompt = contextData.isNotEmpty ? '$contextData\n\nЗапрос: $message' : message;
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Не удалось получить ответ.';
  }

  Future<Map<String, dynamic>> analyzeHealth(int patientId) async {
    final p = await _patientRepo.findById(patientId);
    if (p == null) throw Exception('Patient not found');

    final emk = await _emkRepo.findByPatientId(patientId);
    String emkContext = emk != null 
        ? '--- ДАННЫЕ ЭМК ---\nКлинические диагнозы: ${emk.diagnoses ?? "нет"}\nПротивопоказания: ${emk.contraindications ?? "нет"}\nЦели реабилитации (SMART): ${emk.treatmentGoals ?? "не заданы"}\nИтоговые рекомендации: ${emk.finalRecommendations ?? "нет"}\n'
        : '';

    final measurements = await _measurementRepo.findByPatientId(patientId);
    final moods = await _moodRepo.findByPatientId(patientId);

    String medicalContext = 'ПАЦИЕНТ: ${p.name}\n'
        'Основной диагноз: ${p.mainDiagnosisMkb ?? "Не указан"}\n'
        'Группа здоровья: ${p.healthGroup ?? "Не указана"}\n'
        'Цель заезда: ${p.arrivalPurpose ?? "Не указана"}\n'
        '$emkContext\n'
        'ПОСЛЕДНИЕ ЗАМЕРЫ (АД, Пульс, Боль): ${measurements.reversed.take(10).map((m) => "${m.pressureSystolic.toInt()}/${m.pressureDiastolic.toInt()}, P:${m.pulse}, Pain:${m.painLevel}").join("; ")}\n'
        'ПОСЛЕДНЕЕ НАСТРОЕНИЕ: ${moods.reversed.take(5).map((m) => "Оценка:${m.score}, Коммент:${m.comment}").join("; ")}\n';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.aiApiKey,
      systemInstruction: Content.system(AiPrompts.analysisInstruction),
    );

    final response = await model.generateContent([Content.text('Проанализируй состояние пациента и данные его медкарты:\n$medicalContext')]);
    final text = response.text ?? '';

    String cleanJson = text;
    if (text.contains('```json')) {
      cleanJson = text.split('```json')[1].split('```')[0].trim();
    } else if (text.contains('```')) {
      cleanJson = text.split('```')[1].split('```')[0].trim();
    }

    try {
      return jsonDecode(cleanJson);
    } catch (e) {
      return {
        'summary': text,
        'recommendations': ['Следуйте назначениям врача', 'Соблюдайте режим покоя', 'Продолжайте мониторинг']
      };
    }
  }
}
