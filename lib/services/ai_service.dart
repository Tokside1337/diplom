import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/patient.dart';

/// Базовая конфигурация API для ИИ-сервисов
mixin AIConfig {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  Map<String, String> get headers {
    final h = {'Content-Type': 'application/json'};
    if (AIService.token != null) {
      h['Authorization'] = 'Bearer ${AIService.token}';
    }
    return h;
  }
}

/// Сервис для взаимодействия с удаленным ИИ через бэкенд
class AIService with AIConfig {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static String? token;
  static void setToken(String? t) => token = t;

  /// Чат с ИИ-консультантом
  static Future<String> chatWithAI(String message, int patientId, {bool isDoctor = false}) async {
    final service = AIService();
    try {
      final response = await http.post(
        Uri.parse('${service.baseUrl}/ai/chat'),
        body: jsonEncode({
          'message': message,
          'patientId': patientId,
          'isDoctor': isDoctor,
        }),
        headers: service.headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['text'] ?? 'Не удалось получить ответ.';
      }
      return _handleError(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Получение комплексного анализа здоровья от ИИ
  static Future<Map<String, dynamic>> getAdvancedHealthAnalysis(int patientId) async {
    final service = AIService();
    try {
      final response = await http.post(
        Uri.parse('${service.baseUrl}/ai/analyze-health'),
        body: jsonEncode({'patientId': patientId}),
        headers: service.headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Health Analysis Error: $e');
    }
    return {'summary': 'Не удалось получить анализ от ИИ.', 'recommendations': []};
  }

  /// Получение глубокого анализа настроения
  static Future<Map<String, dynamic>> analyzeMoodWithAI(String text) async {
    final service = AIService();
    try {
      final response = await http.post(
        Uri.parse('${service.baseUrl}/ai/analyze-mood'),
        body: jsonEncode({'text': text}),
        headers: service.headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Mood AI Error: $e');
    }
    
    // Фолбэк на локальный анализ при ошибке сервера
    return {
      'score': MoodAnalyzer.calculateMoodScore(text),
      'sentiment': MoodAnalyzer.analyzeSentiment(text),
      'analysis': 'Локальный анализ (сервер недоступен)'
    };
  }

  static String _handleError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return 'Ошибка сервера: ${data['error'] ?? 'Неизвестная ошибка'}';
    } catch (_) {
      return 'Ошибка связи с серверов ИИ.';
    }
  }

  static String _handleException(dynamic e) {
    debugPrint('AI Exception: $e');
    return 'Ошибка сети. Убедитесь, что сервер запущен.';
  }

  // Методы обратной совместимости для UI, использующие новые анализаторы
  static String analyzeTrend(List<Measurement> measurements) => 
      HealthAnalyzer.analyzeTrend(measurements);

  static List<String> getRecommendations(Patient p, List<Diagnosis> d, List<Measurement> m) =>
      HealthAnalyzer.getRecommendations(p, d, m);

  static int calculateMoodScore(String text) => MoodAnalyzer.calculateMoodScore(text);
  static String analyzeSentiment(String text) => MoodAnalyzer.analyzeSentiment(text);
}

/// Логика анализа физических показателей и медицинских трендов
class HealthAnalyzer {
  static const int systolicHigh = 140;
  static const int diastolicHigh = 90;
  static const int pulseHigh = 100;
  static const int pulseLow = 60;

  static String analyzeTrend(List<Measurement> measurements) {
    if (measurements.isEmpty) return 'Недостаточно данных для анализа';
    
    final critical = _checkCriticalVitals(measurements.last);
    if (critical != null) return critical;

    if (measurements.length < 3) return 'Данные собираются...';

    final last = measurements.last;
    final first = measurements.first;

    final sysDiff = last.pressureSystolic - first.pressureSystolic;
    final diaDiff = last.pressureDiastolic - first.pressureDiastolic;

    if (sysDiff.abs() < 5 && diaDiff.abs() < 5) return '📊 Давление стабильно.';
    if (sysDiff < -5 && diaDiff < -5) return '📉 Положительная динамика: давление снижается.';
    if (sysDiff > 5 && diaDiff > 5) return '📈 Давление повышается. Обратитесь к врачу.';

    return 'Следим за динамикой...';
  }

  static List<String> getRecommendations(Patient patient, List<Diagnosis> diagnoses, List<Measurement> measurements) {
    final recs = <String>[];
    
    if (measurements.isNotEmpty) {
      final critical = _checkCriticalVitals(measurements.last);
      if (critical != null) {
        recs.add('🚨 СРОЧНО: $critical');
        return recs;
      }
      
      final last = measurements.last;
      if (last.pressureSystolic > systolicHigh) recs.add('⚠️ Ограничьте соль и стресс.');
      if (last.pulse > pulseHigh) recs.add('❤️ Практикуйте дыхательную гимнастику.');
    }

    final hasPtsd = diagnoses.any((d) => d.description.toLowerCase().contains('птср'));
    if (hasPtsd) {
      recs.addAll(['🧠 Арт-терапия', '💭 КПТ-сессия']);
    } else {
      recs.add('🏃 Ежедневный курс ЛФК');
    }

    return recs;
  }

  static String? _checkCriticalVitals(Measurement m) {
    if (m.pressureSystolic >= 180 || m.pressureDiastolic >= 120) return 'Критически высокое давление!';
    if (m.pressureSystolic < 70) return 'Критически низкое давление!';
    return null;
  }
}

/// Логика анализа текста и настроения (Client-side fallback)
class MoodAnalyzer {
  static int calculateMoodScore(String text) {
    if (text.isEmpty) return 3;
    final sentiment = analyzeSentiment(text);
    if (sentiment == 'CRITICAL') return 1;
    
    final raw = _calculateRawScore(text);
    if (raw >= 2.0) return 5;
    if (raw > 0.5) return 4;
    if (raw >= -0.5) return 3;
    if (raw > -2.0) return 2;
    return 1;
  }

  static String analyzeSentiment(String text) {
    final normalized = text.toLowerCase();
    final critical = ['суицид', 'убить', 'смерть', 'умру', 'покончить', 'вены'];
    if (critical.any((k) => normalized.contains(k))) return 'CRITICAL';

    final score = _calculateRawScore(text);
    if (score < -5.0) return 'CRITICAL';
    if (score > 0.5) return 'Positive';
    if (score < -0.5) return 'Negative';
    return 'Neutral';
  }

  static double _calculateRawScore(String text) {
    final words = text.toLowerCase().split(RegExp(r'[\s,.;!?]+'));
    double total = 0;

    for (final word in words) {
      total += _scores[word] ?? 0.0;
    }
    return total;
  }

  static const Map<String, double> _scores = {
    'хорошо': 1.0, 'отлично': 2.0, 'лучше': 1.5, 'рад': 1.5, 'счастлив': 2.0,
    'плохо': -1.5, 'грустно': -1.2, 'боль': -2.0, 'ужасно': -2.5, 'болит': -2.0,
    'суицид': -10.0, 'смерть': -8.0, 'убить': -10.0,
  };
}
