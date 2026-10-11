import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/app_failure.dart';

abstract interface class ApiClient {
  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  });
}

final class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUri,
    required this.client,
    required this.token,
    this.onUnauthorized,
    this.trace,
    this.requestTimeout = const Duration(seconds: 15),
  });
  final Uri baseUri;
  final http.Client client;
  final String? Function() token;
  void Function()? onUnauthorized;

  /// Optional debug trace intentionally excludes headers, bodies and PII.
  final void Function(String)? trace;
  final Duration requestTimeout;
  int _requestId = 0;

  @override
  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    final uri = baseUri.resolve(path).replace(queryParameters: query);
    final requestId =
        'hrleaders-${DateTime.now().microsecondsSinceEpoch}-${++_requestId}';
    for (var attempt = 0; attempt < (method == 'GET' ? 2 : 1); attempt++) {
      try {
        final accessToken = token();
        final request = http.Request(method, uri)
          ..headers.addAll({
            'Accept': 'application/json',
            'X-Request-ID': requestId,
            if (body != null) 'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          });
        if (body != null) request.body = jsonEncode(body);
        // Bound sending AND reading the response body. Mutations are never retried.
        final response = await (() async => http.Response.fromStream(
          await client.send(request),
        ))().timeout(requestTimeout);
        trace?.call(
          '$requestId $method ${response.statusCode} attempt=$attempt',
        );
        if (method == 'GET' && response.statusCode >= 502 && attempt == 0) {
          continue;
        }
        if (response.statusCode == 401 &&
            path != 'auth/login' &&
            path != 'auth/register') {
          onUnauthorized?.call();
        }
        Object? decoded;
        if (response.body.isNotEmpty) {
          try {
            decoded = jsonDecode(response.body);
          } on FormatException {
            if (response.statusCode >= 400) {
              throw _statusFailure(response.statusCode);
            }
            throw AppFailure(
              FailureKind.malformed,
              'invalid_json',
              statusCode: response.statusCode,
            );
          }
        }
        if (response.statusCode >= 400) {
          final fallback = _statusFailure(response.statusCode);
          throw _decodeFailure(decoded, fallback);
        }
        return decoded;
      } on TimeoutException {
        if (method == 'GET' && attempt == 0) continue;
        throw const AppFailure(FailureKind.unavailable, 'timeout');
      } on http.ClientException {
        if (method == 'GET' && attempt == 0) continue;
        throw const AppFailure(FailureKind.unavailable, 'network_unavailable');
      }
    }
    throw const AppFailure(FailureKind.unavailable, 'network_unavailable');
  }

  AppFailure _statusFailure(int status) => AppFailure(
    switch (status) {
      401 => FailureKind.unauthenticated,
      403 => FailureKind.forbidden,
      404 => FailureKind.notFound,
      409 => FailureKind.conflict,
      400 || 422 => FailureKind.validation,
      _ => FailureKind.unavailable,
    },
    'http_$status',
    statusCode: status,
  );

  AppFailure _decodeFailure(Object? decoded, AppFailure fallback) {
    if (decoded is! Map<String, Object?>) return fallback;
    final fields = <String, String>{};
    final error = decoded['error'];
    var code = fallback.code;
    if (error is Map<String, Object?>) {
      final value = error['code'];
      if (value is String) code = value;
      final details = error['details'];
      if (details is Map<String, Object?>) {
        final fieldDetails = details['fields'];
        if (fieldDetails is List<Object?>) {
          for (final item in fieldDetails) {
            if (item is Map<String, Object?> &&
                item['field'] is String &&
                item['message'] is String) {
              fields[item['field']! as String] = item['message']! as String;
            }
          }
        } else if (fieldDetails is Map<String, Object?>) {
          for (final entry in fieldDetails.entries) {
            if (entry.value is String) {
              fields[entry.key] = entry.value! as String;
            }
          }
        }
      }
    }

    final validationDetails = decoded['detail'];
    if (validationDetails is List<Object?>) {
      code = 'validation_error';
      for (final item in validationDetails) {
        if (item is! Map<String, Object?> ||
            item['msg'] is! String ||
            item['loc'] is! List<Object?>) {
          continue;
        }
        final location = (item['loc']! as List<Object?>)
            .where((part) => part != 'body')
            .map((part) => part.toString())
            .join('.');
        if (location.isNotEmpty) {
          fields[location] = item['msg']! as String;
        }
      }
    }
    return AppFailure(
      fallback.kind,
      code,
      fields: Map.unmodifiable(fields),
      statusCode: fallback.statusCode,
    );
  }

  void close() => client.close();
}
