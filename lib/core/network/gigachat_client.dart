import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import 'gigachat_exception.dart';
import 'ssl_context.dart';

const _uuid = Uuid();

/// Клиент GigaChat API.
///
/// Возможности:
/// - OAuth2 client_credentials через Auth Key (Basic).
/// - Авто-обновление access_token (TTL ~30 минут).
/// - Чат-комплишн (sync) и стрим (SSE).
/// - SSL pinning к Минцифре через [MintsifryTrust].
class GigaChatClient {
  GigaChatClient._(this._oauthDio, this._apiDio);

  final Dio _oauthDio;
  final Dio _apiDio;

  String? _accessToken;
  DateTime? _expiresAt;
  Completer<String>? _refreshCompleter;

  static Future<GigaChatClient> create() async {
    final httpClient = await MintsifryTrust.buildHttpClient();

    Dio buildDio(String baseUrl, Map<String, String> headers, Duration recv) {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: recv,
        headers: headers,
      ));
      dio.httpClientAdapter = IOHttpClientAdapter()
        ..createHttpClient = () => httpClient;
      return dio;
    }

    final oauthDio = buildDio(
      AppConfig.gigaChatOauthUrl,
      const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      const Duration(seconds: 30),
    );
    final apiDio = buildDio(
      AppConfig.gigaChatApiBase,
      const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      const Duration(seconds: 60),
    );

    return GigaChatClient._(oauthDio, apiDio);
  }

  /// Получить актуальный access_token (с авто-рефрешем).
  Future<String> ensureAccessToken() async {
    final now = DateTime.now();
    if (_accessToken != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(const Duration(seconds: 30)))) {
      return _accessToken!;
    }
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<String>();
    _refreshCompleter = completer;
    try {
      final token = await _fetchAccessToken();
      _accessToken = token;
      completer.complete(token);
      return token;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<String> _fetchAccessToken() async {
    try {
      final response = await _oauthDio.post<Map<String, dynamic>>(
        '',
        data: 'scope=${AppConfig.gigaChatScope}',
        options: Options(
          headers: {
            'Authorization': 'Basic ${AppConfig.gigaChatAuthKey}',
            'RqUID': _uuid.v4(),
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        throw GigaChatException('OAuth: пустой ответ', statusCode: response.statusCode);
      }
      final token = data['access_token'] as String?;
      final expiresAt = data['expires_at'];
      if (token == null) {
        throw GigaChatException('OAuth: нет access_token', statusCode: response.statusCode);
      }
      if (expiresAt is int) {
        _expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAt);
      } else if (expiresAt is String) {
        _expiresAt = DateTime.tryParse(expiresAt) ??
            DateTime.now().add(const Duration(minutes: 25));
      } else {
        _expiresAt = DateTime.now().add(const Duration(minutes: 25));
      }
      return token;
    } on DioException catch (e) {
      throw GigaChatException(
        'OAuth не удался: ${_explainDioError(e)}',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    } on SocketException catch (e) {
      throw GigaChatException('Нет сети: ${e.message}', cause: e);
    } catch (e) {
      throw GigaChatException('OAuth исключение: $e', cause: e);
    }
  }

  /// Не-стримовый чат-комплишн.
  Future<String> completion({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 1024,
    String? model,
  }) async {
    Future<Response<Map<String, dynamic>>> doCall(String token) {
      return _apiDio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': model ?? AppConfig.gigaChatModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    }

    try {
      var token = await ensureAccessToken();
      Response<Map<String, dynamic>> response;
      try {
        response = await doCall(token);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          _accessToken = null;
          _expiresAt = null;
          token = await ensureAccessToken();
          response = await doCall(token);
        } else {
          rethrow;
        }
      }
      final body = response.data;
      if (body == null) {
        throw GigaChatException('Пустой ответ', statusCode: response.statusCode);
      }
      final choices = body['choices'];
      if (choices is! List || choices.isEmpty) {
        throw GigaChatException('choices отсутствуют', statusCode: response.statusCode);
      }
      final messageObj =
          (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = messageObj?['content'] as String?;
      if (content == null) {
        throw GigaChatException('content пустой', statusCode: response.statusCode);
      }
      return content.trim();
    } on DioException catch (e) {
      throw GigaChatException(
        'Ошибка чат-запроса: ${_explainDioError(e)}',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    } on SocketException catch (e) {
      throw GigaChatException('Нет сети: ${e.message}', cause: e);
    } catch (e) {
      if (e is GigaChatException) rethrow;
      throw GigaChatException('Чат исключение: $e', cause: e);
    }
  }

  /// SSE стрим чат-комплишна. Возвращает [Stream] кусочков текста.
  Stream<String> streamCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 1024,
    String? model,
  }) async* {
    final token = await ensureAccessToken();
    try {
      final response = await _apiDio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': model ?? AppConfig.gigaChatModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final body = response.data;
      if (body == null) {
        throw GigaChatException('Пустой стрим', statusCode: response.statusCode);
      }
      final buffer = StringBuffer();
      await for (final chunk in body.stream) {
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        while (true) {
          final raw = buffer.toString();
          final separatorIndex = raw.indexOf('\n\n');
          if (separatorIndex < 0) break;
          final event = raw.substring(0, separatorIndex);
          final remainder = raw.substring(separatorIndex + 2);
          buffer
            ..clear()
            ..write(remainder);
          for (final line in event.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
            final payload = trimmed.substring(5).trim();
            if (payload == '[DONE]') return;
            try {
              final decoded = jsonDecode(payload) as Map<String, dynamic>;
              final choices = decoded['choices'] as List?;
              if (choices == null || choices.isEmpty) continue;
              final delta = (choices.first as Map<String, dynamic>)['delta']
                  as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {
              // битый chunk — игнорируем
            }
          }
        }
      }
    } on DioException catch (e) {
      throw GigaChatException(
        'Стрим упал: ${_explainDioError(e)}',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    } on SocketException catch (e) {
      throw GigaChatException('Нет сети: ${e.message}', cause: e);
    }
  }

  String _explainDioError(DioException e) {
    final type = e.type;
    final status = e.response?.statusCode;
    if (status == 401) return 'Не авторизован (Auth Key/scope)';
    if (status == 429) return 'Превышен лимит запросов';
    if (status == 503) return 'Сервис недоступен';
    return e.message ?? type.toString();
  }
}
