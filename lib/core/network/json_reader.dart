import '../error/app_failure.dart';

/// JSON is confined to data/network boundaries; no untyped maps reach UI.
final class JsonReader {
  JsonReader(Object? value) : data = _object(value);
  final Map<String, Object?> data;
  static Map<String, Object?> _object(Object? value) {
    if (value is! Map<String, Object?>) _malformed();
    return value;
  }

  static Never _malformed() =>
      throw const AppFailure(FailureKind.malformed, 'invalid_contract');
  String string(String key) =>
      data[key] is String ? data[key]! as String : _malformed();
  String? optionalString(String key) => data[key] == null ? null : string(key);
  int integer(String key) =>
      data[key] is int ? data[key]! as int : _malformed();
  int? optionalInteger(String key) => data[key] == null ? null : integer(key);
  double decimal(String key) =>
      data[key] is num ? (data[key]! as num).toDouble() : _malformed();
  double? optionalDecimal(String key) =>
      data[key] == null ? null : decimal(key);
  bool boolean(String key, {bool? fallback}) =>
      data[key] is bool ? data[key]! as bool : fallback ?? _malformed();
  List<Object?> list(String key) =>
      data[key] is List<Object?> ? data[key]! as List<Object?> : _malformed();
  List<String> strings(String key) =>
      list(key).map((v) => v is String ? v : _malformed()).toList();
  JsonReader object(String key) => JsonReader(data[key]);
  DateTime date(String key) => DateTime.tryParse(string(key)) ?? _malformed();
  DateTime? optionalDate(String key) => data[key] == null ? null : date(key);
  T enumeration<T extends Enum>(String key, List<T> values) =>
      values.where((value) => value.name == string(key)).firstOrNull ??
      _malformed();
  T? optionalEnum<T extends Enum>(String key, List<T> values) =>
      data[key] == null ? null : enumeration(key, values);
}

List<T> decodeList<T>(Object? value, T Function(Object?) decode) {
  if (value is! List<Object?>) {
    throw const AppFailure(FailureKind.malformed, 'expected_list');
  }
  return value.map(decode).toList(growable: false);
}
