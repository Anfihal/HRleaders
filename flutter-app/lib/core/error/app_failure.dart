enum FailureKind {
  validation,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  unavailable,
  unsupported,
  malformed,
}

/// Pure application error. Server text is diagnostic; UI translates [kind].
class AppFailure implements Exception {
  const AppFailure(
    this.kind,
    this.code, {
    this.fields = const {},
    this.statusCode,
  });
  final FailureKind kind;
  final String code;
  final Map<String, String> fields;
  final int? statusCode;
  @override
  String toString() => 'AppFailure($kind, $code)';
}
