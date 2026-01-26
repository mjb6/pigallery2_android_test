import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner;
  final int _maxBodyLength;
  LoggingClient(this._inner, {int maxBodyLength = 1024}) : _maxBodyLength = maxBodyLength;

  static String _redactHeaders(Map<String, String> headers) {
    final sanitized = {...headers};
    for (final k in ['cookie', 'set-cookie', 'csrf-token', 'authorization']) {
      if (sanitized.keys.any((h) => h.toLowerCase() == k)) {
        sanitized.update(sanitized.keys.firstWhere((h) => h.toLowerCase() == k), (_) => '<REDACTED>');
      }
    }
    return sanitized.toString();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) return _inner.send(request);

    final sw = Stopwatch()..start();
    try {
      developer.log('HTTP → ${request.method} ${request.url}', name: 'api');
      developer.log('Headers: ${_redactHeaders(request.headers)}', name: 'api');

      if (request is http.Request && request.body.isNotEmpty) {
        final preview = request.body.length > _maxBodyLength ? '${request.body.substring(0, _maxBodyLength)}...' : request.body;
        developer.log('Request body: $preview', name: 'api');
      }

      final streamed = await _inner.send(request);
      final response = await http.Response.fromStream(streamed);
      sw.stop();

      final contentType = response.headers['content-type'] ?? '';
      String bodyPreview = '';
      if (contentType.contains('application/json') || contentType.contains('text/')) {
        final body = response.body;
        bodyPreview = body.length > _maxBodyLength ? '${body.substring(0, _maxBodyLength)}...' : body;
      } else {
        bodyPreview = '<non-text (${response.headers['content-type'] ?? 'unknown'})>';
      }

      developer.log('HTTP ← ${request.method} ${request.url} [${response.statusCode}] (${sw.elapsedMilliseconds}ms)', name: 'api');
      developer.log('Response headers: ${response.headers}', name: 'api');
      developer.log('Response body: $bodyPreview', name: 'api');

      // rebuild a StreamedResponse from response bytes so callers get normal behavior
      return http.StreamedResponse(
        Stream.fromIterable([response.bodyBytes]),
        response.statusCode,
        request: request,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        contentLength: response.contentLength,
      );
    } catch (e, st) {
      sw.stop();
      developer.log('HTTP ERROR ${request.method} ${request.url}: $e', name: 'api', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}