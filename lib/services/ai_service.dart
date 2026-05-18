import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/patient.dart';

class AIService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }

  /// Чат с ИИ-консультантом через Backend API
  static Future<String> chatWithAI(String message, int patientId, {bool isDoctor = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/chat'),
        body: jsonEncode({
          'message': message,
          'patientId': patientId,
          'isDoctor': isDoctor,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'Не удалось получить ответ.';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('AI Server Error: ${errorData['error']}');
        return 'Сервер ИИ вернул ошибку. Попробуйте позже.';
      }
    } catch (e) {
      debugPrint('AI Connection Error: $e');
      return 'Ошибка связи с сервером ИИ. Убедитесь, что сервер запущен и доступен.';
    }
  }

  /// Вспомогательный метод для расчета числового веса текста (остается на клиенте для мгновенной оценки)
  static double _calculateRawScore(String text) {
    if (text.isEmpty) return 0.0;
    final normalizedText = text.toLowerCase();

    final Map<String, double> positiveScores = {
      'хорошо': 1.0, 'отлично': 2.0, 'лучше': 1.5, 'спокойно': 1.0,
      'рад': 1.5, 'счастлив': 2.0, 'прогресс': 2.0, 'бодрость': 1.5,
      'выспался': 1.5, 'уверенно': 1.2, 'легче': 1.2, 'улыбка': 1.0,
      'доволен': 1.5, 'приятно': 1.0, 'здорово': 1.8, 'спасибо': 1.0,
      'надежда': 1.5, 'радость': 1.5, 'успех': 1.5, 'прекрасно': 2.0,
      'великолепно': 2.0, 'замечательно': 1.8, 'выздоравливаю': 1.8,
      'восстановление': 1.5, 'энергия': 1.3, 'сила': 1.2, 'облегчение': 1.4,
      'оптимизм': 1.5, 'светло': 1.0, 'уютно': 1.0, 'спокойствие': 1.2,
      'любовь': 1.8, 'поддержка': 1.5, 'забота': 1.5, 'вместе': 1.0,
      'понимание': 1.5, 'помощь': 1.0, 'родные': 1.0, 'семья': 0.5,
      'обнимали': 1.5, 'ценили': 1.2, 'родственники': 0.5, 'близкие': 1.0,
      'примирение': 1.7, 'согласие': 1.4, 'доверие': 1.6, 'верность': 1.5,
    };

    final Map<String, double> negativeScores = {
      'плохо': -1.5, 'грустно': -1.2, 'боль': -2.0, 'ужасно': -2.5,
      'депрессия': -3.0, 'тревога': -2.5, 'устал': -1.0, 'болит': -2.0,
      'страх': -2.0, 'тяжело': -1.5, 'бессонница': -2.0, 'кошмар': -2.5,
      'паника': -3.0, 'слабость': -1.5, 'злой': -1.8, 'раздражает': -1.8,
      'немощь': -2.0, 'обидно': -1.2, 'одиноко': -1.5, 'тоска': -1.8,
      'печаль': -1.2, 'отчаяние': -2.8, 'безнадежность': -2.8, 'апатия': -2.2,
      'уныние': -1.5, 'раздражение': -1.5, 'гнев': -2.0, 'ярость': -2.5,
      'стресс': -1.8, 'давление': -1.2, 'тошнота': -1.5, 'головокружение': -1.5,
      'ломота': -1.5, 'зуд': -1.0, 'онемение': -1.2,
      'ссора': -1.8, 'конфликт': -2.0, 'развод': -2.5, 'предательство': -3.0,
      'крик': -1.5, 'ругаемся': -1.8, 'непонимание': -1.5, 'бросили': -2.0,
      'измена': -2.5, 'один': -1.0, 'ненужный': -1.8, 'отвергнут': -2.0,
      'одиночество': -1.8, 'вражда': -2.2, 'ненависть': -2.5, 'обида': -1.3,
      'упрек': -1.2, 'скандал': -2.0, 'холодность': -1.5,
    };

    final Map<String, double> criticalScores = {
      'суицид': -10.0, 'убить': -10.0, 'убью': -10.0, 'убийство': -10.0,
      'смерть': -8.0, 'умру': -8.0, 'покончить': -10.0, 'вскрыть': -10.0,
      'повешусь': -10.0, 'зарезать': -10.0, 'отравиться': -10.0, 'мстить': -7.0,
      'пристрелить': -10.0, 'удушить': -10.0, 'нож': -3.0, 'яд': -3.0,
      'удавиться': -10.0, 'задушить': -10.0, 'расправа': -9.0, 'казнить': -8.0,
      'прирезать': -10.0, 'взорвать': -10.0, 'выброситься': -10.0, 'окно': -3.0,
      'петля': -5.0, 'пуля': -4.0, 'оружие': -3.0, 'кровать': -1.0, 'вены': -6.0,
      'таблетки': -2.0, 'передозировка': -7.0, 'кровь': -3.0,
    };

    final Map<String, double> intensifiers = {
      'очень': 1.5, 'крайне': 2.0, 'совсем': 1.8, 'абсолютно': 2.0,
      'немного': 0.5, 'чуть': 0.5, 'еле': 0.7, 'чертовски': 1.8,
      'ужасно': 1.5, 'невероятно': 2.0, 'сильно': 1.4, 'слегка': 0.6,
    };

    double totalScore = 0;
    final words = normalizedText.split(RegExp(r'[\s,.;!?]+'));

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      double multiplier = 1.0;
      bool isNegated = false;

      if (i > 0) {
        if (words[i - 1] == 'не' || words[i - 1] == 'ни') {
          isNegated = true;
        }
        if (intensifiers.containsKey(words[i - 1])) {
          multiplier = intensifiers[words[i - 1]]!;
        }
      }

      if (positiveScores.containsKey(word)) {
        double score = positiveScores[word]! * multiplier;
        totalScore += isNegated ? -score : score;
      } else if (negativeScores.containsKey(word)) {
        double score = negativeScores[word]! * multiplier;
        totalScore += isNegated ? -score : score;
      } else if (criticalScores.containsKey(word)) {
        double score = criticalScores[word]! * multiplier;
        totalScore += isNegated ? score * 0.5 : score;
      }
    }
    return totalScore;
  }

  /// Расширенный анализ тональности текста для русского языка
  static String analyzeSentiment(String text) {
    if (text.isEmpty) return 'Neutral';
    
    // Проверка на критические маркеры отдельно для точного срабатывания
    final normalized = text.toLowerCase();
    final criticalKeywords = ['суицид', 'убить', 'убью', 'смерть', 'умру', 'покончить', 'вскрыть', 'повешусь', 'удавиться', 'вены'];
    if (criticalKeywords.any((k) => normalized.contains(k))) return 'CRITICAL';

    double totalScore = _calculateRawScore(text);

    if (totalScore < -5.0) return 'CRITICAL';
    if (totalScore > 0.5) return 'Positive';
    if (totalScore < -0.5) return 'Negative';
    return 'Neutral';
  }

  /// Расчет оценки настроения (1-5) на основе анализа текста
  static int calculateMoodScore(String text) {
    if (text.isEmpty) return 3; // По умолчанию нейтрально

    final sentiment = analyzeSentiment(text);
    if (sentiment == 'CRITICAL') return 1;
    
    double raw = _calculateRawScore(text);
    
    if (raw >= 2.0) return 5;
    if (raw > 0.5) return 4;
    if (raw >= -0.5) return 3;
    if (raw > -2.0) return 2;
    return 1;
  }

  /// Проверка критического давления
  static String? checkCriticalPressureFromMeasurements(List<Measurement> measurements) {
    if (measurements.isEmpty) return null;

    final lastMeasurement = measurements.last;
    final systolic = lastMeasurement.pressureSystolic;
    final diastolic = lastMeasurement.pressureDiastolic;

    if (systolic >= 180 || diastolic >= 120) {
      return '🔴 КРИТИЧЕСКИ ОПАСНО: Очень высокое давление (${systolic.toInt()}/${diastolic.toInt()})! НЕМЕДЛЕННО вызовите скорую помощь (103) или обратитесь в приемный покой!';
    }

    if (systolic >= 160 || diastolic >= 100) {
      return '⚠️ ОПАСНО: Давление критически высокое (${systolic.toInt()}/${diastolic.toInt()}). Требуется срочная консультация врача. Примите прописанные лекарства, обеспечьте покой.';
    }

    if (systolic < 70 || diastolic < 40) {
      return '🔴 КРИТИЧЕСКИ ОПАСНО: Экстремально низкое давление (${systolic.toInt()}/${diastolic.toInt()})! НЕМЕДЛЕННО вызовите скорую помощь (103)! Обморок может наступить в любой момент.';
    }

    if (systolic < 90 || diastolic < 60) {
      return '⚠️ ОПАСНО: Низкое давление (${systolic.toInt()}/${diastolic.toInt()}). Возможны головокружение и слабость. Пейте больше воды, избегайте резких движений.';
    }

    return null;
  }

  /// Система рекомендаций
  static List<String> getRecommendations(Patient patient, List<Diagnosis> diagnoses, List<Measurement> measurements) {
    List<String> recommendations = [];
    bool hasPtsd = diagnoses.any((d) => d.description.toLowerCase().contains('птср'));

    final criticalPressure = checkCriticalPressureFromMeasurements(measurements);
    if (criticalPressure != null) {
      recommendations.add('🚨 СРОЧНО: $criticalPressure');
      return recommendations;
    }

    if (hasPtsd) {
      recommendations.add('🧠 Групповая арт-терапия');
      recommendations.add('📊 Сеанс биологической обратной связи (БОС)');
      recommendations.add('💭 Когнитивно-поведенческая терапия');
    } else {
      recommendations.add('🏃 Общий курс ЛФК');
      recommendations.add('💆 Массаж воротниковой зоны');
      recommendations.add('🏊 Плавание');
    }

    if (measurements.isNotEmpty) {
      final last = measurements.last;
      if (last.pressureSystolic > 140 || last.pressureDiastolic > 90) {
        recommendations.add('⚠️ Повышенное давление: ограничьте соль, больше отдыхайте');
      } else if (last.pressureSystolic < 100 || last.pressureDiastolic < 60) {
        recommendations.add('💧 Пониженное давление: пейте больше воды, можно кофеин (если нет противопоказаний)');
      }

      if (last.pulse > 100) {
        recommendations.add('❤️ Учащенный пульс: практикуйте дыхательные упражнения');
      } else if (last.pulse < 60 && last.pulse > 0) {
        recommendations.add('💓 Замедленный пульс: проконсультируйтесь с кардиологом');
      }
    }

    return recommendations;
  }

  /// Анализ тренда физических показателей
  static String analyzeTrend(List<Measurement> measurements) {
    if (measurements.isEmpty) return 'Недостаточно данных для анализа';
    if (measurements.length < 3) return 'Данные собираются...';

    final last = measurements.last;
    final first = measurements.first;

    final criticalPressure = checkCriticalPressureFromMeasurements(measurements);
    if (criticalPressure != null) {
      return criticalPressure;
    }

    final systolicDiff = last.pressureSystolic - first.pressureSystolic;
    final diastolicDiff = last.pressureDiastolic - first.pressureDiastolic;

    if (systolicDiff.abs() < 5 && diastolicDiff.abs() < 5) {
      return '📊 Давление стабильно. Терапия эффективна.';
    } else if (systolicDiff < -5 && diastolicDiff < -5) {
      return '📉 Положительная динамика: давление снижается на ${systolicDiff.abs().toInt()}/${diastolicDiff.abs().toInt()} мм рт.ст.';
    } else if (systolicDiff > 5 && diastolicDiff > 5) {
      return '📈 Давление повышается: +${systolicDiff.toInt()}/${diastolicDiff.toInt()}. Требуется коррекция лечения.';
    }

    return 'Следим за динамикой...';
  }

  /// Анализ на основе всех данных
  static String analyzeFullHealthStatus(List<Measurement> measurements, List<MoodEntry> moods) {
    if (measurements.isEmpty && moods.isEmpty) {
      return 'Недостаточно данных для оценки состояния. Добавьте замеры давления и записи в дневник.';
    }

    final pressureAnalysis = analyzeTrend(measurements);
    if (pressureAnalysis.contains('КРИТИЧЕСКИ') || pressureAnalysis.contains('ОПАСНО')) {
      return pressureAnalysis;
    }

    if (moods.isNotEmpty) {
      final recentMoods = moods.reversed.take(5).toList();
      final avgMood = recentMoods.map((m) => m.score).reduce((a, b) => a + b) / recentMoods.length;

      if (avgMood < 2.5) {
        return '😔 Эмоциональное состояние требует внимания. $pressureAnalysis Рекомендуется психологическая поддержка.';
      } else if (avgMood > 4) {
        return '😊 Отличное эмоциональное состояние! $pressureAnalysis';
      }
    }

    return pressureAnalysis;
  }
}
