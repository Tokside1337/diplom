import 'package:diplom/models/medical_models.dart';
import 'package:diplom/models/patient.dart';

class AIService {
  /// Расширенный анализ тональности текста для русского языка (Rule-based)
  /// Добавлена детекция критических состояний и анализ семейных отношений
  static String analyzeSentiment(String text) {
    if (text.isEmpty) return 'Neutral';
    
    final normalizedText = text.toLowerCase();
    
    // Списки слов с весами
    final Map<String, double> positiveScores = {
      'хорошо': 1.0, 'отлично': 2.0, 'лучше': 1.5, 'спокойно': 1.0, 
      'рад': 1.5, 'счастлив': 2.0, 'прогресс': 2.0, 'бодрость': 1.5,
      'выспался': 1.5, 'уверенно': 1.2, 'легче': 1.2, 'улыбка': 1.0,
      'доволен': 1.5, 'приятно': 1.0, 'здорово': 1.8, 'спасибо': 1.0,
      'надежда': 1.5, 'радость': 1.5, 'успех': 1.5, 'прекрасно': 2.0,
      'великолепно': 2.0, 'замечательно': 1.8, 'выздоравливаю': 1.8,
      'восстановление': 1.5, 'энергия': 1.3, 'сила': 1.2, 'облегчение': 1.4,
      'оптимизм': 1.5, 'светло': 1.0, 'уютно': 1.0, 'спокойствие': 1.2,
      // Семейные позитивные маркеры
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
      // Семейные негативные маркеры
      'ссора': -1.8, 'конфликт': -2.0, 'развод': -2.5, 'предательство': -3.0,
      'крик': -1.5, 'ругаемся': -1.8, 'непонимание': -1.5, 'бросили': -2.0,
      'измена': -2.5, 'один': -1.0, 'ненужный': -1.8, 'отвергнут': -2.0,
      'одиночество': -1.8, 'вражда': -2.2, 'ненависть': -2.5, 'обида': -1.3,
      'упрек': -1.2, 'скандал': -2.0, 'холодность': -1.5,
    };

    // Критические маркеры (мысли об убийстве, суициде, причинении вреда)
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
    bool hasCriticalMarker = false;
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
        if (!isNegated) hasCriticalMarker = true;
      }
    }

    if (hasCriticalMarker || totalScore < -5.0) return 'CRITICAL';
    if (totalScore > 0.5) return 'Positive';
    if (totalScore < -0.5) return 'Negative';
    return 'Neutral';
  }

  /// Система рекомендаций
  static List<String> getRecommendations(Patient patient, List<Diagnosis> diagnoses) {
    List<String> recommendations = [];
    bool hasPtsd = diagnoses.any((d) => d.description.toLowerCase().contains('птср'));
    
    if (hasPtsd) {
      recommendations.add('Групповая арт-терапия');
      recommendations.add('Сеанс биологической обратной связи (БОС)');
      recommendations.add('Когнитивно-поведенческая терапия');
    } else {
      recommendations.add('Общий курс ЛФК');
      recommendations.add('Массаж воротниковой зоны');
      recommendations.add('Плавание');
    }
    return recommendations;
  }

  /// Анализ тренда физических показателей
  static String analyzeTrend(List<Measurement> measurements) {
    if (measurements.length < 2) return 'Недостаточно данных для анализа';
    
    final recent = measurements.take(3).toList();
    double avgRecent = recent.map((m) => m.pressureSystolic).reduce((a, b) => a + b) / recent.length;
    
    if (measurements.length >= 6) {
      final older = measurements.skip(3).take(3).toList();
      double avgOlder = older.map((m) => m.pressureSystolic).reduce((a, b) => a + b) / older.length;
      
      if (avgRecent < avgOlder - 7) return 'Стабильное улучшение';
      if (avgRecent > avgOlder + 7) return 'Тревожная тенденция: Рост показателей';
    }

    double last = measurements.first.pressureSystolic;
    double prev = measurements[1].pressureSystolic;
    
    if (last < prev - 5) return 'Улучшение (снижение давления)';
    if (last > prev + 5) return 'Внимание: Резкий скачок давления';
    
    return 'Состояние стабильно';
  }
}
