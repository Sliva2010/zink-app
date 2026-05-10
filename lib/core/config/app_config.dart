/// Глобальная конфигурация приложения ZINK.
///
/// Значения берутся из `--dart-define` при сборке. Дефолты безопасны для
/// дев-сборки, но в продакшене Auth Key должен прокидываться через CI.
class AppConfig {
  AppConfig._();

  /// Версия и брендинг
  static const String appName = 'ZINK';
  static const String appTagline = 'персональный ИИ-репетитор';

  /// GigaChat API
  ///
  /// Auth Key — это base64(ClientID:ClientSecret).
  /// Перенесён в --dart-define, дефолт оставлен для локального запуска.
  static const String gigaChatAuthKey = String.fromEnvironment(
    'GIGACHAT_AUTH_KEY',
    defaultValue:
        'MDE5YjViYjgtNWIxNC03MjBmLWEwNTctY2E5NjM3ZTdjZTY5OjAxYWEwODNiLTlkZDgtNGMwMi1hMTZiLTVkNmEyY2ExNzVlOQ==',
  );

  static const String gigaChatClientId = String.fromEnvironment(
    'GIGACHAT_CLIENT_ID',
    defaultValue: '019b5bb8-5b14-720f-a057-ca9637e7ce69',
  );

  /// Scope: GIGACHAT_API_PERS — для физлица. Для юр-лица — GIGACHAT_API_CORP.
  static const String gigaChatScope = String.fromEnvironment(
    'GIGACHAT_SCOPE',
    defaultValue: 'GIGACHAT_API_PERS',
  );

  /// Базовая модель GigaChat:Lite доступна как просто "GigaChat".
  static const String gigaChatModel = String.fromEnvironment(
    'GIGACHAT_MODEL',
    defaultValue: 'GigaChat',
  );

  static const String gigaChatOauthUrl =
      'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';

  static const String gigaChatApiBase =
      'https://gigachat.devices.sberbank.ru/api/v1';

  /// Геймификация
  static const int xpPerQuestion = 8;
  static const int xpPerCardReview = 4;
  static const int xpPerQuizCorrect = 12;
  static const int xpPerOcrScan = 15;
  static const int xpPerStreakDay = 20;

  /// Daily goal: вопросов в день базово
  static const int baseDailyGoal = 5;

  /// Лимиты, чтобы беречь память на слабых устройствах
  static const int chatHistoryInMemoryLimit = 80;
  static const int offlineCacheSize = 60;
}
