// GENERATED from api (2).json by tool/generate_api_contract.py.
// Do not edit by hand; regenerate after changing the OpenAPI contract.

typedef ApiDynamicObject = Map<String, Object?>;

abstract interface class ApiJsonModel {
  String get schemaName;
  Map<String, Object?> toJson();
}

abstract interface class ApiEnumValue {
  String toJson();
}

Map<String, Object?> _apiObject(Object? value) {
  if (value is! Map) throw FormatException('Expected a JSON object');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw FormatException('Expected string object keys');
    result[entry.key as String] = entry.value;
  }
  return result;
}

Object? _apiAny(Object? value) => value;
String _apiString(Object? value) => value is String ? value : throw FormatException('Expected a string');
String _apiUuid(Object? value) {
  final result = _apiString(value);
  if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(result)) {
    throw FormatException('Expected a UUID');
  }
  return result;
}
int _apiInt(Object? value) => value is int ? value : throw FormatException('Expected an integer');
double _apiDouble(Object? value) => value is num ? value.toDouble() : throw FormatException('Expected a number');
bool _apiBool(Object? value) => value is bool ? value : throw FormatException('Expected a boolean');
DateTime _apiDateTime(Object? value) {
  final parsed = DateTime.tryParse(_apiString(value));
  if (parsed == null) throw FormatException('Expected an ISO-8601 date');
  return parsed;
}
DateTime _apiDateOnly(Object? value) {
  final result = _apiString(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result)) throw FormatException('Expected an ISO date');
  final parsed = DateTime.tryParse(result);
  if (parsed == null || parsed.toIso8601String().split('T').first != result) throw FormatException('Expected an ISO date');
  return parsed;
}
String _apiEncodeDate(DateTime value, {required bool dateOnly}) =>
    dateOnly ? value.toIso8601String().split('T').first : value.toIso8601String();
T _apiRequired<T>(Map<String, Object?> json, String key, T Function(Object?) decode) {
  if (!json.containsKey(key) || json[key] == null) throw FormatException('Missing required field: $key');
  return decode(json[key]);
}
T? _apiOptional<T>(Map<String, Object?> json, String key, T Function(Object?) decode) {
  final value = json[key];
  return value == null ? null : decode(value);
}
List<T> _apiList<T>(Object? value, T Function(Object?) decode) {
  if (value is! List) throw FormatException('Expected a JSON array');
  return List<T>.unmodifiable(value.map(decode));
}
Map<String, T> _apiMap<T>(Object? value, T Function(Object?) decode) {
  final json = _apiObject(value);
  return Map<String, T>.unmodifiable(json.map((key, value) => MapEntry(key, decode(value))));
}
Map<String, Object?> _apiExtras(Map<String, Object?> json, Set<String> known) =>
    Map<String, Object?>.unmodifiable(Map.fromEntries(json.entries.where((entry) => !known.contains(entry.key))));
Object? _apiEncode(Object? value) {
  if (value == null || value is String || value is num || value is bool) return value;
  if (value is ApiJsonModel) return value.toJson();
  if (value is ApiEnumValue) return value.toJson();
  if (value is DateTime) return value.toIso8601String();
  if (value is List) return value.map(_apiEncode).toList(growable: false);
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) throw FormatException('Expected string object keys');
      result[entry.key as String] = _apiEncode(entry.value);
    }
    return result;
  }
  throw FormatException('Unsupported JSON value: ${value.runtimeType}');
}
void _apiValidateString(String name, String? value, {int? min, int? max, String? pattern}) {
  if (value == null) return;
  if ((min != null && value.length < min) || (max != null && value.length > max) ||
      (pattern != null && !RegExp(pattern).hasMatch(value))) {
    throw FormatException('Invalid value for $name');
  }
}
void _apiValidateNumber(String name, num? value, {num? min, num? max, num? exclusiveMin, num? exclusiveMax}) {
  if (value == null) return;
  if ((min != null && value < min) || (max != null && value > max) ||
      (exclusiveMin != null && value <= exclusiveMin) ||
      (exclusiveMax != null && value >= exclusiveMax)) {
    throw FormatException('Invalid value for $name');
  }
}
void _apiValidateCount(String name, int? value, {int? min, int? max}) {
  if (value == null) return;
  if ((min != null && value < min) || (max != null && value > max)) {
    throw FormatException('Invalid item count for $name');
  }
}

enum ApiAttemptStatus implements ApiEnumValue {
  in_progress('in_progress'), submitted('submitted'), scored('scored'), expired('expired');
  const ApiAttemptStatus(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiAttemptStatus fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiAttemptStatus: $value'),
  );
}

enum ApiGrade implements ApiEnumValue {
  junior('junior'), middle('middle'), senior('senior'), lead('lead');
  const ApiGrade(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiGrade fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiGrade: $value'),
  );
}

enum ApiGradeChangeReason implements ApiEnumValue {
  test_passed('test_passed'), test_failed('test_failed'), downgrade_requested('downgrade_requested'), upgrade_requested('upgrade_requested');
  const ApiGradeChangeReason(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiGradeChangeReason fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiGradeChangeReason: $value'),
  );
}

enum ApiOfferStatus implements ApiEnumValue {
  sent('sent'), viewed('viewed'), accepted('accepted'), declined('declined'), withdrawn('withdrawn');
  const ApiOfferStatus(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiOfferStatus fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiOfferStatus: $value'),
  );
}

enum ApiQuestionType implements ApiEnumValue {
  single_choice('single_choice'), multiple_choice('multiple_choice'), code('code'), text('text');
  const ApiQuestionType(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiQuestionType fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiQuestionType: $value'),
  );
}

enum ApiRole implements ApiEnumValue {
  candidate('candidate'), employer('employer');
  const ApiRole(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiRole fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiRole: $value'),
  );
}

enum ApiTeamRole implements ApiEnumValue {
  backend('backend'), frontend('frontend'), fullstack('fullstack'), mobile('mobile'), ml('ml'), devops('devops'), security('security'), qa('qa'), embedded('embedded');
  const ApiTeamRole(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiTeamRole fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiTeamRole: $value'),
  );
}

enum ApiValidationStatus implements ApiEnumValue {
  pending('pending'), processing('processing'), completed('completed'), failed('failed');
  const ApiValidationStatus(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiValidationStatus fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiValidationStatus: $value'),
  );
}

enum ApiWorkFormat implements ApiEnumValue {
  office('office'), hybrid('hybrid'), remote('remote');
  const ApiWorkFormat(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiWorkFormat fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiWorkFormat: $value'),
  );
}

enum ApiInlineProvider implements ApiEnumValue {
  demo('demo'), disabled('disabled');
  const ApiInlineProvider(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiInlineProvider fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiInlineProvider: $value'),
  );
}

enum ApiInlineFormat implements ApiEnumValue {
  text('text'), voice('voice'), video('video');
  const ApiInlineFormat(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiInlineFormat fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiInlineFormat: $value'),
  );
}

enum ApiInlineStatus implements ApiEnumValue {
  active('active'), inactive('inactive'), archived('archived');
  const ApiInlineStatus(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiInlineStatus fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiInlineStatus: $value'),
  );
}

enum ApiInlineStorage implements ApiEnumValue {
  private_database('private_database'), private_object_storage('private_object_storage');
  const ApiInlineStorage(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiInlineStorage fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiInlineStorage: $value'),
  );
}

enum ApiInlineQuality implements ApiEnumValue {
  standard('standard'), high('high');
  const ApiInlineQuality(this.value);
  final String value;
  @override
  String toJson() => value;
  static ApiInlineQuality fromJson(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ApiInlineQuality: $value'),
  );
}

