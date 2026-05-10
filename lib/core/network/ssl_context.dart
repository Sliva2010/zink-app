import 'dart:io';

import 'package:flutter/services.dart';

/// Сборка [SecurityContext] с корневыми сертификатами Минцифры РФ.
///
/// GigaChat API доступен только через сертификаты Russian Trusted Root CA /
/// Russian Trusted Sub CA. Эти CA не входят в стандартный trust store Android
/// и iOS, поэтому встраиваем их вручную.
class MintsifryTrust {
  MintsifryTrust._();

  static const List<String> _assetPaths = [
    'assets/certificates/russian_trusted_root_ca.pem',
    'assets/certificates/russian_trusted_sub_ca.pem',
  ];

  /// Возвращает [SecurityContext], дополнивший дефолтный системный список
  /// сертификатами Минцифры.
  static Future<SecurityContext> build() async {
    final context = SecurityContext(withTrustedRoots: true);
    for (final assetPath in _assetPaths) {
      try {
        final bytes = await rootBundle.load(assetPath);
        context.setTrustedCertificatesBytes(bytes.buffer.asUint8List());
      } catch (e) {
        // Сертификат уже добавлен или формат не подошёл — пропускаем без падения.
        // На некоторых платформах повторный setTrustedCertificatesBytes
        // выбрасывает TlsException — это нормально, всё равно идём дальше.
      }
    }
    return context;
  }

  /// Готовый [HttpClient] с подмешанным контекстом Минцифры.
  static Future<HttpClient> buildHttpClient({
    Duration connectionTimeout = const Duration(seconds: 20),
  }) async {
    final context = await build();
    final client = HttpClient(context: context)
      ..connectionTimeout = connectionTimeout
      ..idleTimeout = const Duration(seconds: 20)
      ..userAgent = 'ZINK/1.0 (Android; Flutter)';
    return client;
  }
}
