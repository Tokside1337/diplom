import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Future<String> _callOllama(String systemPrompt, String userPrompt) async {
    final url = Uri.parse('${AppConfig.ollamaBaseUrl}/api/chat');
    
    final body = jsonEncode({
      'model': AppConfig.ollamaModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'stream': false,
    });

    print('[AiService] Calling Ollama: ${AppConfig.ollamaModel}');
    print('[AiService] Prompt length: ${userPrompt.length}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['message']['content'] as String;
        print('[AiService] Success. Response length: ${content.length}');
        return content;
      } else {
        print('[AiService] Error from Ollama: ${response.statusCode} ${response.body}');
        return 'Ошибка LLM (код ${response.statusCode}).';
      }
    } catch (e) {
      print('[AiService] Exception during Ollama call: $e');
      return 'Не удалось связаться с локальной LLM.';
    }
  }

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

    final systemPrompt = isDoctor ? AiPrompts.doctorPrompt : AiPrompts.patientPrompt;
    final userPrompt = contextData.isNotEmpty ? '$contextData\n\nЗапрос: $message' : message;

    return await _callOllama(systemPrompt, userPrompt);
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

    final text = await _callOllama(AiPrompts.analysisInstruction, 'Проанализируй состояние пациента и данные его медкарты:\n$medicalContext');

    String cleanJson = text;
    if (text.contains('```json')) {
      cleanJson = text.split('```json')[1].split('```')[0].trim();
    } else if (text.contains('```')) {
      cleanJson = text.split('```')[1].split('```')[0].trim();
    }

    try {
      return jsonDecode(cleanJson);
    } catch (e) {
      print('[AiService] JSON parse error: $e. Raw text: $text');
      return {
        'summary': text,
        'recommendations': ['Следуйте назначениям врача', 'Соблюдайте режим покоя', 'Продолжайте мониторинг']
      };
    }
  }
}
