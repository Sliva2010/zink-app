import '../../models/achievement.dart';

/// Каталог достижений ZINK.
class AchievementsCatalog {
  AchievementsCatalog._();

  static const List<Achievement> all = [
    // Вопросы
    Achievement(
      id: 'first_question',
      title: 'Первый шаг',
      description: 'Задайте первый вопрос ИИ-репетитору',
      threshold: 1,
      type: AchievementType.questions,
    ),
    Achievement(
      id: 'curious_mind',
      title: 'Любопытный ум',
      description: '10 вопросов задано',
      threshold: 10,
      type: AchievementType.questions,
    ),
    Achievement(
      id: 'inquisitive',
      title: 'Пытливый ученик',
      description: '50 вопросов задано',
      threshold: 50,
      type: AchievementType.questions,
    ),
    Achievement(
      id: 'knowledge_seeker',
      title: 'Искатель знаний',
      description: '200 вопросов задано',
      threshold: 200,
      type: AchievementType.questions,
    ),

    // Карточки
    Achievement(
      id: 'first_card',
      title: 'Карточный шулер',
      description: 'Первая повторённая карточка',
      threshold: 1,
      type: AchievementType.cardsReviewed,
    ),
    Achievement(
      id: 'cardmaster',
      title: 'Мастер карт',
      description: '100 повторений карточек',
      threshold: 100,
      type: AchievementType.cardsReviewed,
    ),

    // Квизы
    Achievement(
      id: 'first_quiz',
      title: 'Тестируемый',
      description: 'Первый пройденный квиз',
      threshold: 1,
      type: AchievementType.quizzesCompleted,
    ),
    Achievement(
      id: 'quiz_pro',
      title: 'Квиз-про',
      description: '20 пройденных квизов',
      threshold: 20,
      type: AchievementType.quizzesCompleted,
    ),

    // Стрик
    Achievement(
      id: 'three_in_row',
      title: 'Три дня',
      description: 'Стрик 3 дня подряд',
      threshold: 3,
      type: AchievementType.streakDays,
    ),
    Achievement(
      id: 'week_streak',
      title: 'Неделя огня',
      description: 'Стрик 7 дней подряд',
      threshold: 7,
      type: AchievementType.streakDays,
    ),
    Achievement(
      id: 'month_streak',
      title: 'Месяц фокуса',
      description: 'Стрик 30 дней подряд',
      threshold: 30,
      type: AchievementType.streakDays,
    ),

    // XP
    Achievement(
      id: 'xp_100',
      title: 'Старт энергии',
      description: '100 XP заработано',
      threshold: 100,
      type: AchievementType.xpTotal,
    ),
    Achievement(
      id: 'xp_1000',
      title: 'Тысячник',
      description: '1000 XP заработано',
      threshold: 1000,
      type: AchievementType.xpTotal,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'Знаток',
      description: '5000 XP заработано',
      threshold: 5000,
      type: AchievementType.xpTotal,
    ),

    // Заметки
    Achievement(
      id: 'first_note',
      title: 'Первая заметка',
      description: 'Сохранён первый конспект',
      threshold: 1,
      type: AchievementType.notesCreated,
    ),
    Achievement(
      id: 'note_collector',
      title: 'Собиратель',
      description: '25 конспектов сохранено',
      threshold: 25,
      type: AchievementType.notesCreated,
    ),

    // Особые
    Achievement(
      id: 'pdf_export',
      title: 'Хранитель знаний',
      description: 'Экспорт конспекта в PDF',
      threshold: 1,
      type: AchievementType.notesCreated,
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