final class ApiAnswerInput implements ApiJsonModel {
  @override
  String get schemaName => 'AnswerInput';
  ApiAnswerInput({required this.text, this.expectedRevision, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String text;
  final int? expectedRevision;
  final Map<String, Object?> extra;

  factory ApiAnswerInput.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAnswerInput(text: _apiRequired(json, 'text', _apiString), expectedRevision: _apiOptional(json, 'expected_revision', _apiInt), extra: _apiExtras(json, {'text', 'expected_revision'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'text': _apiEncode(text),
      if (expectedRevision != null) 'expected_revision': _apiEncode(expectedRevision),
    };
    _apiValidateString('text', text, min: 1, max: 12000);
    _apiValidateNumber('expected_revision', expectedRevision, min: 0.0);
    return json;
  }
}

final class ApiAnswerResponse implements ApiJsonModel {
  @override
  String get schemaName => 'AnswerResponse';
  ApiAnswerResponse({required this.id, required this.questionId, required this.answer, this.isCorrect, this.pointsEarned, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String id;
  final String questionId;
  final String answer;
  final bool? isCorrect;
  final double? pointsEarned;
  final Map<String, Object?> extra;

  factory ApiAnswerResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAnswerResponse(id: _apiRequired(json, 'id', _apiUuid), questionId: _apiRequired(json, 'question_id', _apiUuid), answer: _apiRequired(json, 'answer', _apiString), isCorrect: _apiOptional(json, 'is_correct', _apiBool), pointsEarned: _apiOptional(json, 'points_earned', _apiDouble), extra: _apiExtras(json, {'id', 'question_id', 'answer', 'is_correct', 'points_earned'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'question_id': _apiEncode(questionId),
      'answer': _apiEncode(answer),
      if (isCorrect != null) 'is_correct': _apiEncode(isCorrect),
      if (pointsEarned != null) 'points_earned': _apiEncode(pointsEarned),
    };
    if (id != null) _apiUuid(id);
    if (questionId != null) _apiUuid(questionId);
    return json;
  }
}

final class ApiAttemptListEntry implements ApiJsonModel {
  @override
  String get schemaName => 'AttemptListEntry';
  ApiAttemptListEntry({required this.id, required this.disciplineCode, required this.targetGrade, required this.status, this.scorePercent, this.passed, required this.startedAt, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String id;
  final String disciplineCode;
  final String targetGrade;
  final ApiAttemptStatus status;
  final double? scorePercent;
  final bool? passed;
  final DateTime startedAt;
  final Map<String, Object?> extra;

  factory ApiAttemptListEntry.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAttemptListEntry(id: _apiRequired(json, 'id', _apiUuid), disciplineCode: _apiRequired(json, 'discipline_code', _apiString), targetGrade: _apiRequired(json, 'target_grade', _apiString), status: _apiRequired(json, 'status', (value) => ApiAttemptStatus.fromJson(value)), scorePercent: _apiOptional(json, 'score_percent', _apiDouble), passed: _apiOptional(json, 'passed', _apiBool), startedAt: _apiRequired(json, 'started_at', _apiDateTime), extra: _apiExtras(json, {'id', 'discipline_code', 'target_grade', 'status', 'score_percent', 'passed', 'started_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'discipline_code': _apiEncode(disciplineCode),
      'target_grade': _apiEncode(targetGrade),
      'status': _apiEncode(status),
      if (scorePercent != null) 'score_percent': _apiEncode(scorePercent),
      if (passed != null) 'passed': _apiEncode(passed),
      'started_at': _apiEncodeDate(startedAt, dateOnly: false),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiAttemptResponse implements ApiJsonModel {
  @override
  String get schemaName => 'AttemptResponse';
  ApiAttemptResponse({required this.id, required this.disciplineCode, required this.targetGrade, required this.status, required this.questionIds, required this.startedAt, this.submittedAt, this.scoredAt, this.score, this.maxScore, this.scorePercent, this.passed, this.timeSpentSeconds, required this.answers, this.extra = const {}})
      : questionIds = List.unmodifiable(questionIds),
        answers = List.unmodifiable(answers),
        extra = Map.unmodifiable(extra);
  final String id;
  final String disciplineCode;
  final String targetGrade;
  final ApiAttemptStatus status;
  final List<String> questionIds;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final DateTime? scoredAt;
  final double? score;
  final double? maxScore;
  final double? scorePercent;
  final bool? passed;
  final int? timeSpentSeconds;
  final List<ApiAnswerResponse> answers;
  final Map<String, Object?> extra;

  factory ApiAttemptResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAttemptResponse(id: _apiRequired(json, 'id', _apiUuid), disciplineCode: _apiRequired(json, 'discipline_code', _apiString), targetGrade: _apiRequired(json, 'target_grade', _apiString), status: _apiRequired(json, 'status', (value) => ApiAttemptStatus.fromJson(value)), questionIds: _apiRequired(json, 'question_ids', (value) => _apiList(value, _apiUuid)), startedAt: _apiRequired(json, 'started_at', _apiDateTime), submittedAt: _apiOptional(json, 'submitted_at', _apiDateTime), scoredAt: _apiOptional(json, 'scored_at', _apiDateTime), score: _apiOptional(json, 'score', _apiDouble), maxScore: _apiOptional(json, 'max_score', _apiDouble), scorePercent: _apiOptional(json, 'score_percent', _apiDouble), passed: _apiOptional(json, 'passed', _apiBool), timeSpentSeconds: _apiOptional(json, 'time_spent_seconds', _apiInt), answers: _apiRequired(json, 'answers', (value) => _apiList(value, (value) => ApiAnswerResponse.fromJson(value))), extra: _apiExtras(json, {'id', 'discipline_code', 'target_grade', 'status', 'question_ids', 'started_at', 'submitted_at', 'scored_at', 'score', 'max_score', 'score_percent', 'passed', 'time_spent_seconds', 'answers'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'discipline_code': _apiEncode(disciplineCode),
      'target_grade': _apiEncode(targetGrade),
      'status': _apiEncode(status),
      'question_ids': _apiEncode(questionIds),
      'started_at': _apiEncodeDate(startedAt, dateOnly: false),
      if (submittedAt != null) 'submitted_at': _apiEncodeDate(submittedAt, dateOnly: false),
      if (scoredAt != null) 'scored_at': _apiEncodeDate(scoredAt, dateOnly: false),
      if (score != null) 'score': _apiEncode(score),
      if (maxScore != null) 'max_score': _apiEncode(maxScore),
      if (scorePercent != null) 'score_percent': _apiEncode(scorePercent),
      if (passed != null) 'passed': _apiEncode(passed),
      if (timeSpentSeconds != null) 'time_spent_seconds': _apiEncode(timeSpentSeconds),
      'answers': _apiEncode(answers),
    };
    _apiUuid(id);
    for (final item in questionIds) _apiUuid(item);
    return json;
  }
}

final class ApiAvatarConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'AvatarConfiguration';
  ApiAvatarConfiguration({this.provider, this.endpoint, this.model, this.secretRef, this.temperature, this.timeoutSeconds, this.retries, this.maxTokens, this.defaultAvatarId, this.visualStyle, this.behavior, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiInlineProvider? provider;
  final String? endpoint;
  final String? model;
  final String? secretRef;
  final double? temperature;
  final int? timeoutSeconds;
  final int? retries;
  final int? maxTokens;
  final String? defaultAvatarId;
  final String? visualStyle;
  final String? behavior;
  final Map<String, Object?> extra;

  factory ApiAvatarConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAvatarConfiguration(provider: _apiOptional(json, 'provider', (value) => ApiInlineProvider.fromJson(value)), endpoint: _apiOptional(json, 'endpoint', _apiString), model: _apiOptional(json, 'model', _apiString), secretRef: _apiOptional(json, 'secret_ref', _apiString), temperature: _apiOptional(json, 'temperature', _apiDouble), timeoutSeconds: _apiOptional(json, 'timeout_seconds', _apiInt), retries: _apiOptional(json, 'retries', _apiInt), maxTokens: _apiOptional(json, 'max_tokens', _apiInt), defaultAvatarId: _apiOptional(json, 'default_avatar_id', _apiUuid), visualStyle: _apiOptional(json, 'visual_style', _apiString), behavior: _apiOptional(json, 'behavior', _apiString), extra: _apiExtras(json, {'provider', 'endpoint', 'model', 'secret_ref', 'temperature', 'timeout_seconds', 'retries', 'max_tokens', 'default_avatar_id', 'visual_style', 'behavior'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (provider != null) 'provider': _apiEncode(provider),
      if (endpoint != null) 'endpoint': _apiEncode(endpoint),
      if (model != null) 'model': _apiEncode(model),
      if (secretRef != null) 'secret_ref': _apiEncode(secretRef),
      if (temperature != null) 'temperature': _apiEncode(temperature),
      if (timeoutSeconds != null) 'timeout_seconds': _apiEncode(timeoutSeconds),
      if (retries != null) 'retries': _apiEncode(retries),
      if (maxTokens != null) 'max_tokens': _apiEncode(maxTokens),
      if (defaultAvatarId != null) 'default_avatar_id': _apiEncode(defaultAvatarId),
      if (visualStyle != null) 'visual_style': _apiEncode(visualStyle),
      if (behavior != null) 'behavior': _apiEncode(behavior),
    };
    _apiValidateString('endpoint', endpoint, max: 2048);
    _apiValidateString('model', model, max: 200);
    _apiValidateString('secret_ref', secretRef, max: 100, pattern: '^[A-Za-z0-9_-]*\$');
    _apiValidateNumber('temperature', temperature, min: 0.0, max: 2.0);
    _apiValidateNumber('timeout_seconds', timeoutSeconds, min: 1.0, max: 120.0);
    _apiValidateNumber('retries', retries, min: 0.0, max: 3.0);
    _apiValidateNumber('max_tokens', maxTokens, min: 100.0, max: 16000.0);
    if (defaultAvatarId != null) _apiUuid(defaultAvatarId);
    _apiValidateString('visual_style', visualStyle, max: 120);
    _apiValidateString('behavior', behavior, max: 120);
    return json;
  }
}

final class ApiAvatarInput implements ApiJsonModel {
  @override
  String get schemaName => 'AvatarInput';
  ApiAvatarInput({required this.name, required this.imageBase64, required this.consent, this.voice, this.language, this.visualStyle, this.behavior, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String name;
  final String imageBase64;
  final bool consent;
  final String? voice;
  final String? language;
  final String? visualStyle;
  final String? behavior;
  final Map<String, Object?> extra;

  factory ApiAvatarInput.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAvatarInput(name: _apiRequired(json, 'name', _apiString), imageBase64: _apiRequired(json, 'image_base64', _apiString), consent: _apiRequired(json, 'consent', _apiBool), voice: _apiOptional(json, 'voice', _apiString), language: _apiOptional(json, 'language', _apiString), visualStyle: _apiOptional(json, 'visual_style', _apiString), behavior: _apiOptional(json, 'behavior', _apiString), extra: _apiExtras(json, {'name', 'image_base64', 'consent', 'voice', 'language', 'visual_style', 'behavior'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'name': _apiEncode(name),
      'image_base64': _apiEncode(imageBase64),
      'consent': _apiEncode(consent),
      if (voice != null) 'voice': _apiEncode(voice),
      if (language != null) 'language': _apiEncode(language),
      if (visualStyle != null) 'visual_style': _apiEncode(visualStyle),
      if (behavior != null) 'behavior': _apiEncode(behavior),
    };
    _apiValidateString('name', name, min: 1, max: 200);
    _apiValidateString('image_base64', imageBase64, max: 8000000);
    _apiValidateString('voice', voice, max: 200);
    _apiValidateString('language', language, min: 2, max: 30);
    _apiValidateString('visual_style', visualStyle, max: 120);
    _apiValidateString('behavior', behavior, max: 120);
    return json;
  }
}

final class ApiAvatarUpdate implements ApiJsonModel {
  @override
  String get schemaName => 'AvatarUpdate';
  ApiAvatarUpdate({required this.name, this.voice, this.language, this.visualStyle, this.behavior, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String name;
  final String? voice;
  final String? language;
  final String? visualStyle;
  final String? behavior;
  final Map<String, Object?> extra;

  factory ApiAvatarUpdate.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiAvatarUpdate(name: _apiRequired(json, 'name', _apiString), voice: _apiOptional(json, 'voice', _apiString), language: _apiOptional(json, 'language', _apiString), visualStyle: _apiOptional(json, 'visual_style', _apiString), behavior: _apiOptional(json, 'behavior', _apiString), extra: _apiExtras(json, {'name', 'voice', 'language', 'visual_style', 'behavior'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'name': _apiEncode(name),
      if (voice != null) 'voice': _apiEncode(voice),
      if (language != null) 'language': _apiEncode(language),
      if (visualStyle != null) 'visual_style': _apiEncode(visualStyle),
      if (behavior != null) 'behavior': _apiEncode(behavior),
    };
    _apiValidateString('name', name, min: 1, max: 200);
    _apiValidateString('voice', voice, max: 200);
    _apiValidateString('language', language, min: 2, max: 30);
    _apiValidateString('visual_style', visualStyle, max: 120);
    _apiValidateString('behavior', behavior, max: 120);
    return json;
  }
}

final class ApiCandidateProfileResponse implements ApiJsonModel {
  @override
  String get schemaName => 'CandidateProfileResponse';
  ApiCandidateProfileResponse({required this.id, required this.fullName, required this.headline, this.city, this.grade, this.teamRole, this.workFormat, this.salaryExpectation, required this.skills, this.about, required this.openToOffers, this.fspParticipantId, this.fspSyncedAt, required this.isFspVerified, required this.achievements, required this.categories, required this.updatedAt, this.extra = const {}})
      : skills = List.unmodifiable(skills),
        achievements = List.unmodifiable(achievements),
        categories = List.unmodifiable(categories),
        extra = Map.unmodifiable(extra);
  final String id;
  final String fullName;
  final String headline;
  final String? city;
  final ApiGrade? grade;
  final ApiTeamRole? teamRole;
  final ApiWorkFormat? workFormat;
  final int? salaryExpectation;
  final List<String> skills;
  final String? about;
  final bool openToOffers;
  final String? fspParticipantId;
  final DateTime? fspSyncedAt;
  final bool isFspVerified;
  final List<ApiFspAchievementResponse> achievements;
  final List<ApiTalentCategoryResponse> categories;
  final DateTime updatedAt;
  final Map<String, Object?> extra;

  factory ApiCandidateProfileResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiCandidateProfileResponse(id: _apiRequired(json, 'id', _apiUuid), fullName: _apiRequired(json, 'full_name', _apiString), headline: _apiRequired(json, 'headline', _apiString), city: _apiOptional(json, 'city', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), teamRole: _apiOptional(json, 'team_role', (value) => ApiTeamRole.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), salaryExpectation: _apiOptional(json, 'salary_expectation', _apiInt), skills: _apiRequired(json, 'skills', (value) => _apiList(value, _apiString)), about: _apiOptional(json, 'about', _apiString), openToOffers: _apiRequired(json, 'open_to_offers', _apiBool), fspParticipantId: _apiOptional(json, 'fsp_participant_id', _apiString), fspSyncedAt: _apiOptional(json, 'fsp_synced_at', _apiDateTime), isFspVerified: _apiRequired(json, 'is_fsp_verified', _apiBool), achievements: _apiRequired(json, 'achievements', (value) => _apiList(value, (value) => ApiFspAchievementResponse.fromJson(value))), categories: _apiRequired(json, 'categories', (value) => _apiList(value, (value) => ApiTalentCategoryResponse.fromJson(value))), updatedAt: _apiRequired(json, 'updated_at', _apiDateTime), extra: _apiExtras(json, {'id', 'full_name', 'headline', 'city', 'grade', 'team_role', 'work_format', 'salary_expectation', 'skills', 'about', 'open_to_offers', 'fsp_participant_id', 'fsp_synced_at', 'is_fsp_verified', 'achievements', 'categories', 'updated_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'full_name': _apiEncode(fullName),
      'headline': _apiEncode(headline),
      if (city != null) 'city': _apiEncode(city),
      if (grade != null) 'grade': _apiEncode(grade),
      if (teamRole != null) 'team_role': _apiEncode(teamRole),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      if (salaryExpectation != null) 'salary_expectation': _apiEncode(salaryExpectation),
      'skills': _apiEncode(skills),
      if (about != null) 'about': _apiEncode(about),
      'open_to_offers': _apiEncode(openToOffers),
      if (fspParticipantId != null) 'fsp_participant_id': _apiEncode(fspParticipantId),
      if (fspSyncedAt != null) 'fsp_synced_at': _apiEncodeDate(fspSyncedAt, dateOnly: false),
      'is_fsp_verified': _apiEncode(isFspVerified),
      'achievements': _apiEncode(achievements),
      'categories': _apiEncode(categories),
      'updated_at': _apiEncodeDate(updatedAt, dateOnly: false),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiCandidateSearchResponse implements ApiJsonModel {
  @override
  String get schemaName => 'CandidateSearchResponse';
  ApiCandidateSearchResponse({required this.items, required this.total, required this.limit, required this.offset, this.extra = const {}})
      : items = List.unmodifiable(items),
        extra = Map.unmodifiable(extra);
  final List<ApiCandidateSummaryResponse> items;
  final int total;
  final int limit;
  final int offset;
  final Map<String, Object?> extra;

  factory ApiCandidateSearchResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiCandidateSearchResponse(items: _apiRequired(json, 'items', (value) => _apiList(value, (value) => ApiCandidateSummaryResponse.fromJson(value))), total: _apiRequired(json, 'total', _apiInt), limit: _apiRequired(json, 'limit', _apiInt), offset: _apiRequired(json, 'offset', _apiInt), extra: _apiExtras(json, {'items', 'total', 'limit', 'offset'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'items': _apiEncode(items),
      'total': _apiEncode(total),
      'limit': _apiEncode(limit),
      'offset': _apiEncode(offset),
    };
    return json;
  }
}

final class ApiCandidateSummaryResponse implements ApiJsonModel {
  @override
  String get schemaName => 'CandidateSummaryResponse';
  ApiCandidateSummaryResponse({required this.id, required this.fullName, required this.headline, this.city, this.grade, this.teamRole, this.workFormat, this.salaryExpectation, required this.skills, required this.isFspVerified, required this.relevantScore, required this.categories, this.extra = const {}})
      : skills = List.unmodifiable(skills),
        categories = List.unmodifiable(categories),
        extra = Map.unmodifiable(extra);
  final String id;
  final String fullName;
  final String headline;
  final String? city;
  final ApiGrade? grade;
  final ApiTeamRole? teamRole;
  final ApiWorkFormat? workFormat;
  final int? salaryExpectation;
  final List<String> skills;
  final bool isFspVerified;
  final double relevantScore;
  final List<ApiTalentCategoryResponse> categories;
  final Map<String, Object?> extra;

  factory ApiCandidateSummaryResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiCandidateSummaryResponse(id: _apiRequired(json, 'id', _apiUuid), fullName: _apiRequired(json, 'full_name', _apiString), headline: _apiRequired(json, 'headline', _apiString), city: _apiOptional(json, 'city', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), teamRole: _apiOptional(json, 'team_role', (value) => ApiTeamRole.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), salaryExpectation: _apiOptional(json, 'salary_expectation', _apiInt), skills: _apiRequired(json, 'skills', (value) => _apiList(value, _apiString)), isFspVerified: _apiRequired(json, 'is_fsp_verified', _apiBool), relevantScore: _apiRequired(json, 'relevant_score', _apiDouble), categories: _apiRequired(json, 'categories', (value) => _apiList(value, (value) => ApiTalentCategoryResponse.fromJson(value))), extra: _apiExtras(json, {'id', 'full_name', 'headline', 'city', 'grade', 'team_role', 'work_format', 'salary_expectation', 'skills', 'is_fsp_verified', 'relevant_score', 'categories'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'full_name': _apiEncode(fullName),
      'headline': _apiEncode(headline),
      if (city != null) 'city': _apiEncode(city),
      if (grade != null) 'grade': _apiEncode(grade),
      if (teamRole != null) 'team_role': _apiEncode(teamRole),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      if (salaryExpectation != null) 'salary_expectation': _apiEncode(salaryExpectation),
      'skills': _apiEncode(skills),
      'is_fsp_verified': _apiEncode(isFspVerified),
      'relevant_score': _apiEncode(relevantScore),
      'categories': _apiEncode(categories),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'Configuration';
  ApiConfiguration({this.ai, this.voice, this.video, this.avatar, this.security, this.defaultScenarioId, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiProviderConfiguration? ai;
  final ApiVoiceConfiguration? voice;
  final ApiVideoConfiguration? video;
  final ApiAvatarConfiguration? avatar;
  final ApiSecurityConfiguration? security;
  final String? defaultScenarioId;
  final Map<String, Object?> extra;

  factory ApiConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiConfiguration(ai: _apiOptional(json, 'ai', (value) => ApiProviderConfiguration.fromJson(value)), voice: _apiOptional(json, 'voice', (value) => ApiVoiceConfiguration.fromJson(value)), video: _apiOptional(json, 'video', (value) => ApiVideoConfiguration.fromJson(value)), avatar: _apiOptional(json, 'avatar', (value) => ApiAvatarConfiguration.fromJson(value)), security: _apiOptional(json, 'security', (value) => ApiSecurityConfiguration.fromJson(value)), defaultScenarioId: _apiOptional(json, 'default_scenario_id', _apiUuid), extra: _apiExtras(json, {'ai', 'voice', 'video', 'avatar', 'security', 'default_scenario_id'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (ai != null) 'ai': _apiEncode(ai),
      if (voice != null) 'voice': _apiEncode(voice),
      if (video != null) 'video': _apiEncode(video),
      if (avatar != null) 'avatar': _apiEncode(avatar),
      if (security != null) 'security': _apiEncode(security),
      if (defaultScenarioId != null) 'default_scenario_id': _apiEncode(defaultScenarioId),
    };
    if (defaultScenarioId != null) _apiUuid(defaultScenarioId);
    return json;
  }
}

final class ApiCriterion implements ApiJsonModel {
  @override
  String get schemaName => 'Criterion';
  ApiCriterion({required this.name, required this.weight, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String name;
  final int weight;
  final Map<String, Object?> extra;

  factory ApiCriterion.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiCriterion(name: _apiRequired(json, 'name', _apiString), weight: _apiRequired(json, 'weight', _apiInt), extra: _apiExtras(json, {'name', 'weight'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'name': _apiEncode(name),
      'weight': _apiEncode(weight),
    };
    _apiValidateString('name', name, min: 1, max: 120);
    _apiValidateNumber('weight', weight, max: 100.0, exclusiveMin: 0.0);
    return json;
  }
}

final class ApiDictionariesResponse implements ApiJsonModel {
  @override
  String get schemaName => 'DictionariesResponse';
  ApiDictionariesResponse({required this.roles, required this.disciplines, required this.verificationLevels, required this.competitionResults, required this.competitionLevels, required this.sportRanks, required this.grades, required this.teamRoles, required this.workFormats, required this.offerStatuses, this.extra = const {}})
      : roles = List.unmodifiable(roles),
        disciplines = List.unmodifiable(disciplines),
        verificationLevels = List.unmodifiable(verificationLevels),
        competitionResults = List.unmodifiable(competitionResults),
        competitionLevels = List.unmodifiable(competitionLevels),
        sportRanks = List.unmodifiable(sportRanks),
        grades = List.unmodifiable(grades),
        teamRoles = List.unmodifiable(teamRoles),
        workFormats = List.unmodifiable(workFormats),
        offerStatuses = List.unmodifiable(offerStatuses),
        extra = Map.unmodifiable(extra);
  final List<ApiOption> roles;
  final List<ApiOption> disciplines;
  final List<ApiLevelOption> verificationLevels;
  final List<ApiOption> competitionResults;
  final List<ApiOption> competitionLevels;
  final List<ApiOption> sportRanks;
  final List<ApiOption> grades;
  final List<ApiOption> teamRoles;
  final List<ApiOption> workFormats;
  final List<ApiOption> offerStatuses;
  final Map<String, Object?> extra;

  factory ApiDictionariesResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiDictionariesResponse(roles: _apiRequired(json, 'roles', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), disciplines: _apiRequired(json, 'disciplines', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), verificationLevels: _apiRequired(json, 'verification_levels', (value) => _apiList(value, (value) => ApiLevelOption.fromJson(value))), competitionResults: _apiRequired(json, 'competition_results', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), competitionLevels: _apiRequired(json, 'competition_levels', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), sportRanks: _apiRequired(json, 'sport_ranks', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), grades: _apiRequired(json, 'grades', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), teamRoles: _apiRequired(json, 'team_roles', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), workFormats: _apiRequired(json, 'work_formats', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), offerStatuses: _apiRequired(json, 'offer_statuses', (value) => _apiList(value, (value) => ApiOption.fromJson(value))), extra: _apiExtras(json, {'roles', 'disciplines', 'verification_levels', 'competition_results', 'competition_levels', 'sport_ranks', 'grades', 'team_roles', 'work_formats', 'offer_statuses'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'roles': _apiEncode(roles),
      'disciplines': _apiEncode(disciplines),
      'verification_levels': _apiEncode(verificationLevels),
      'competition_results': _apiEncode(competitionResults),
      'competition_levels': _apiEncode(competitionLevels),
      'sport_ranks': _apiEncode(sportRanks),
      'grades': _apiEncode(grades),
      'team_roles': _apiEncode(teamRoles),
      'work_formats': _apiEncode(workFormats),
      'offer_statuses': _apiEncode(offerStatuses),
    };
    return json;
  }
}

final class ApiEmployerOverviewResponse implements ApiJsonModel {
  @override
  String get schemaName => 'EmployerOverviewResponse';
  ApiEmployerOverviewResponse({required this.talentPool, required this.funnel, required this.rates, this.averageResponseHours, required this.openVacancies, required this.recentDeclineReasons, this.extra = const {}})
      : recentDeclineReasons = List.unmodifiable(recentDeclineReasons),
        extra = Map.unmodifiable(extra);
  final ApiTalentPoolResponse talentPool;
  final ApiFunnelResponse funnel;
  final ApiRatesResponse rates;
  final double? averageResponseHours;
  final int openVacancies;
  final List<String> recentDeclineReasons;
  final Map<String, Object?> extra;

  factory ApiEmployerOverviewResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiEmployerOverviewResponse(talentPool: _apiRequired(json, 'talent_pool', (value) => ApiTalentPoolResponse.fromJson(value)), funnel: _apiRequired(json, 'funnel', (value) => ApiFunnelResponse.fromJson(value)), rates: _apiRequired(json, 'rates', (value) => ApiRatesResponse.fromJson(value)), averageResponseHours: _apiOptional(json, 'average_response_hours', _apiDouble), openVacancies: _apiRequired(json, 'open_vacancies', _apiInt), recentDeclineReasons: _apiRequired(json, 'recent_decline_reasons', (value) => _apiList(value, _apiString)), extra: _apiExtras(json, {'talent_pool', 'funnel', 'rates', 'average_response_hours', 'open_vacancies', 'recent_decline_reasons'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'talent_pool': _apiEncode(talentPool),
      'funnel': _apiEncode(funnel),
      'rates': _apiEncode(rates),
      if (averageResponseHours != null) 'average_response_hours': _apiEncode(averageResponseHours),
      'open_vacancies': _apiEncode(openVacancies),
      'recent_decline_reasons': _apiEncode(recentDeclineReasons),
    };
    return json;
  }
}

final class ApiErrorBody implements ApiJsonModel {
  @override
  String get schemaName => 'ErrorBody';
  ApiErrorBody({required this.code, required this.message, this.details, this.extra = const {}})
      : details = details == null ? null : Map.unmodifiable(details),
        extra = Map.unmodifiable(extra);
  final String code;
  final String message;
  final Map<String, Object?>? details;
  final Map<String, Object?> extra;

  factory ApiErrorBody.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiErrorBody(code: _apiRequired(json, 'code', _apiString), message: _apiRequired(json, 'message', _apiString), details: _apiOptional(json, 'details', _apiObject), extra: _apiExtras(json, {'code', 'message', 'details'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'code': _apiEncode(code),
      'message': _apiEncode(message),
      if (details != null) 'details': _apiEncode(details),
    };
    return json;
  }
}

final class ApiErrorResponse implements ApiJsonModel {
  @override
  String get schemaName => 'ErrorResponse';
  ApiErrorResponse({required this.error, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiErrorBody error;
  final Map<String, Object?> extra;

  factory ApiErrorResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiErrorResponse(error: _apiRequired(json, 'error', (value) => ApiErrorBody.fromJson(value)), extra: _apiExtras(json, {'error'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'error': _apiEncode(error),
    };
    return json;
  }
}

final class ApiFspAchievementResponse implements ApiJsonModel {
  @override
  String get schemaName => 'FspAchievementResponse';
  ApiFspAchievementResponse({required this.competitionName, required this.heldOn, required this.disciplineCode, required this.competitionLevelCode, required this.resultCode, this.teamRole, this.sportRankCode, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String competitionName;
  final DateTime heldOn;
  final String disciplineCode;
  final String competitionLevelCode;
  final String resultCode;
  final String? teamRole;
  final String? sportRankCode;
  final Map<String, Object?> extra;

  factory ApiFspAchievementResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiFspAchievementResponse(competitionName: _apiRequired(json, 'competition_name', _apiString), heldOn: _apiRequired(json, 'held_on', _apiDateOnly), disciplineCode: _apiRequired(json, 'discipline_code', _apiString), competitionLevelCode: _apiRequired(json, 'competition_level_code', _apiString), resultCode: _apiRequired(json, 'result_code', _apiString), teamRole: _apiOptional(json, 'team_role', _apiString), sportRankCode: _apiOptional(json, 'sport_rank_code', _apiString), extra: _apiExtras(json, {'competition_name', 'held_on', 'discipline_code', 'competition_level_code', 'result_code', 'team_role', 'sport_rank_code'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'competition_name': _apiEncode(competitionName),
      'held_on': _apiEncodeDate(heldOn, dateOnly: true),
      'discipline_code': _apiEncode(disciplineCode),
      'competition_level_code': _apiEncode(competitionLevelCode),
      'result_code': _apiEncode(resultCode),
      if (teamRole != null) 'team_role': _apiEncode(teamRole),
      if (sportRankCode != null) 'sport_rank_code': _apiEncode(sportRankCode),
    };
    return json;
  }
}

final class ApiFspSyncResponse implements ApiJsonModel {
  @override
  String get schemaName => 'FspSyncResponse';
  ApiFspSyncResponse({required this.profile, required this.imported, required this.skipped, this.extra = const {}})
      : skipped = List.unmodifiable(skipped),
        extra = Map.unmodifiable(extra);
  final ApiCandidateProfileResponse profile;
  final int imported;
  final List<String> skipped;
  final Map<String, Object?> extra;

  factory ApiFspSyncResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiFspSyncResponse(profile: _apiRequired(json, 'profile', (value) => ApiCandidateProfileResponse.fromJson(value)), imported: _apiRequired(json, 'imported', _apiInt), skipped: _apiRequired(json, 'skipped', (value) => _apiList(value, _apiString)), extra: _apiExtras(json, {'profile', 'imported', 'skipped'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'profile': _apiEncode(profile),
      'imported': _apiEncode(imported),
      'skipped': _apiEncode(skipped),
    };
    return json;
  }
}

final class ApiFunnelResponse implements ApiJsonModel {
  @override
  String get schemaName => 'FunnelResponse';
  ApiFunnelResponse({required this.candidatesViewed, required this.candidatesContacted, required this.offersSent, required this.offersOpened, required this.offersAccepted, required this.offersDeclined, required this.offersWithdrawn, required this.offersAwaiting, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final int candidatesViewed;
  final int candidatesContacted;
  final int offersSent;
  final int offersOpened;
  final int offersAccepted;
  final int offersDeclined;
  final int offersWithdrawn;
  final int offersAwaiting;
  final Map<String, Object?> extra;

  factory ApiFunnelResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiFunnelResponse(candidatesViewed: _apiRequired(json, 'candidates_viewed', _apiInt), candidatesContacted: _apiRequired(json, 'candidates_contacted', _apiInt), offersSent: _apiRequired(json, 'offers_sent', _apiInt), offersOpened: _apiRequired(json, 'offers_opened', _apiInt), offersAccepted: _apiRequired(json, 'offers_accepted', _apiInt), offersDeclined: _apiRequired(json, 'offers_declined', _apiInt), offersWithdrawn: _apiRequired(json, 'offers_withdrawn', _apiInt), offersAwaiting: _apiRequired(json, 'offers_awaiting', _apiInt), extra: _apiExtras(json, {'candidates_viewed', 'candidates_contacted', 'offers_sent', 'offers_opened', 'offers_accepted', 'offers_declined', 'offers_withdrawn', 'offers_awaiting'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'candidates_viewed': _apiEncode(candidatesViewed),
      'candidates_contacted': _apiEncode(candidatesContacted),
      'offers_sent': _apiEncode(offersSent),
      'offers_opened': _apiEncode(offersOpened),
      'offers_accepted': _apiEncode(offersAccepted),
      'offers_declined': _apiEncode(offersDeclined),
      'offers_withdrawn': _apiEncode(offersWithdrawn),
      'offers_awaiting': _apiEncode(offersAwaiting),
    };
    return json;
  }
}

final class ApiGradeHistoryResponse implements ApiJsonModel {
  @override
  String get schemaName => 'GradeHistoryResponse';
  ApiGradeHistoryResponse({required this.id, required this.disciplineCode, this.previousGrade, required this.newGrade, required this.reason, this.attemptId, required this.createdAt, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String id;
  final String disciplineCode;
  final String? previousGrade;
  final String newGrade;
  final ApiGradeChangeReason reason;
  final String? attemptId;
  final DateTime createdAt;
  final Map<String, Object?> extra;

  factory ApiGradeHistoryResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiGradeHistoryResponse(id: _apiRequired(json, 'id', _apiUuid), disciplineCode: _apiRequired(json, 'discipline_code', _apiString), previousGrade: _apiOptional(json, 'previous_grade', _apiString), newGrade: _apiRequired(json, 'new_grade', _apiString), reason: _apiRequired(json, 'reason', (value) => ApiGradeChangeReason.fromJson(value)), attemptId: _apiOptional(json, 'attempt_id', _apiUuid), createdAt: _apiRequired(json, 'created_at', _apiDateTime), extra: _apiExtras(json, {'id', 'discipline_code', 'previous_grade', 'new_grade', 'reason', 'attempt_id', 'created_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'discipline_code': _apiEncode(disciplineCode),
      if (previousGrade != null) 'previous_grade': _apiEncode(previousGrade),
      'new_grade': _apiEncode(newGrade),
      'reason': _apiEncode(reason),
      if (attemptId != null) 'attempt_id': _apiEncode(attemptId),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
    };
    _apiUuid(id);
    _apiUuid(attemptId);
    return json;
  }
}

final class ApiHTTPValidationError implements ApiJsonModel {
  @override
  String get schemaName => 'HTTPValidationError';
  ApiHTTPValidationError({this.detail, this.extra = const {}})
      : detail = detail == null ? null : List.unmodifiable(detail),
        extra = Map.unmodifiable(extra);
  final List<ApiValidationError>? detail;
  final Map<String, Object?> extra;

  factory ApiHTTPValidationError.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiHTTPValidationError(detail: _apiOptional(json, 'detail', (value) => _apiList(value, (value) => ApiValidationError.fromJson(value))), extra: _apiExtras(json, {'detail'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (detail != null) 'detail': _apiEncode(detail),
    };
    return json;
  }
}

final class ApiInterviewInput implements ApiJsonModel {
  @override
  String get schemaName => 'InterviewInput';
  ApiInterviewInput({required this.vacancyId, required this.candidateId, required this.scenarioId, required this.format, this.language, this.avatarId, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String vacancyId;
  final String candidateId;
  final String scenarioId;
  final ApiInlineFormat format;
  final String? language;
  final String? avatarId;
  final Map<String, Object?> extra;

  factory ApiInterviewInput.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiInterviewInput(vacancyId: _apiRequired(json, 'vacancy_id', _apiUuid), candidateId: _apiRequired(json, 'candidate_id', _apiUuid), scenarioId: _apiRequired(json, 'scenario_id', _apiUuid), format: _apiRequired(json, 'format', (value) => ApiInlineFormat.fromJson(value)), language: _apiOptional(json, 'language', _apiString), avatarId: _apiOptional(json, 'avatar_id', _apiUuid), extra: _apiExtras(json, {'vacancy_id', 'candidate_id', 'scenario_id', 'format', 'language', 'avatar_id'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'vacancy_id': _apiEncode(vacancyId),
      'candidate_id': _apiEncode(candidateId),
      'scenario_id': _apiEncode(scenarioId),
      'format': _apiEncode(format),
      if (language != null) 'language': _apiEncode(language),
      if (avatarId != null) 'avatar_id': _apiEncode(avatarId),
    };
    if (vacancyId != null) _apiUuid(vacancyId);
    if (candidateId != null) _apiUuid(candidateId);
    if (scenarioId != null) _apiUuid(scenarioId);
    _apiValidateString('language', language, min: 2, max: 30);
    if (avatarId != null) _apiUuid(avatarId);
    return json;
  }
}

final class ApiLevelBucketResponse implements ApiJsonModel {
  @override
  String get schemaName => 'LevelBucketResponse';
  ApiLevelBucketResponse({required this.disciplineCode, required this.levelCode, required this.candidates, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String disciplineCode;
  final String levelCode;
  final int candidates;
  final Map<String, Object?> extra;

  factory ApiLevelBucketResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiLevelBucketResponse(disciplineCode: _apiRequired(json, 'discipline_code', _apiString), levelCode: _apiRequired(json, 'level_code', _apiString), candidates: _apiRequired(json, 'candidates', _apiInt), extra: _apiExtras(json, {'discipline_code', 'level_code', 'candidates'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'discipline_code': _apiEncode(disciplineCode),
      'level_code': _apiEncode(levelCode),
      'candidates': _apiEncode(candidates),
    };
    return json;
  }
}

final class ApiLevelOption implements ApiJsonModel {
  @override
  String get schemaName => 'LevelOption';
  ApiLevelOption({required this.code, required this.label, required this.minScore, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String code;
  final String label;
  final double minScore;
  final Map<String, Object?> extra;

  factory ApiLevelOption.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiLevelOption(code: _apiRequired(json, 'code', _apiString), label: _apiRequired(json, 'label', _apiString), minScore: _apiRequired(json, 'min_score', _apiDouble), extra: _apiExtras(json, {'code', 'label', 'min_score'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'code': _apiEncode(code),
      'label': _apiEncode(label),
      'min_score': _apiEncode(minScore),
    };
    return json;
  }
}

final class ApiLoginRequest implements ApiJsonModel {
  @override
  String get schemaName => 'LoginRequest';
  ApiLoginRequest({required this.email, required this.password, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String email;
  final String password;
  final Map<String, Object?> extra;

  factory ApiLoginRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiLoginRequest(email: _apiRequired(json, 'email', _apiString), password: _apiRequired(json, 'password', _apiString), extra: _apiExtras(json, {'email', 'password'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'email': _apiEncode(email),
      'password': _apiEncode(password),
    };
    _apiValidateString('password', password, min: 1, max: 128);
    return json;
  }
}

final class ApiOfferCreateRequest implements ApiJsonModel {
  @override
  String get schemaName => 'OfferCreateRequest';
  ApiOfferCreateRequest({required this.vacancyId, required this.candidateId, required this.salary, required this.message, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String vacancyId;
  final String candidateId;
  final int salary;
  final String message;
  final Map<String, Object?> extra;

  factory ApiOfferCreateRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiOfferCreateRequest(vacancyId: _apiRequired(json, 'vacancy_id', _apiUuid), candidateId: _apiRequired(json, 'candidate_id', _apiUuid), salary: _apiRequired(json, 'salary', _apiInt), message: _apiRequired(json, 'message', _apiString), extra: _apiExtras(json, {'vacancy_id', 'candidate_id', 'salary', 'message'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'vacancy_id': _apiEncode(vacancyId),
      'candidate_id': _apiEncode(candidateId),
      'salary': _apiEncode(salary),
      'message': _apiEncode(message),
    };
    _apiUuid(vacancyId);
    _apiUuid(candidateId);
    _apiValidateNumber('salary', salary, exclusiveMin: 0.0);
    _apiValidateString('message', message, min: 10, max: 2000);
    return json;
  }
}

final class ApiOfferDeclineRequest implements ApiJsonModel {
  @override
  String get schemaName => 'OfferDeclineRequest';
  ApiOfferDeclineRequest({required this.reason, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String reason;
  final Map<String, Object?> extra;

  factory ApiOfferDeclineRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiOfferDeclineRequest(reason: _apiRequired(json, 'reason', _apiString), extra: _apiExtras(json, {'reason'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'reason': _apiEncode(reason),
    };
    _apiValidateString('reason', reason, min: 1, max: 1000);
    return json;
  }
}

final class ApiOfferResponse implements ApiJsonModel {
  @override
  String get schemaName => 'OfferResponse';
  ApiOfferResponse({required this.id, required this.status, required this.salary, required this.message, required this.createdAt, this.viewedAt, this.respondedAt, this.declineReason, required this.awaitsResponse, required this.vacancy, required this.companyName, required this.candidateId, required this.candidateName, required this.candidateHeadline, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String id;
  final ApiOfferStatus status;
  final int salary;
  final String message;
  final DateTime createdAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final String? declineReason;
  final bool awaitsResponse;
  final ApiVacancyResponse vacancy;
  final String companyName;
  final String candidateId;
  final String candidateName;
  final String candidateHeadline;
  final Map<String, Object?> extra;

  factory ApiOfferResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiOfferResponse(id: _apiRequired(json, 'id', _apiUuid), status: _apiRequired(json, 'status', (value) => ApiOfferStatus.fromJson(value)), salary: _apiRequired(json, 'salary', _apiInt), message: _apiRequired(json, 'message', _apiString), createdAt: _apiRequired(json, 'created_at', _apiDateTime), viewedAt: _apiOptional(json, 'viewed_at', _apiDateTime), respondedAt: _apiOptional(json, 'responded_at', _apiDateTime), declineReason: _apiOptional(json, 'decline_reason', _apiString), awaitsResponse: _apiRequired(json, 'awaits_response', _apiBool), vacancy: _apiRequired(json, 'vacancy', (value) => ApiVacancyResponse.fromJson(value)), companyName: _apiRequired(json, 'company_name', _apiString), candidateId: _apiRequired(json, 'candidate_id', _apiUuid), candidateName: _apiRequired(json, 'candidate_name', _apiString), candidateHeadline: _apiRequired(json, 'candidate_headline', _apiString), extra: _apiExtras(json, {'id', 'status', 'salary', 'message', 'created_at', 'viewed_at', 'responded_at', 'decline_reason', 'awaits_response', 'vacancy', 'company_name', 'candidate_id', 'candidate_name', 'candidate_headline'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'status': _apiEncode(status),
      'salary': _apiEncode(salary),
      'message': _apiEncode(message),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
      if (viewedAt != null) 'viewed_at': _apiEncodeDate(viewedAt, dateOnly: false),
      if (respondedAt != null) 'responded_at': _apiEncodeDate(respondedAt, dateOnly: false),
      if (declineReason != null) 'decline_reason': _apiEncode(declineReason),
      'awaits_response': _apiEncode(awaitsResponse),
      'vacancy': _apiEncode(vacancy),
      'company_name': _apiEncode(companyName),
      'candidate_id': _apiEncode(candidateId),
      'candidate_name': _apiEncode(candidateName),
      'candidate_headline': _apiEncode(candidateHeadline),
    };
    _apiUuid(id);
    _apiUuid(candidateId);
    return json;
  }
}

final class ApiOption implements ApiJsonModel {
  @override
  String get schemaName => 'Option';
  ApiOption({required this.code, required this.label, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String code;
  final String label;
  final Map<String, Object?> extra;

  factory ApiOption.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiOption(code: _apiRequired(json, 'code', _apiString), label: _apiRequired(json, 'label', _apiString), extra: _apiExtras(json, {'code', 'label'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'code': _apiEncode(code),
      'label': _apiEncode(label),
    };
    return json;
  }
}

final class ApiProfileUpdateRequest implements ApiJsonModel {
  @override
  String get schemaName => 'ProfileUpdateRequest';
  ApiProfileUpdateRequest({required this.fullName, required this.headline, this.city, this.grade, this.teamRole, this.workFormat, this.salaryExpectation, this.skills, this.about, this.openToOffers, this.fspParticipantId, this.extra = const {}})
      : skills = skills == null ? null : List.unmodifiable(skills),
        extra = Map.unmodifiable(extra);
  final String fullName;
  final String headline;
  final String? city;
  final ApiGrade? grade;
  final ApiTeamRole? teamRole;
  final ApiWorkFormat? workFormat;
  final int? salaryExpectation;
  final List<String>? skills;
  final String? about;
  final bool? openToOffers;
  final String? fspParticipantId;
  final Map<String, Object?> extra;

  factory ApiProfileUpdateRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiProfileUpdateRequest(fullName: _apiRequired(json, 'full_name', _apiString), headline: _apiRequired(json, 'headline', _apiString), city: _apiOptional(json, 'city', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), teamRole: _apiOptional(json, 'team_role', (value) => ApiTeamRole.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), salaryExpectation: _apiOptional(json, 'salary_expectation', _apiInt), skills: _apiOptional(json, 'skills', (value) => _apiList(value, _apiString)), about: _apiOptional(json, 'about', _apiString), openToOffers: _apiOptional(json, 'open_to_offers', _apiBool), fspParticipantId: _apiOptional(json, 'fsp_participant_id', _apiString), extra: _apiExtras(json, {'full_name', 'headline', 'city', 'grade', 'team_role', 'work_format', 'salary_expectation', 'skills', 'about', 'open_to_offers', 'fsp_participant_id'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'full_name': _apiEncode(fullName),
      'headline': _apiEncode(headline),
      if (city != null) 'city': _apiEncode(city),
      if (grade != null) 'grade': _apiEncode(grade),
      if (teamRole != null) 'team_role': _apiEncode(teamRole),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      if (salaryExpectation != null) 'salary_expectation': _apiEncode(salaryExpectation),
      if (skills != null) 'skills': _apiEncode(skills),
      if (about != null) 'about': _apiEncode(about),
      if (openToOffers != null) 'open_to_offers': _apiEncode(openToOffers),
      if (fspParticipantId != null) 'fsp_participant_id': _apiEncode(fspParticipantId),
    };
    _apiValidateString('full_name', fullName, min: 2, max: 200);
    _apiValidateString('headline', headline, min: 2, max: 200);
    _apiValidateString('city', city, max: 120);
    _apiValidateNumber('salary_expectation', salaryExpectation, exclusiveMin: 0.0);
    _apiValidateString('about', about, max: 4000);
    _apiValidateString('fsp_participant_id', fspParticipantId, max: 64);
    return json;
  }
}

final class ApiProviderConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'ProviderConfiguration';
  ApiProviderConfiguration({this.provider, this.endpoint, this.model, this.secretRef, this.temperature, this.timeoutSeconds, this.retries, this.maxTokens, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiInlineProvider? provider;
  final String? endpoint;
  final String? model;
  final String? secretRef;
  final double? temperature;
  final int? timeoutSeconds;
  final int? retries;
  final int? maxTokens;
  final Map<String, Object?> extra;

  factory ApiProviderConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiProviderConfiguration(provider: _apiOptional(json, 'provider', (value) => ApiInlineProvider.fromJson(value)), endpoint: _apiOptional(json, 'endpoint', _apiString), model: _apiOptional(json, 'model', _apiString), secretRef: _apiOptional(json, 'secret_ref', _apiString), temperature: _apiOptional(json, 'temperature', _apiDouble), timeoutSeconds: _apiOptional(json, 'timeout_seconds', _apiInt), retries: _apiOptional(json, 'retries', _apiInt), maxTokens: _apiOptional(json, 'max_tokens', _apiInt), extra: _apiExtras(json, {'provider', 'endpoint', 'model', 'secret_ref', 'temperature', 'timeout_seconds', 'retries', 'max_tokens'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (provider != null) 'provider': _apiEncode(provider),
      if (endpoint != null) 'endpoint': _apiEncode(endpoint),
      if (model != null) 'model': _apiEncode(model),
      if (secretRef != null) 'secret_ref': _apiEncode(secretRef),
      if (temperature != null) 'temperature': _apiEncode(temperature),
      if (timeoutSeconds != null) 'timeout_seconds': _apiEncode(timeoutSeconds),
      if (retries != null) 'retries': _apiEncode(retries),
      if (maxTokens != null) 'max_tokens': _apiEncode(maxTokens),
    };
    _apiValidateString('endpoint', endpoint, max: 2048);
    _apiValidateString('model', model, max: 200);
    _apiValidateString('secret_ref', secretRef, max: 100, pattern: '^[A-Za-z0-9_-]*\$');
    _apiValidateNumber('temperature', temperature, min: 0.0, max: 2.0);
    _apiValidateNumber('timeout_seconds', timeoutSeconds, min: 1.0, max: 120.0);
    _apiValidateNumber('retries', retries, min: 0.0, max: 3.0);
    _apiValidateNumber('max_tokens', maxTokens, min: 100.0, max: 16000.0);
    return json;
  }
}

final class ApiQuestionResponse implements ApiJsonModel {
  @override
  String get schemaName => 'QuestionResponse';
  ApiQuestionResponse({required this.id, required this.disciplineCode, required this.targetGrade, required this.difficulty, required this.questionType, required this.body, required this.options, required this.skills, required this.points, this.extra = const {}})
      : options = List.unmodifiable(options),
        skills = List.unmodifiable(skills),
        extra = Map.unmodifiable(extra);
  final String id;
  final String disciplineCode;
  final String targetGrade;
  final int difficulty;
  final ApiQuestionType questionType;
  final String body;
  final List<String> options;
  final List<String> skills;
  final double points;
  final Map<String, Object?> extra;

  factory ApiQuestionResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiQuestionResponse(id: _apiRequired(json, 'id', _apiUuid), disciplineCode: _apiRequired(json, 'discipline_code', _apiString), targetGrade: _apiRequired(json, 'target_grade', _apiString), difficulty: _apiRequired(json, 'difficulty', _apiInt), questionType: _apiRequired(json, 'question_type', (value) => ApiQuestionType.fromJson(value)), body: _apiRequired(json, 'body', _apiString), options: _apiRequired(json, 'options', (value) => _apiList(value, _apiString)), skills: _apiRequired(json, 'skills', (value) => _apiList(value, _apiString)), points: _apiRequired(json, 'points', _apiDouble), extra: _apiExtras(json, {'id', 'discipline_code', 'target_grade', 'difficulty', 'question_type', 'body', 'options', 'skills', 'points'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'discipline_code': _apiEncode(disciplineCode),
      'target_grade': _apiEncode(targetGrade),
      'difficulty': _apiEncode(difficulty),
      'question_type': _apiEncode(questionType),
      'body': _apiEncode(body),
      'options': _apiEncode(options),
      'skills': _apiEncode(skills),
      'points': _apiEncode(points),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiRatesResponse implements ApiJsonModel {
  @override
  String get schemaName => 'RatesResponse';
  ApiRatesResponse({this.viewToOffer, this.offerOpen, this.acceptance, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final double? viewToOffer;
  final double? offerOpen;
  final double? acceptance;
  final Map<String, Object?> extra;

  factory ApiRatesResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiRatesResponse(viewToOffer: _apiOptional(json, 'view_to_offer', _apiDouble), offerOpen: _apiOptional(json, 'offer_open', _apiDouble), acceptance: _apiOptional(json, 'acceptance', _apiDouble), extra: _apiExtras(json, {'view_to_offer', 'offer_open', 'acceptance'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (viewToOffer != null) 'view_to_offer': _apiEncode(viewToOffer),
      if (offerOpen != null) 'offer_open': _apiEncode(offerOpen),
      if (acceptance != null) 'acceptance': _apiEncode(acceptance),
    };
    return json;
  }
}

final class ApiRegisterRequest implements ApiJsonModel {
  @override
  String get schemaName => 'RegisterRequest';
  ApiRegisterRequest({required this.email, required this.password, required this.fullName, required this.role, this.companyName, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String email;
  final String password;
  final String fullName;
  final ApiRole role;
  final String? companyName;
  final Map<String, Object?> extra;

  factory ApiRegisterRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiRegisterRequest(email: _apiRequired(json, 'email', _apiString), password: _apiRequired(json, 'password', _apiString), fullName: _apiRequired(json, 'full_name', _apiString), role: _apiRequired(json, 'role', (value) => ApiRole.fromJson(value)), companyName: _apiOptional(json, 'company_name', _apiString), extra: _apiExtras(json, {'email', 'password', 'full_name', 'role', 'company_name'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'email': _apiEncode(email),
      'password': _apiEncode(password),
      'full_name': _apiEncode(fullName),
      'role': _apiEncode(role),
      if (companyName != null) 'company_name': _apiEncode(companyName),
    };
    _apiValidateString('password', password, min: 1, max: 128);
    _apiValidateString('full_name', fullName, min: 2, max: 200);
    _apiValidateString('company_name', companyName, max: 200);
    return json;
  }
}

final class ApiScenarioInput implements ApiJsonModel {
  @override
  String get schemaName => 'ScenarioInput';
  ApiScenarioInput({required this.name, this.description, this.role, this.interviewType, this.goals, this.durationMinutes, this.language, this.greeting, required this.questions, this.followUp, this.closing, required this.criteria, this.redFlags, this.instructions, this.tone, this.model, this.voice, this.avatarId, this.status, this.extra = const {}})
      : questions = List.unmodifiable(questions),
        criteria = List.unmodifiable(criteria),
        redFlags = redFlags == null ? null : List.unmodifiable(redFlags),
        extra = Map.unmodifiable(extra);
  final String name;
  final String? description;
  final String? role;
  final String? interviewType;
  final String? goals;
  final int? durationMinutes;
  final String? language;
  final String? greeting;
  final List<String> questions;
  final String? followUp;
  final String? closing;
  final List<ApiCriterion> criteria;
  final List<String>? redFlags;
  final String? instructions;
  final String? tone;
  final String? model;
  final String? voice;
  final String? avatarId;
  final ApiInlineStatus? status;
  final Map<String, Object?> extra;

  factory ApiScenarioInput.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiScenarioInput(name: _apiRequired(json, 'name', _apiString), description: _apiOptional(json, 'description', _apiString), role: _apiOptional(json, 'role', _apiString), interviewType: _apiOptional(json, 'interview_type', _apiString), goals: _apiOptional(json, 'goals', _apiString), durationMinutes: _apiOptional(json, 'duration_minutes', _apiInt), language: _apiOptional(json, 'language', _apiString), greeting: _apiOptional(json, 'greeting', _apiString), questions: _apiRequired(json, 'questions', (value) => _apiList(value, _apiString)), followUp: _apiOptional(json, 'follow_up', _apiString), closing: _apiOptional(json, 'closing', _apiString), criteria: _apiRequired(json, 'criteria', (value) => _apiList(value, (value) => ApiCriterion.fromJson(value))), redFlags: _apiOptional(json, 'red_flags', (value) => _apiList(value, _apiString)), instructions: _apiOptional(json, 'instructions', _apiString), tone: _apiOptional(json, 'tone', _apiString), model: _apiOptional(json, 'model', _apiString), voice: _apiOptional(json, 'voice', _apiString), avatarId: _apiOptional(json, 'avatar_id', _apiUuid), status: _apiOptional(json, 'status', (value) => ApiInlineStatus.fromJson(value)), extra: _apiExtras(json, {'name', 'description', 'role', 'interview_type', 'goals', 'duration_minutes', 'language', 'greeting', 'questions', 'follow_up', 'closing', 'criteria', 'red_flags', 'instructions', 'tone', 'model', 'voice', 'avatar_id', 'status'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'name': _apiEncode(name),
      if (description != null) 'description': _apiEncode(description),
      if (role != null) 'role': _apiEncode(role),
      if (interviewType != null) 'interview_type': _apiEncode(interviewType),
      if (goals != null) 'goals': _apiEncode(goals),
      if (durationMinutes != null) 'duration_minutes': _apiEncode(durationMinutes),
      if (language != null) 'language': _apiEncode(language),
      if (greeting != null) 'greeting': _apiEncode(greeting),
      'questions': _apiEncode(questions),
      if (followUp != null) 'follow_up': _apiEncode(followUp),
      if (closing != null) 'closing': _apiEncode(closing),
      'criteria': _apiEncode(criteria),
      if (redFlags != null) 'red_flags': _apiEncode(redFlags),
      if (instructions != null) 'instructions': _apiEncode(instructions),
      if (tone != null) 'tone': _apiEncode(tone),
      if (model != null) 'model': _apiEncode(model),
      if (voice != null) 'voice': _apiEncode(voice),
      if (avatarId != null) 'avatar_id': _apiEncode(avatarId),
      if (status != null) 'status': _apiEncode(status),
    };
    _apiValidateString('name', name, min: 1, max: 200);
    _apiValidateString('description', description, max: 4000);
    _apiValidateString('role', role, max: 200);
    _apiValidateString('interview_type', interviewType, max: 120);
    _apiValidateString('goals', goals, max: 4000);
    _apiValidateNumber('duration_minutes', durationMinutes, min: 1.0, max: 180.0);
    _apiValidateString('language', language, min: 2, max: 30);
    _apiValidateString('greeting', greeting, max: 4000);
    _apiValidateCount('questions', questions?.length, min: 1, max: 30);
    _apiValidateString('follow_up', followUp, max: 1000);
    _apiValidateString('closing', closing, max: 4000);
    _apiValidateCount('criteria', criteria?.length, min: 1, max: 20);
    _apiValidateCount('red_flags', redFlags?.length, max: 20);
    _apiValidateString('instructions', instructions, max: 8000);
    _apiValidateString('tone', tone, max: 120);
    _apiValidateString('model', model, max: 200);
    _apiValidateString('voice', voice, max: 200);
    if (avatarId != null) _apiUuid(avatarId);
    return json;
  }
}

final class ApiSecurityConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'SecurityConfiguration';
  ApiSecurityConfiguration({this.consentRequired, this.retentionDays, this.privacyNotice, this.storage, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final bool? consentRequired;
  final int? retentionDays;
  final String? privacyNotice;
  final ApiInlineStorage? storage;
  final Map<String, Object?> extra;

  factory ApiSecurityConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiSecurityConfiguration(consentRequired: _apiOptional(json, 'consent_required', _apiBool), retentionDays: _apiOptional(json, 'retention_days', _apiInt), privacyNotice: _apiOptional(json, 'privacy_notice', _apiString), storage: _apiOptional(json, 'storage', (value) => ApiInlineStorage.fromJson(value)), extra: _apiExtras(json, {'consent_required', 'retention_days', 'privacy_notice', 'storage'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (consentRequired != null) 'consent_required': _apiEncode(consentRequired),
      if (retentionDays != null) 'retention_days': _apiEncode(retentionDays),
      if (privacyNotice != null) 'privacy_notice': _apiEncode(privacyNotice),
      if (storage != null) 'storage': _apiEncode(storage),
    };
    if (consentRequired != null && consentRequired != true) throw FormatException('Invalid value for consent_required');
    _apiValidateNumber('retention_days', retentionDays, min: 1.0, max: 365.0);
    _apiValidateString('privacy_notice', privacyNotice, min: 1, max: 4000);
    return json;
  }
}

final class ApiSessionResponse implements ApiJsonModel {
  @override
  String get schemaName => 'SessionResponse';
  ApiSessionResponse({required this.user, required this.accessToken, this.tokenType, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiUserResponse user;
  final String accessToken;
  final String? tokenType;
  final Map<String, Object?> extra;

  factory ApiSessionResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiSessionResponse(user: _apiRequired(json, 'user', (value) => ApiUserResponse.fromJson(value)), accessToken: _apiRequired(json, 'access_token', _apiString), tokenType: _apiOptional(json, 'token_type', _apiString), extra: _apiExtras(json, {'user', 'access_token', 'token_type'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'user': _apiEncode(user),
      'access_token': _apiEncode(accessToken),
      if (tokenType != null) 'token_type': _apiEncode(tokenType),
    };
    return json;
  }
}

final class ApiStabilityMetricsResponse implements ApiJsonModel {
  @override
  String get schemaName => 'StabilityMetricsResponse';
  ApiStabilityMetricsResponse({required this.candidateId, required this.attemptsCount, required this.scores, required this.stabilityCv, required this.isStable, this.extra = const {}})
      : scores = List.unmodifiable(scores),
        extra = Map.unmodifiable(extra);
  final String candidateId;
  final int attemptsCount;
  final List<double> scores;
  final double stabilityCv;
  final bool isStable;
  final Map<String, Object?> extra;

  factory ApiStabilityMetricsResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiStabilityMetricsResponse(candidateId: _apiRequired(json, 'candidate_id', _apiUuid), attemptsCount: _apiRequired(json, 'attempts_count', _apiInt), scores: _apiRequired(json, 'scores', (value) => _apiList(value, _apiDouble)), stabilityCv: _apiRequired(json, 'stability_cv', _apiDouble), isStable: _apiRequired(json, 'is_stable', _apiBool), extra: _apiExtras(json, {'candidate_id', 'attempts_count', 'scores', 'stability_cv', 'is_stable'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'candidate_id': _apiEncode(candidateId),
      'attempts_count': _apiEncode(attemptsCount),
      'scores': _apiEncode(scores),
      'stability_cv': _apiEncode(stabilityCv),
      'is_stable': _apiEncode(isStable),
    };
    _apiUuid(candidateId);
    return json;
  }
}

final class ApiStartAttemptRequest implements ApiJsonModel {
  @override
  String get schemaName => 'StartAttemptRequest';
  ApiStartAttemptRequest({required this.disciplineCode, required this.targetGrade, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String disciplineCode;
  final String targetGrade;
  final Map<String, Object?> extra;

  factory ApiStartAttemptRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiStartAttemptRequest(disciplineCode: _apiRequired(json, 'discipline_code', _apiString), targetGrade: _apiRequired(json, 'target_grade', _apiString), extra: _apiExtras(json, {'discipline_code', 'target_grade'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'discipline_code': _apiEncode(disciplineCode),
      'target_grade': _apiEncode(targetGrade),
    };
    _apiValidateString('discipline_code', disciplineCode, min: 1, max: 64);
    _apiValidateString('target_grade', targetGrade, min: 1, max: 32);
    return json;
  }
}

final class ApiStartInput implements ApiJsonModel {
  @override
  String get schemaName => 'StartInput';
  ApiStartInput({required this.consent, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final bool consent;
  final Map<String, Object?> extra;

  factory ApiStartInput.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiStartInput(consent: _apiRequired(json, 'consent', _apiBool), extra: _apiExtras(json, {'consent'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'consent': _apiEncode(consent),
    };
    return json;
  }
}

final class ApiSubmitAnswerRequest implements ApiJsonModel {
  @override
  String get schemaName => 'SubmitAnswerRequest';
  ApiSubmitAnswerRequest({required this.questionId, required this.answer, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String questionId;
  final String answer;
  final Map<String, Object?> extra;

  factory ApiSubmitAnswerRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiSubmitAnswerRequest(questionId: _apiRequired(json, 'question_id', _apiUuid), answer: _apiRequired(json, 'answer', _apiString), extra: _apiExtras(json, {'question_id', 'answer'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'question_id': _apiEncode(questionId),
      'answer': _apiEncode(answer),
    };
    _apiUuid(questionId);
    _apiValidateString('answer', answer, min: 1, max: 4000);
    return json;
  }
}

final class ApiTalentCategoryResponse implements ApiJsonModel {
  @override
  String get schemaName => 'TalentCategoryResponse';
  ApiTalentCategoryResponse({required this.disciplineCode, required this.score, required this.level, this.nextLevel, this.pointsToNextLevel, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String disciplineCode;
  final double score;
  final ApiVerificationLevelResponse level;
  final ApiVerificationLevelResponse? nextLevel;
  final double? pointsToNextLevel;
  final Map<String, Object?> extra;

  factory ApiTalentCategoryResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiTalentCategoryResponse(disciplineCode: _apiRequired(json, 'discipline_code', _apiString), score: _apiRequired(json, 'score', _apiDouble), level: _apiRequired(json, 'level', (value) => ApiVerificationLevelResponse.fromJson(value)), nextLevel: _apiOptional(json, 'next_level', (value) => ApiVerificationLevelResponse.fromJson(value)), pointsToNextLevel: _apiOptional(json, 'points_to_next_level', _apiDouble), extra: _apiExtras(json, {'discipline_code', 'score', 'level', 'next_level', 'points_to_next_level'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'discipline_code': _apiEncode(disciplineCode),
      'score': _apiEncode(score),
      'level': _apiEncode(level),
      if (nextLevel != null) 'next_level': _apiEncode(nextLevel),
      if (pointsToNextLevel != null) 'points_to_next_level': _apiEncode(pointsToNextLevel),
    };
    return json;
  }
}

final class ApiTalentPoolResponse implements ApiJsonModel {
  @override
  String get schemaName => 'TalentPoolResponse';
  ApiTalentPoolResponse({required this.candidatesOpen, required this.candidatesVerified, this.verifiedShare, required this.distribution, this.extra = const {}})
      : distribution = List.unmodifiable(distribution),
        extra = Map.unmodifiable(extra);
  final int candidatesOpen;
  final int candidatesVerified;
  final double? verifiedShare;
  final List<ApiLevelBucketResponse> distribution;
  final Map<String, Object?> extra;

  factory ApiTalentPoolResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiTalentPoolResponse(candidatesOpen: _apiRequired(json, 'candidates_open', _apiInt), candidatesVerified: _apiRequired(json, 'candidates_verified', _apiInt), verifiedShare: _apiOptional(json, 'verified_share', _apiDouble), distribution: _apiRequired(json, 'distribution', (value) => _apiList(value, (value) => ApiLevelBucketResponse.fromJson(value))), extra: _apiExtras(json, {'candidates_open', 'candidates_verified', 'verified_share', 'distribution'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'candidates_open': _apiEncode(candidatesOpen),
      'candidates_verified': _apiEncode(candidatesVerified),
      if (verifiedShare != null) 'verified_share': _apiEncode(verifiedShare),
      'distribution': _apiEncode(distribution),
    };
    return json;
  }
}

final class ApiUserResponse implements ApiJsonModel {
  @override
  String get schemaName => 'UserResponse';
  ApiUserResponse({required this.id, required this.email, required this.fullName, required this.role, this.companyName, required this.createdAt, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String id;
  final String email;
  final String fullName;
  final ApiRole role;
  final String? companyName;
  final DateTime createdAt;
  final Map<String, Object?> extra;

  factory ApiUserResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiUserResponse(id: _apiRequired(json, 'id', _apiUuid), email: _apiRequired(json, 'email', _apiString), fullName: _apiRequired(json, 'full_name', _apiString), role: _apiRequired(json, 'role', (value) => ApiRole.fromJson(value)), companyName: _apiOptional(json, 'company_name', _apiString), createdAt: _apiRequired(json, 'created_at', _apiDateTime), extra: _apiExtras(json, {'id', 'email', 'full_name', 'role', 'company_name', 'created_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'email': _apiEncode(email),
      'full_name': _apiEncode(fullName),
      'role': _apiEncode(role),
      if (companyName != null) 'company_name': _apiEncode(companyName),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiVacancyCreateRequest implements ApiJsonModel {
  @override
  String get schemaName => 'VacancyCreateRequest';
  ApiVacancyCreateRequest({required this.title, required this.salaryFrom, required this.salaryTo, this.disciplineCode, this.grade, this.workFormat, this.skills, this.description, this.extra = const {}})
      : skills = skills == null ? null : List.unmodifiable(skills),
        extra = Map.unmodifiable(extra);
  final String title;
  final int salaryFrom;
  final int salaryTo;
  final String? disciplineCode;
  final ApiGrade? grade;
  final ApiWorkFormat? workFormat;
  final List<String>? skills;
  final String? description;
  final Map<String, Object?> extra;

  factory ApiVacancyCreateRequest.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVacancyCreateRequest(title: _apiRequired(json, 'title', _apiString), salaryFrom: _apiRequired(json, 'salary_from', _apiInt), salaryTo: _apiRequired(json, 'salary_to', _apiInt), disciplineCode: _apiOptional(json, 'discipline_code', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), skills: _apiOptional(json, 'skills', (value) => _apiList(value, _apiString)), description: _apiOptional(json, 'description', _apiString), extra: _apiExtras(json, {'title', 'salary_from', 'salary_to', 'discipline_code', 'grade', 'work_format', 'skills', 'description'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'title': _apiEncode(title),
      'salary_from': _apiEncode(salaryFrom),
      'salary_to': _apiEncode(salaryTo),
      if (disciplineCode != null) 'discipline_code': _apiEncode(disciplineCode),
      if (grade != null) 'grade': _apiEncode(grade),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      if (skills != null) 'skills': _apiEncode(skills),
      if (description != null) 'description': _apiEncode(description),
    };
    _apiValidateString('title', title, min: 3, max: 200);
    _apiValidateNumber('salary_from', salaryFrom, exclusiveMin: 0.0);
    _apiValidateNumber('salary_to', salaryTo, exclusiveMin: 0.0);
    _apiValidateString('discipline_code', disciplineCode, max: 64);
    _apiValidateCount('skills', skills?.length, max: 30);
    _apiValidateString('description', description, max: 4000);
    return json;
  }
}

final class ApiVacancyResponse implements ApiJsonModel {
  @override
  String get schemaName => 'VacancyResponse';
  ApiVacancyResponse({required this.id, required this.title, required this.salaryFrom, required this.salaryTo, this.disciplineCode, this.grade, this.workFormat, required this.skills, required this.description, required this.isOpen, required this.createdAt, this.extra = const {}})
      : skills = List.unmodifiable(skills),
        extra = Map.unmodifiable(extra);
  final String id;
  final String title;
  final int salaryFrom;
  final int salaryTo;
  final String? disciplineCode;
  final ApiGrade? grade;
  final ApiWorkFormat? workFormat;
  final List<String> skills;
  final String description;
  final bool isOpen;
  final DateTime createdAt;
  final Map<String, Object?> extra;

  factory ApiVacancyResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVacancyResponse(id: _apiRequired(json, 'id', _apiUuid), title: _apiRequired(json, 'title', _apiString), salaryFrom: _apiRequired(json, 'salary_from', _apiInt), salaryTo: _apiRequired(json, 'salary_to', _apiInt), disciplineCode: _apiOptional(json, 'discipline_code', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), skills: _apiRequired(json, 'skills', (value) => _apiList(value, _apiString)), description: _apiRequired(json, 'description', _apiString), isOpen: _apiRequired(json, 'is_open', _apiBool), createdAt: _apiRequired(json, 'created_at', _apiDateTime), extra: _apiExtras(json, {'id', 'title', 'salary_from', 'salary_to', 'discipline_code', 'grade', 'work_format', 'skills', 'description', 'is_open', 'created_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'title': _apiEncode(title),
      'salary_from': _apiEncode(salaryFrom),
      'salary_to': _apiEncode(salaryTo),
      if (disciplineCode != null) 'discipline_code': _apiEncode(disciplineCode),
      if (grade != null) 'grade': _apiEncode(grade),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      'skills': _apiEncode(skills),
      'description': _apiEncode(description),
      'is_open': _apiEncode(isOpen),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiVacancyWithStatsResponse implements ApiJsonModel {
  @override
  String get schemaName => 'VacancyWithStatsResponse';
  ApiVacancyWithStatsResponse({required this.id, required this.title, required this.salaryFrom, required this.salaryTo, this.disciplineCode, this.grade, this.workFormat, required this.skills, required this.description, required this.isOpen, required this.createdAt, required this.offersTotal, required this.offersAwaiting, required this.offersAccepted, this.extra = const {}})
      : skills = List.unmodifiable(skills),
        extra = Map.unmodifiable(extra);
  final String id;
  final String title;
  final int salaryFrom;
  final int salaryTo;
  final String? disciplineCode;
  final ApiGrade? grade;
  final ApiWorkFormat? workFormat;
  final List<String> skills;
  final String description;
  final bool isOpen;
  final DateTime createdAt;
  final int offersTotal;
  final int offersAwaiting;
  final int offersAccepted;
  final Map<String, Object?> extra;

  factory ApiVacancyWithStatsResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVacancyWithStatsResponse(id: _apiRequired(json, 'id', _apiUuid), title: _apiRequired(json, 'title', _apiString), salaryFrom: _apiRequired(json, 'salary_from', _apiInt), salaryTo: _apiRequired(json, 'salary_to', _apiInt), disciplineCode: _apiOptional(json, 'discipline_code', _apiString), grade: _apiOptional(json, 'grade', (value) => ApiGrade.fromJson(value)), workFormat: _apiOptional(json, 'work_format', (value) => ApiWorkFormat.fromJson(value)), skills: _apiRequired(json, 'skills', (value) => _apiList(value, _apiString)), description: _apiRequired(json, 'description', _apiString), isOpen: _apiRequired(json, 'is_open', _apiBool), createdAt: _apiRequired(json, 'created_at', _apiDateTime), offersTotal: _apiRequired(json, 'offers_total', _apiInt), offersAwaiting: _apiRequired(json, 'offers_awaiting', _apiInt), offersAccepted: _apiRequired(json, 'offers_accepted', _apiInt), extra: _apiExtras(json, {'id', 'title', 'salary_from', 'salary_to', 'discipline_code', 'grade', 'work_format', 'skills', 'description', 'is_open', 'created_at', 'offers_total', 'offers_awaiting', 'offers_accepted'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'title': _apiEncode(title),
      'salary_from': _apiEncode(salaryFrom),
      'salary_to': _apiEncode(salaryTo),
      if (disciplineCode != null) 'discipline_code': _apiEncode(disciplineCode),
      if (grade != null) 'grade': _apiEncode(grade),
      if (workFormat != null) 'work_format': _apiEncode(workFormat),
      'skills': _apiEncode(skills),
      'description': _apiEncode(description),
      'is_open': _apiEncode(isOpen),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
      'offers_total': _apiEncode(offersTotal),
      'offers_awaiting': _apiEncode(offersAwaiting),
      'offers_accepted': _apiEncode(offersAccepted),
    };
    _apiUuid(id);
    return json;
  }
}

final class ApiValidationError implements ApiJsonModel {
  @override
  String get schemaName => 'ValidationError';
  ApiValidationError({required this.loc, required this.msg, required this.type, this.input, this.ctx, this.extra = const {}})
      : loc = List.unmodifiable(loc),
        ctx = ctx == null ? null : Map.unmodifiable(ctx),
        extra = Map.unmodifiable(extra);
  final List<Object?> loc;
  final String msg;
  final String type;
  final Object? input;
  final Map<String, Object?>? ctx;
  final Map<String, Object?> extra;

  factory ApiValidationError.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiValidationError(loc: _apiRequired(json, 'loc', (value) => _apiList(value, _apiAny)), msg: _apiRequired(json, 'msg', _apiString), type: _apiRequired(json, 'type', _apiString), input: _apiOptional(json, 'input', _apiAny), ctx: _apiOptional(json, 'ctx', _apiObject), extra: _apiExtras(json, {'loc', 'msg', 'type', 'input', 'ctx'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'loc': _apiEncode(loc),
      'msg': _apiEncode(msg),
      'type': _apiEncode(type),
      if (input != null) 'input': _apiEncode(input),
      if (ctx != null) 'ctx': _apiEncode(ctx),
    };
    return json;
  }
}

final class ApiValidationReportResponse implements ApiJsonModel {
  @override
  String get schemaName => 'ValidationReportResponse';
  ApiValidationReportResponse({required this.id, required this.attemptId, required this.status, this.stabilityScore, this.discriminationScore, this.expertAgreementScore, required this.metadata, required this.createdAt, this.extra = const {}})
      : metadata = Map.unmodifiable(metadata),
        extra = Map.unmodifiable(extra);
  final String id;
  final String attemptId;
  final ApiValidationStatus status;
  final double? stabilityScore;
  final double? discriminationScore;
  final double? expertAgreementScore;
  final Map<String, double> metadata;
  final DateTime createdAt;
  final Map<String, Object?> extra;

  factory ApiValidationReportResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiValidationReportResponse(id: _apiRequired(json, 'id', _apiUuid), attemptId: _apiRequired(json, 'attempt_id', _apiUuid), status: _apiRequired(json, 'status', (value) => ApiValidationStatus.fromJson(value)), stabilityScore: _apiOptional(json, 'stability_score', _apiDouble), discriminationScore: _apiOptional(json, 'discrimination_score', _apiDouble), expertAgreementScore: _apiOptional(json, 'expert_agreement_score', _apiDouble), metadata: _apiRequired(json, 'metadata', (value) => _apiMap(value, _apiDouble)), createdAt: _apiRequired(json, 'created_at', _apiDateTime), extra: _apiExtras(json, {'id', 'attempt_id', 'status', 'stability_score', 'discrimination_score', 'expert_agreement_score', 'metadata', 'created_at'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'id': _apiEncode(id),
      'attempt_id': _apiEncode(attemptId),
      'status': _apiEncode(status),
      if (stabilityScore != null) 'stability_score': _apiEncode(stabilityScore),
      if (discriminationScore != null) 'discrimination_score': _apiEncode(discriminationScore),
      if (expertAgreementScore != null) 'expert_agreement_score': _apiEncode(expertAgreementScore),
      'metadata': _apiEncode(metadata),
      'created_at': _apiEncodeDate(createdAt, dateOnly: false),
    };
    _apiUuid(id);
    _apiUuid(attemptId);
    return json;
  }
}

final class ApiVerificationLevelResponse implements ApiJsonModel {
  @override
  String get schemaName => 'VerificationLevelResponse';
  ApiVerificationLevelResponse({required this.code, required this.label, required this.minScore, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final String code;
  final String label;
  final double minScore;
  final Map<String, Object?> extra;

  factory ApiVerificationLevelResponse.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVerificationLevelResponse(code: _apiRequired(json, 'code', _apiString), label: _apiRequired(json, 'label', _apiString), minScore: _apiRequired(json, 'min_score', _apiDouble), extra: _apiExtras(json, {'code', 'label', 'min_score'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      'code': _apiEncode(code),
      'label': _apiEncode(label),
      'min_score': _apiEncode(minScore),
    };
    return json;
  }
}

final class ApiVideoConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'VideoConfiguration';
  ApiVideoConfiguration({this.provider, this.endpoint, this.model, this.secretRef, this.temperature, this.timeoutSeconds, this.retries, this.maxTokens, this.quality, this.width, this.height, this.reconnectAttempts, this.recording, this.fallback, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiInlineProvider? provider;
  final String? endpoint;
  final String? model;
  final String? secretRef;
  final double? temperature;
  final int? timeoutSeconds;
  final int? retries;
  final int? maxTokens;
  final ApiInlineQuality? quality;
  final int? width;
  final int? height;
  final int? reconnectAttempts;
  final bool? recording;
  final String? fallback;
  final Map<String, Object?> extra;

  factory ApiVideoConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVideoConfiguration(provider: _apiOptional(json, 'provider', (value) => ApiInlineProvider.fromJson(value)), endpoint: _apiOptional(json, 'endpoint', _apiString), model: _apiOptional(json, 'model', _apiString), secretRef: _apiOptional(json, 'secret_ref', _apiString), temperature: _apiOptional(json, 'temperature', _apiDouble), timeoutSeconds: _apiOptional(json, 'timeout_seconds', _apiInt), retries: _apiOptional(json, 'retries', _apiInt), maxTokens: _apiOptional(json, 'max_tokens', _apiInt), quality: _apiOptional(json, 'quality', (value) => ApiInlineQuality.fromJson(value)), width: _apiOptional(json, 'width', _apiInt), height: _apiOptional(json, 'height', _apiInt), reconnectAttempts: _apiOptional(json, 'reconnect_attempts', _apiInt), recording: _apiOptional(json, 'recording', _apiBool), fallback: _apiOptional(json, 'fallback', _apiString), extra: _apiExtras(json, {'provider', 'endpoint', 'model', 'secret_ref', 'temperature', 'timeout_seconds', 'retries', 'max_tokens', 'quality', 'width', 'height', 'reconnect_attempts', 'recording', 'fallback'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (provider != null) 'provider': _apiEncode(provider),
      if (endpoint != null) 'endpoint': _apiEncode(endpoint),
      if (model != null) 'model': _apiEncode(model),
      if (secretRef != null) 'secret_ref': _apiEncode(secretRef),
      if (temperature != null) 'temperature': _apiEncode(temperature),
      if (timeoutSeconds != null) 'timeout_seconds': _apiEncode(timeoutSeconds),
      if (retries != null) 'retries': _apiEncode(retries),
      if (maxTokens != null) 'max_tokens': _apiEncode(maxTokens),
      if (quality != null) 'quality': _apiEncode(quality),
      if (width != null) 'width': _apiEncode(width),
      if (height != null) 'height': _apiEncode(height),
      if (reconnectAttempts != null) 'reconnect_attempts': _apiEncode(reconnectAttempts),
      if (recording != null) 'recording': _apiEncode(recording),
      if (fallback != null) 'fallback': _apiEncode(fallback),
    };
    _apiValidateString('endpoint', endpoint, max: 2048);
    _apiValidateString('model', model, max: 200);
    _apiValidateString('secret_ref', secretRef, max: 100, pattern: '^[A-Za-z0-9_-]*\$');
    _apiValidateNumber('temperature', temperature, min: 0.0, max: 2.0);
    _apiValidateNumber('timeout_seconds', timeoutSeconds, min: 1.0, max: 120.0);
    _apiValidateNumber('retries', retries, min: 0.0, max: 3.0);
    _apiValidateNumber('max_tokens', maxTokens, min: 100.0, max: 16000.0);
    _apiValidateNumber('width', width, min: 320.0, max: 1920.0);
    _apiValidateNumber('height', height, min: 240.0, max: 1080.0);
    _apiValidateNumber('reconnect_attempts', reconnectAttempts, min: 0.0, max: 10.0);
    if (recording != null && recording != false) throw FormatException('Invalid value for recording');
    if (fallback != null && fallback != 'text') throw FormatException('Invalid value for fallback');
    return json;
  }
}

final class ApiVoiceConfiguration implements ApiJsonModel {
  @override
  String get schemaName => 'VoiceConfiguration';
  ApiVoiceConfiguration({this.provider, this.endpoint, this.model, this.secretRef, this.temperature, this.timeoutSeconds, this.retries, this.maxTokens, this.voice, this.language, this.speed, this.pitch, this.fallback, this.extra = const {}})
      : extra = Map.unmodifiable(extra);
  final ApiInlineProvider? provider;
  final String? endpoint;
  final String? model;
  final String? secretRef;
  final double? temperature;
  final int? timeoutSeconds;
  final int? retries;
  final int? maxTokens;
  final String? voice;
  final String? language;
  final double? speed;
  final double? pitch;
  final String? fallback;
  final Map<String, Object?> extra;

  factory ApiVoiceConfiguration.fromJson(Object? value) {
    final json = _apiObject(value);
    final result = ApiVoiceConfiguration(provider: _apiOptional(json, 'provider', (value) => ApiInlineProvider.fromJson(value)), endpoint: _apiOptional(json, 'endpoint', _apiString), model: _apiOptional(json, 'model', _apiString), secretRef: _apiOptional(json, 'secret_ref', _apiString), temperature: _apiOptional(json, 'temperature', _apiDouble), timeoutSeconds: _apiOptional(json, 'timeout_seconds', _apiInt), retries: _apiOptional(json, 'retries', _apiInt), maxTokens: _apiOptional(json, 'max_tokens', _apiInt), voice: _apiOptional(json, 'voice', _apiString), language: _apiOptional(json, 'language', _apiString), speed: _apiOptional(json, 'speed', _apiDouble), pitch: _apiOptional(json, 'pitch', _apiDouble), fallback: _apiOptional(json, 'fallback', _apiString), extra: _apiExtras(json, {'provider', 'endpoint', 'model', 'secret_ref', 'temperature', 'timeout_seconds', 'retries', 'max_tokens', 'voice', 'language', 'speed', 'pitch', 'fallback'}));
    result.toJson();
    return result;
  }

  @override
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),
      if (provider != null) 'provider': _apiEncode(provider),
      if (endpoint != null) 'endpoint': _apiEncode(endpoint),
      if (model != null) 'model': _apiEncode(model),
      if (secretRef != null) 'secret_ref': _apiEncode(secretRef),
      if (temperature != null) 'temperature': _apiEncode(temperature),
      if (timeoutSeconds != null) 'timeout_seconds': _apiEncode(timeoutSeconds),
      if (retries != null) 'retries': _apiEncode(retries),
      if (maxTokens != null) 'max_tokens': _apiEncode(maxTokens),
      if (voice != null) 'voice': _apiEncode(voice),
      if (language != null) 'language': _apiEncode(language),
      if (speed != null) 'speed': _apiEncode(speed),
      if (pitch != null) 'pitch': _apiEncode(pitch),
      if (fallback != null) 'fallback': _apiEncode(fallback),
    };
    _apiValidateString('endpoint', endpoint, max: 2048);
    _apiValidateString('model', model, max: 200);
    _apiValidateString('secret_ref', secretRef, max: 100, pattern: '^[A-Za-z0-9_-]*\$');
    _apiValidateNumber('temperature', temperature, min: 0.0, max: 2.0);
    _apiValidateNumber('timeout_seconds', timeoutSeconds, min: 1.0, max: 120.0);
    _apiValidateNumber('retries', retries, min: 0.0, max: 3.0);
    _apiValidateNumber('max_tokens', maxTokens, min: 100.0, max: 16000.0);
    _apiValidateString('voice', voice, max: 200);
    _apiValidateString('language', language, min: 2, max: 30);
    _apiValidateNumber('speed', speed, min: 0.5, max: 2.0);
    _apiValidateNumber('pitch', pitch, min: 0.0, max: 2.0);
    if (fallback != null && fallback != 'text') throw FormatException('Invalid value for fallback');
    return json;
  }
}
