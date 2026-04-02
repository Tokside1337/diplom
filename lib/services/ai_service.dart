import '../models/medical_models.dart';
import '../models/patient.dart';

class AIService {
  // Имитация анализа тональности текста (Sentiment Analysis)
  // В реальном приложении здесь был бы вызов API или TFLite модели
  static String analyzeSentiment(String text) {
    text = text.toLowerCase();
    final negativeWords = ['плохо', 'грустно', 'боль', 'ужасно', 'депрессия', 'тревога', 'устал'];
    final positiveWords = ['хорошо', 'отлично', 'рад', 'счастлив', 'лучше', 'спокойно'];

    int score = 0;
    for (var word in negativeWords) {
      if (text.contains(word)) score--;
    }
    for (var word in positiveWords) {
      if (text.contains(word)) score++;
    }

    if (score < 0) return 'Negative';
    if (score > 0) return 'Positive';
    return 'Neutral';
  }

  // Имитация системы рекомендаций (Collaborative Filtering / Apriori)
  static List<String> getRecommendations(Patient patient, List<Diagnosis> diagnoses) {
    // В реальности: поиск похожих пациентов в БД и выбор их успешных процедур
    List<String> recommendations = [];
    
    bool hasPtsd = diagnoses.any((d) => d.description.toLowerCase().contains('птср'));
    
    if (hasPtsd) {
      recommendations.add('Групповая арт-терапия');
      recommendations.add('Сеанс биологической обратной связи (БОС)');
    } else {
      recommendations.add('Общий курс ЛФК');
      recommendations.add('Массаж воротниковой зоны');
    }
    
    return recommendations;
  }

  // Анализ динамики показателей
  static String analyzeTrend(List<Measurement> measurements) {
    if (measurements.length < 2) return 'Недостаточно данных';
    
    double last = measurements.first.pressureSystolic;
    double prev = measurements[1].pressureSystolic;
    
    if (last < prev - 5) return 'Улучшение (снижение давления)';
    if (last > prev + 5) return 'Внимание: Рост давления';
    return 'Стабильное состояние';
  }
}
