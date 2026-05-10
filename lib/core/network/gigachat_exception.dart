/// Унифицированное исключение GigaChat API.
class GigaChatException implements Exception {
  GigaChatException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final code = statusCode != null ? ' [$statusCode]' : '';
    return 'GigaChatException$code: $message';
  }
}
