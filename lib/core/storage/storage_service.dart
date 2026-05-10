import 'package:hive_flutter/hive_flutter.dart';

/// Единая точка доступа к локальному хранилищу.
///
/// Используется Hive (быстрый, NoSQL, файл-бэкенд). Все модели сериализуются
/// в Map<String, dynamic>, что избавляет от кодогенерации.
class StorageService {
  StorageService._();

  static const String userBoxName = 'zink_user';
  static const String chatsBoxName = 'zink_chats';
  static const String notesBoxName = 'zink_notes';
  static const String cardsBoxName = 'zink_cards';
  static const String quizzesBoxName = 'zink_quizzes';
  static const String mindMapsBoxName = 'zink_mindmaps';
  static const String progressBoxName = 'zink_progress';
  static const String achievementsBoxName = 'zink_achievements';
  static const String settingsBoxName = 'zink_settings';
  static const String aiCacheBoxName = 'zink_ai_cache';
  static const String pendingBoxName = 'zink_pending';

  static late final Box<dynamic> _user;
  static late final Box<dynamic> _chats;
  static late final Box<dynamic> _notes;
  static late final Box<dynamic> _cards;
  static late final Box<dynamic> _quizzes;
  static late final Box<dynamic> _mindMaps;
  static late final Box<dynamic> _progress;
  static late final Box<dynamic> _achievements;
  static late final Box<dynamic> _settings;
  static late final Box<dynamic> _aiCache;
  static late final Box<dynamic> _pending;

  static Future<void> init() async {
    await Hive.initFlutter();
    _user = await Hive.openBox<dynamic>(userBoxName);
    _chats = await Hive.openBox<dynamic>(chatsBoxName);
    _notes = await Hive.openBox<dynamic>(notesBoxName);
    _cards = await Hive.openBox<dynamic>(cardsBoxName);
    _quizzes = await Hive.openBox<dynamic>(quizzesBoxName);
    _mindMaps = await Hive.openBox<dynamic>(mindMapsBoxName);
    _progress = await Hive.openBox<dynamic>(progressBoxName);
    _achievements = await Hive.openBox<dynamic>(achievementsBoxName);
    _settings = await Hive.openBox<dynamic>(settingsBoxName);
    _aiCache = await Hive.openBox<dynamic>(aiCacheBoxName);
    _pending = await Hive.openBox<dynamic>(pendingBoxName);
  }

  static Box<dynamic> get user => _user;
  static Box<dynamic> get chats => _chats;
  static Box<dynamic> get notes => _notes;
  static Box<dynamic> get cards => _cards;
  static Box<dynamic> get quizzes => _quizzes;
  static Box<dynamic> get mindMaps => _mindMaps;
  static Box<dynamic> get progress => _progress;
  static Box<dynamic> get achievements => _achievements;
  static Box<dynamic> get settings => _settings;
  static Box<dynamic> get aiCache => _aiCache;
  static Box<dynamic> get pending => _pending;

  static Future<void> clearAll() async {
    await Future.wait([
      _user.clear(),
      _chats.clear(),
      _notes.clear(),
      _cards.clear(),
      _quizzes.clear(),
      _mindMaps.clear(),
      _progress.clear(),
      _achievements.clear(),
      _aiCache.clear(),
      _pending.clear(),
    ]);
  }
}
