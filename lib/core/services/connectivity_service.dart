import 'package:connectivity_plus/connectivity_plus.dart';

/// Проверка наличия сети перед API-запросами.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  /// Возвращает true, если есть хотя бы одно активное соединение.
  static Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true; // при ошибке проверки — не блокируем запрос
    }
  }

  /// Стрим изменений состояния сети.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
