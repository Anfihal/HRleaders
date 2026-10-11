#!/usr/bin/env python3
"""Generate typed Dart transport models and operation metadata from api (2).json."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "api (2).json"
MODELS = ROOT / "lib" / "core" / "models" / "api_models.dart"
OPERATIONS = ROOT / "lib" / "core" / "network" / "api_v1_contract.dart"
COMPONENT_PREFIX = "#/components/schemas/"


def pascal(value: str) -> str:
    return "".join(part[:1].upper() + part[1:] for part in re.split(r"[^A-Za-z0-9]+", value) if part)


def camel(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value)
    return parts[0].lower() + "".join(part[:1].upper() + part[1:] for part in parts[1:] if part)


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )
    return f"'{escaped}'"


def dart_literal(value: Any) -> str:
    if isinstance(value, str):
        return dart_string(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return repr(value)
    raise TypeError(f"Unsupported OpenAPI constant: {value!r}")


def non_null_schema(schema: dict[str, Any]) -> tuple[dict[str, Any], bool]:
    if schema.get("nullable") is True:
        return schema, True
    if isinstance(schema.get("type"), list):
        types = [value for value in schema["type"] if value != "null"]
        if len(types) == 1:
            return {**schema, "type": types[0]}, len(types) != len(schema["type"])
    branches = schema.get("anyOf") or schema.get("oneOf")
    if not branches:
        return schema, False
    non_null = [branch for branch in branches if branch.get("type") != "null"]
    if len(non_null) == 1:
        return non_null[0], len(non_null) != len(branches)
    return {"x-dynamic": True}, len(non_null) != len(branches)


def main() -> None:
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    schemas: dict[str, dict[str, Any]] = spec["components"]["schemas"]
    enum_types: dict[tuple[str, ...], str] = {}
    for name, schema in schemas.items():
        if "enum" in schema:
            enum_types[tuple(schema["enum"])] = f"Api{pascal(name)}"
    used_enum_names = set(enum_types.values())
    for schema_name, schema in schemas.items():
        for prop_name, prop in schema.get("properties", {}).items():
            candidate, _ = non_null_schema(prop)
            values = candidate.get("enum")
            if values:
                key = tuple(values)
                if key not in enum_types:
                    enum_name = f"ApiInline{pascal(prop_name)}"
                    if enum_name in used_enum_names:
                        enum_name = f"{enum_name}For{pascal(schema_name)}"
                    enum_types[key] = enum_name
                    used_enum_names.add(enum_name)

    def type_info(raw: dict[str, Any]) -> tuple[str, str, bool]:
        schema, nullable = non_null_schema(raw)
        ref = schema.get("$ref")
        if ref:
            name = ref.removeprefix(COMPONENT_PREFIX)
            enum_values = schemas.get(name, {}).get("enum")
            if enum_values is not None:
                return enum_types[tuple(enum_values)], "enum", nullable
            return f"Api{pascal(name)}", "model", nullable
        enum_values = schema.get("enum")
        if enum_values:
            return enum_types[tuple(enum_values)], "enum", nullable
        kind = schema.get("type")
        fmt = schema.get("format")
        if fmt in ("date", "date-time"):
            return "DateTime", "date", nullable
        if kind == "array":
            item_type, item_kind, item_nullable = type_info(schema.get("items", {}))
            if item_nullable and not item_type.endswith("?"):
                item_type += "?"
            return f"List<{item_type}>", f"list:{item_kind}", nullable
        if kind == "object" or "additionalProperties" in schema:
            additional = schema.get("additionalProperties")
            if isinstance(additional, dict):
                value_type, value_kind, value_nullable = type_info(additional)
                if value_nullable and not value_type.endswith("?"):
                    value_type += "?"
                return f"Map<String, {value_type}>", f"map:{value_kind}", nullable
            return "Map<String, Object?>", "map:any", nullable
        return {
            "string": "String",
            "integer": "int",
            "number": "double",
            "boolean": "bool",
        }.get(kind, "Object?"), {
            "string": "string",
            "integer": "integer",
            "number": "number",
            "boolean": "boolean",
        }.get(kind, "any"), nullable

    def decoder(raw: dict[str, Any]) -> str:
        schema, _ = non_null_schema(raw)
        ref = schema.get("$ref")
        if ref:
            name = ref.removeprefix(COMPONENT_PREFIX)
            if "enum" in schemas.get(name, {}):
                return f"(value) => Api{pascal(name)}.fromJson(value)"
            return f"(value) => Api{pascal(name)}.fromJson(value)"
        if schema.get("enum"):
            return f"(value) => {enum_types[tuple(schema['enum'])]}.fromJson(value)"
        kind = schema.get("type")
        if kind == "array":
            item = schema.get("items", {})
            item_decoder = decoder(item)
            return f"(value) => _apiList(value, {item_decoder})"
        if kind == "object" or "additionalProperties" in schema:
            additional = schema.get("additionalProperties")
            if isinstance(additional, dict):
                item_decoder = decoder(additional)
                return f"(value) => _apiMap(value, {item_decoder})"
            return "_apiObject"
        fmt = schema.get("format")
        if fmt == "uuid":
            return "_apiUuid"
        if fmt == "date":
            return "_apiDateOnly"
        if fmt == "date-time":
            return "_apiDateTime"
        return {
            "string": "_apiString",
            "integer": "_apiInt",
            "number": "_apiDouble",
            "boolean": "_apiBool",
        }.get(kind, "_apiAny")

    out = [
        "// GENERATED from api (2).json by tool/generate_api_contract.py.",
        "// Do not edit by hand; regenerate after changing the OpenAPI contract.",
        "",
        "typedef ApiDynamicObject = Map<String, Object?>;",
        "",
        "abstract interface class ApiJsonModel {",
        "  String get schemaName;",
        "  Map<String, Object?> toJson();",
        "}",
        "",
        "abstract interface class ApiEnumValue {",
        "  String toJson();",
        "}",
        "",
        "Map<String, Object?> _apiObject(Object? value) {",
        "  if (value is! Map) throw FormatException('Expected a JSON object');",
        "  final result = <String, Object?>{};",
        "  for (final entry in value.entries) {",
        "    if (entry.key is! String) throw FormatException('Expected string object keys');",
        "    result[entry.key as String] = entry.value;",
        "  }",
        "  return result;",
        "}",
        "",
        "Object? _apiAny(Object? value) => value;",
        "String _apiString(Object? value) => value is String ? value : throw FormatException('Expected a string');",
        "String _apiUuid(Object? value) {",
        "  final result = _apiString(value);",
        "  if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(result)) {",
        "    throw FormatException('Expected a UUID');",
        "  }",
        "  return result;",
        "}",
        "int _apiInt(Object? value) => value is int ? value : throw FormatException('Expected an integer');",
        "double _apiDouble(Object? value) => value is num ? value.toDouble() : throw FormatException('Expected a number');",
        "bool _apiBool(Object? value) => value is bool ? value : throw FormatException('Expected a boolean');",
        "DateTime _apiDateTime(Object? value) {",
        "  final parsed = DateTime.tryParse(_apiString(value));",
        "  if (parsed == null) throw FormatException('Expected an ISO-8601 date');",
        "  return parsed;",
        "}",
        "DateTime _apiDateOnly(Object? value) {",
        "  final result = _apiString(value);",
        "  if (!RegExp(r'^\\d{4}-\\d{2}-\\d{2}$').hasMatch(result)) throw FormatException('Expected an ISO date');",
        "  final parsed = DateTime.tryParse(result);",
        "  if (parsed == null || parsed.toIso8601String().split('T').first != result) throw FormatException('Expected an ISO date');",
        "  return parsed;",
        "}",
        "String _apiEncodeDate(DateTime value, {required bool dateOnly}) =>",
        "    dateOnly ? value.toIso8601String().split('T').first : value.toIso8601String();",
        "T _apiRequired<T>(Map<String, Object?> json, String key, T Function(Object?) decode) {",
        "  if (!json.containsKey(key) || json[key] == null) throw FormatException('Missing required field: $key');",
        "  return decode(json[key]);",
        "}",
        "T? _apiOptional<T>(Map<String, Object?> json, String key, T Function(Object?) decode) {",
        "  final value = json[key];",
        "  return value == null ? null : decode(value);",
        "}",
        "List<T> _apiList<T>(Object? value, T Function(Object?) decode) {",
        "  if (value is! List) throw FormatException('Expected a JSON array');",
        "  return List<T>.unmodifiable(value.map(decode));",
        "}",
        "Map<String, T> _apiMap<T>(Object? value, T Function(Object?) decode) {",
        "  final json = _apiObject(value);",
        "  return Map<String, T>.unmodifiable(json.map((key, value) => MapEntry(key, decode(value))));",
        "}",
        "Map<String, Object?> _apiExtras(Map<String, Object?> json, Set<String> known) =>",
        "    Map<String, Object?>.unmodifiable(Map.fromEntries(json.entries.where((entry) => !known.contains(entry.key))));",
        "Object? _apiEncode(Object? value) {",
        "  if (value == null || value is String || value is num || value is bool) return value;",
        "  if (value is ApiJsonModel) return value.toJson();",
        "  if (value is ApiEnumValue) return value.toJson();",
        "  if (value is DateTime) return value.toIso8601String();",
        "  if (value is List) return value.map(_apiEncode).toList(growable: false);",
        "  if (value is Map) {",
        "    final result = <String, Object?>{};",
        "    for (final entry in value.entries) {",
        "      if (entry.key is! String) throw FormatException('Expected string object keys');",
        "      result[entry.key as String] = _apiEncode(entry.value);",
        "    }",
        "    return result;",
        "  }",
        "  throw FormatException('Unsupported JSON value: ${value.runtimeType}');",
        "}",
        "void _apiValidateString(String name, String? value, {int? min, int? max, String? pattern}) {",
        "  if (value == null) return;",
        "  if ((min != null && value.length < min) || (max != null && value.length > max) ||",
        "      (pattern != null && !RegExp(pattern).hasMatch(value))) {",
        "    throw FormatException('Invalid value for $name');",
        "  }",
        "}",
        "void _apiValidateNumber(String name, num? value, {num? min, num? max, num? exclusiveMin, num? exclusiveMax}) {",
        "  if (value == null) return;",
        "  if ((min != null && value < min) || (max != null && value > max) ||",
        "      (exclusiveMin != null && value <= exclusiveMin) ||",
        "      (exclusiveMax != null && value >= exclusiveMax)) {",
        "    throw FormatException('Invalid value for $name');",
        "  }",
        "}",
        "void _apiValidateCount(String name, int? value, {int? min, int? max}) {",
        "  if (value == null) return;",
        "  if ((min != null && value < min) || (max != null && value > max)) {",
        "    throw FormatException('Invalid item count for $name');",
        "  }",
        "}",
        "",
    ]

    # Inline and component enums use their exact wire values, not Dart enum names.
    all_enums: dict[str, tuple[str, ...]] = {}
    for name, schema in schemas.items():
        if "enum" in schema:
            all_enums[enum_types[tuple(schema["enum"])]] = tuple(schema["enum"])
    for values, enum_name in enum_types.items():
        all_enums[enum_name] = values
    for enum_name, values in all_enums.items():
        out.append(f"enum {enum_name} implements ApiEnumValue {{")
        members = []
        for value in values:
            member = re.sub(r"[^A-Za-z0-9_]", "_", value)
            if not member or member[0].isdigit():
                member = f"value_{member}"
            if member in {"default", "switch", "case", "class", "enum", "extension", "in", "is", "new", "operator", "return", "this", "throw", "try", "while"}:
                member = f"value_{member}"
            members.append((member, value))
        out.append("  " + ", ".join(f"{member}({dart_string(value)})" for member, value in members) + ";")
        out.append("  const " + enum_name + "(this.value);")
        out.append("  final String value;")
        out.append("  @override")
        out.append("  String toJson() => value;")
        out.append("  static " + enum_name + " fromJson(Object? value) => values.firstWhere(")
        out.append("    (item) => item.value == value,")
        out.append("    orElse: () => throw FormatException('Unknown " + enum_name + ": $value'),")
        out.append("  );")
        out.append("}")
        out.append("")

    # Component DTOs identify their wire schema so an operation cannot send a
    # valid but unrelated request model by mistake.
    for name, schema in schemas.items():
        if "enum" in schema or not schema.get("properties"):
            continue
        class_name = f"Api{pascal(name)}"
        props: dict[str, dict[str, Any]] = schema.get("properties", {})
        required = set(schema.get("required", []))
        fields: list[tuple[str, str, str, dict[str, Any], bool]] = []
        for prop_name, prop_schema in props.items():
            dart_name = camel(prop_name)
            field_type, kind, nullable = type_info(prop_schema)
            is_required = prop_name in required and not nullable
            if nullable or not is_required:
                if field_type != "Object?":
                    field_type += "?"
            fields.append((prop_name, dart_name, field_type, prop_schema, is_required))

        out.append(f"final class {class_name} implements ApiJsonModel {{")
        out.append(f"  @override")
        out.append(f"  String get schemaName => {dart_string(name)};")
        constructor_fields = [f"required this.{field}" if is_required else f"this.{field}" for _, field, _, _, is_required in fields]
        constructor_fields.append("this.extra = const {}")
        out.append(f"  {class_name}({{{', '.join(constructor_fields)}}})")
        initializers = []
        for prop_name, field, field_type, prop_schema, is_required in fields:
            schema_value, _ = non_null_schema(prop_schema)
            base_type, kind, _ = type_info(prop_schema)
            if kind.startswith("list:"):
                initializers.append(f"{field} = {field} == null ? null : List.unmodifiable({field})" if field_type.endswith("?") else f"{field} = List.unmodifiable({field})")
            elif kind.startswith("map:"):
                initializers.append(f"{field} = {field} == null ? null : Map.unmodifiable({field})" if field_type.endswith("?") else f"{field} = Map.unmodifiable({field})")
        initializers.append("extra = Map.unmodifiable(extra)")
        out.append("      : " + ",\n        ".join(initializers) + ";")
        for _, field, field_type, _, _ in fields:
            out.append(f"  final {field_type} {field};")
        out.append("  final Map<String, Object?> extra;")
        out.append("")
        out.append(f"  factory {class_name}.fromJson(Object? value) {{")
        out.append("    final json = _apiObject(value);")
        args = []
        for prop_name, field, _, prop_schema, is_required in fields:
            args.append(f"{field}: _api{'Required' if is_required else 'Optional'}(json, {dart_string(prop_name)}, {decoder(prop_schema)})")
        known = ", ".join(dart_string(field[0]) for field in fields)
        args.append(f"extra: _apiExtras(json, {{{known}}})")
        out.append(f"    final result = {class_name}({', '.join(args)});")
        out.append("    result.toJson();")
        out.append("    return result;")
        out.append("  }")
        out.append("")
        out.append("  @override")
        out.append("  Map<String, Object?> toJson() {")
        out.append("    final json = <String, Object?>{")
        out.append("      ...extra.map((key, value) => MapEntry(key, _apiEncode(value))),")
        for prop_name, field, _, prop_schema, is_required in fields:
            prop, _ = non_null_schema(prop_schema)
            value = (
                f"_apiEncodeDate({field}, dateOnly: {'true' if prop.get('format') == 'date' else 'false'})"
                if prop.get("format") in ("date", "date-time")
                else f"_apiEncode({field})"
            )
            if is_required:
                out.append(f"      {dart_string(prop_name)}: {value},")
            else:
                out.append(f"      if ({field} != null) {dart_string(prop_name)}: {value},")
        out.append("    };")
        for prop_name, field, field_type, prop_schema, _ in fields:
            prop, nullable = non_null_schema(prop_schema)
            if prop.get("type") == "string":
                args = []
                if "minLength" in prop:
                    args.append(f"min: {int(prop['minLength'])}")
                if "maxLength" in prop:
                    args.append(f"max: {int(prop['maxLength'])}")
                if "pattern" in prop:
                    args.append(f"pattern: {dart_string(prop['pattern'])}")
                if args:
                    out.append(f"    _apiValidateString({dart_string(prop_name)}, {field}, {', '.join(args)});")
            if prop.get("type") in ("integer", "number"):
                args = []
                for key, target in (("minimum", "min"), ("maximum", "max"), ("exclusiveMinimum", "exclusiveMin"), ("exclusiveMaximum", "exclusiveMax")):
                    if key in prop:
                        args.append(f"{target}: {prop[key]}")
                if args:
                    out.append(f"    _apiValidateNumber({dart_string(prop_name)}, {field}, {', '.join(args)});")
            if prop.get("type") == "array" and ("minItems" in prop or "maxItems" in prop):
                args = []
                if "minItems" in prop:
                    args.append(f"min: {prop['minItems']}")
                if "maxItems" in prop:
                    args.append(f"max: {prop['maxItems']}")
                out.append(f"    _apiValidateCount({dart_string(prop_name)}, {field}?.length, {', '.join(args)});")
            if prop.get("type") == "array" and prop.get("items", {}).get("format") == "uuid":
                if field_type.endswith("?"):
                    out.append(f"    if ({field} != null) for (final item in {field}) _apiUuid(item);")
                else:
                    out.append(f"    for (final item in {field}) _apiUuid(item);")
            if "const" in prop:
                out.append(f"    if ({field} != null && {field} != {dart_literal(prop['const'])}) throw FormatException('Invalid value for {prop_name}');")
            if prop.get("format") == "uuid":
                if is_required:
                    out.append(f"    _apiUuid({field});")
                else:
                    out.append(f"    if ({field} != null) _apiUuid({field});")
        out.append("    return json;")
        out.append("  }")
        out.append("}")
        out.append("")

    MODELS.parent.mkdir(parents=True, exist_ok=True)
    MODELS.write_text("\n".join(out), encoding="utf-8")

    operation_lines = [
        "// GENERATED from api (2).json by tool/generate_api_contract.py.",
        "// Do not edit by hand; regenerate after changing the OpenAPI contract.",
        "import '../models/api_models.dart';",
        "import 'api_client.dart';",
        "",
        "final class ApiParameter {",
        "  const ApiParameter({",
        "    this.type,",
        "    this.format,",
        "    this.allowedValues = const {},",
        "    this.minLength,",
        "    this.maxLength,",
        "    this.minimum,",
        "    this.maximum,",
        "    this.exclusiveMinimum,",
        "    this.exclusiveMaximum,",
        "    this.pattern,",
        "  });",
        "  final String? type;",
        "  final String? format;",
        "  final Set<String> allowedValues;",
        "  final int? minLength;",
        "  final int? maxLength;",
        "  final num? minimum;",
        "  final num? maximum;",
        "  final num? exclusiveMinimum;",
        "  final num? exclusiveMaximum;",
        "  final String? pattern;",
        "",
        "  void validate(String name, String value) {",
        "    if (format == 'uuid' && !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(value)) {",
        "      throw ArgumentError.value(value, name, 'Expected a UUID');",
        "    }",
        "    if (type == 'string' &&",
        "        ((minLength != null && value.length < minLength!) ||",
        "         (maxLength != null && value.length > maxLength!) ||",
        "         (pattern != null && !RegExp(pattern!).hasMatch(value)))) {",
        "      throw ArgumentError.value(value, name, 'Value does not match the OpenAPI constraint');",
        "    }",
        "    if (type == 'integer' && int.tryParse(value) == null) {",
        "      throw ArgumentError.value(value, name, 'Expected an integer');",
        "    }",
        "    if (type == 'number' && num.tryParse(value) == null) {",
        "      throw ArgumentError.value(value, name, 'Expected a number');",
        "    }",
        "    if (type == 'boolean' && value != 'true' && value != 'false') {",
        "      throw ArgumentError.value(value, name, 'Expected a boolean');",
        "    }",
        "    if (allowedValues.isNotEmpty && !allowedValues.contains(value)) {",
        "      throw ArgumentError.value(value, name, 'Value is not an allowed enum member');",
        "    }",
        "    final numericValue = num.tryParse(value);",
        "    if (numericValue != null &&",
        "        ((minimum != null && numericValue < minimum!) ||",
        "         (maximum != null && numericValue > maximum!) ||",
        "         (exclusiveMinimum != null && numericValue <= exclusiveMinimum!) ||",
        "         (exclusiveMaximum != null && numericValue >= exclusiveMaximum!))) {",
        "      throw ArgumentError.value(value, name, 'Value is outside the OpenAPI range');",
        "    }",
        "  }",
        "}",
        "",
        "final class ApiOperation {",
        "  const ApiOperation({",
        "    required this.method,",
        "    required this.pathTemplate,",
        "    required this.pathParameters,",
        "    required this.queryParameters,",
        "    required this.requiredQueryParameters,",
        "    required this.acceptsBody,",
        "    required this.requiredBody,",
        "    required this.requestBodySchema,",
        "    required this.pathParameterRules,",
        "    required this.queryParameterRules,",
        "    required this.successStatuses,",
        "    required this.errorStatuses,",
        "  });",
        "  final String method;",
        "  final String pathTemplate;",
        "  final Set<String> pathParameters;",
        "  final Set<String> queryParameters;",
        "  final Set<String> requiredQueryParameters;",
        "  final bool acceptsBody;",
        "  final bool requiredBody;",
        "  final String? requestBodySchema;",
        "  final Map<String, ApiParameter> pathParameterRules;",
        "  final Map<String, ApiParameter> queryParameterRules;",
        "  final Set<int> successStatuses;",
        "  final Set<int> errorStatuses;",
        "",
        "  String resolvePath(Map<String, String> values) {",
        "    if (!values.keys.toSet().containsAll(pathParameters) ||",
        "        !pathParameters.containsAll(values.keys)) {",
        "      throw ArgumentError.value(values, 'pathParameters', 'Path parameters do not match the OpenAPI operation');",
        "    }",
        "    var path = pathTemplate;",
        "    for (final name in pathParameters) {",
        "      final value = values[name]!;",
        "      if (value.isEmpty) throw ArgumentError.value(value, name, 'Path values must not be empty');",
        "      pathParameterRules[name]?.validate(name, value);",
        "      path = path.replaceAll('{$name}', Uri.encodeComponent(value));",
        "    }",
        "    return path;",
        "  }",
        "",
        "  void validate({",
        "    required Map<String, String> pathParameters,",
        "    required Map<String, String> query,",
        "    required Object? body,",
        "  }) {",
        "    resolvePath(pathParameters);",
        "    final unknownQuery = query.keys.toSet().difference(queryParameters);",
        "    if (unknownQuery.isNotEmpty) throw ArgumentError.value(unknownQuery, 'query', 'Unsupported query parameters');",
        "    final missingQuery = requiredQueryParameters.difference(query.keys.toSet());",
        "    if (missingQuery.isNotEmpty) throw ArgumentError.value(missingQuery, 'query', 'Missing required query parameters');",
        "    for (final entry in query.entries) {",
        "      queryParameterRules[entry.key]?.validate(entry.key, entry.value);",
        "    }",
        "    if (!acceptsBody && body != null) throw ArgumentError.value(body, 'body', 'This operation does not accept a request body');",
        "    if (requiredBody && body == null) throw ArgumentError.notNull('body');",
        "    if (body != null && requestBodySchema != null &&",
        "        (body is! ApiJsonModel || body.schemaName != requestBodySchema)) {",
        "      throw ArgumentError.value(body, 'body', 'Expected the $requestBodySchema request model');",
        "    }",
        "    if (body != null && requestBodySchema == null &&",
        "        body is! ApiJsonModel && body is! Map) {",
        "      throw ArgumentError.value(body, 'body', 'Expected a JSON object');",
        "    }",
        "  }",
        "}",
        "",
        "final Map<String, ApiOperation> apiV1Operations = Map<String, ApiOperation>.unmodifiable({",
    ]

    seen_operation_ids: set[str] = set()

    def parameter_rule(parameter: dict[str, Any]) -> str:
        schema, _ = non_null_schema(parameter.get("schema", {}))
        ref = schema.get("$ref")
        if ref:
            enum_schema = schemas.get(ref.removeprefix(COMPONENT_PREFIX), {})
            schema_type = enum_schema.get("type", "string")
            enum_values = enum_schema.get("enum", [])
            schema = {**schema, "type": schema_type, "enum": enum_values}
        values = schema.get("enum", [])
        fields = [f"type: {dart_string(schema['type'])}"] if schema.get("type") else []
        if schema.get("format"):
            fields.append(f"format: {dart_string(schema['format'])}")
        if values:
            fields.append("allowedValues: const {" + ", ".join(dart_string(v) for v in values) + "}")
        for source, target in (
            ("minLength", "minLength"),
            ("maxLength", "maxLength"),
            ("minimum", "minimum"),
            ("maximum", "maximum"),
            ("exclusiveMinimum", "exclusiveMinimum"),
            ("exclusiveMaximum", "exclusiveMaximum"),
        ):
            if source in schema:
                fields.append(f"{target}: {dart_literal(schema[source])}")
        if schema.get("pattern"):
            fields.append(f"pattern: {dart_string(schema['pattern'])}")
        return f"ApiParameter({', '.join(fields)})"

    for path, path_item in spec["paths"].items():
        for method, operation in path_item.items():
            if method.lower() not in {"get", "post", "put", "patch", "delete"}:
                continue
            path_params = sorted(set(re.findall(r"{([^}]+)}", path)))
            path_rules = {
                p["name"]: parameter_rule(p)
                for p in operation.get("parameters", [])
                if p.get("in") == "path"
            }
            query_rules = {
                p["name"]: parameter_rule(p)
                for p in operation.get("parameters", [])
                if p.get("in") == "query"
            }
            query_params = sorted(query_rules)
            required_query = sorted(p["name"] for p in operation.get("parameters", []) if p.get("in") == "query" and p.get("required"))
            body = operation.get("requestBody")
            body_schema = (
                body.get("content", {}).get("application/json", {}).get("schema", {})
                if body
                else {}
            )
            body_schema_name = (
                body_schema.get("$ref", "").removeprefix(COMPONENT_PREFIX)
                or None
            )
            successes = sorted(int(status) for status in operation.get("responses", {}) if status.isdigit() and 200 <= int(status) < 300)
            errors = sorted(int(status) for status in operation.get("responses", {}) if status.isdigit() and int(status) >= 400)
            operation_id = operation.get("operationId")
            if not operation_id:
                raise ValueError(f"Operation has no operationId: {method} {path}")
            if operation_id in seen_operation_ids:
                raise ValueError(f"Duplicate operationId: {operation_id}")
            seen_operation_ids.add(operation_id)
            if path.startswith("/api/v1/"):
                runtime_path = path.removeprefix("/api/v1/")
            else:
                runtime_path = path
            operation_lines.extend([
                f"  {dart_string(operation_id)}: ApiOperation(",
                f"    method: {dart_string(method.upper())},",
                f"    pathTemplate: {dart_string(runtime_path)},",
                f"    pathParameters: const {{{', '.join(dart_string(v) for v in path_params)}}},",
                f"    queryParameters: const {{{', '.join(dart_string(v) for v in query_params)}}},",
                f"    requiredQueryParameters: const {{{', '.join(dart_string(v) for v in required_query)}}},",
                f"    acceptsBody: {'true' if body else 'false'},",
                f"    requiredBody: {'true' if body and body.get('required') else 'false'},",
                f"    requestBodySchema: {dart_string(body_schema_name) if body_schema_name else 'null'},",
                "    pathParameterRules: const {" + ", ".join(
                    f"{dart_string(name)}: {rule}" for name, rule in path_rules.items()
                ) + "},",
                "    queryParameterRules: const {" + ", ".join(
                    f"{dart_string(name)}: {rule}" for name, rule in query_rules.items()
                ) + "},",
                f"    successStatuses: const {{{', '.join(map(str, successes))}}},",
                f"    errorStatuses: const {{{', '.join(map(str, errors))}}},",
                "  ),",
            ])
    operation_lines.extend([
        "});",
        "",
        "final class ApiV1Client {",
        "  const ApiV1Client(this._client);",
        "  final ApiClient _client;",
        "",
        "  Future<T> execute<T>(",
        "    String operationId, {",
        "    Map<String, String> pathParameters = const {},",
        "    Map<String, String> query = const {},",
        "    Object? body,",
        "    required T Function(Object?) decode,",
        "  }) async {",
        "    final operation = _operation(operationId);",
        "    operation.validate(pathParameters: pathParameters, query: query, body: body);",
        "    final payload = _bodyJson(body);",
        "    final result = await _client.request(",
        "      operation.method,",
        "      operation.resolvePath(pathParameters),",
        "      body: payload,",
        "      query: query.isEmpty ? null : query,",
        "    );",
        "    return decode(result);",
        "  }",
        "",
        "  Future<void> executeNoContent(",
        "    String operationId, {",
        "    Map<String, String> pathParameters = const {},",
        "    Map<String, String> query = const {},",
        "    Object? body,",
        "  }) async {",
        "    final operation = _operation(operationId);",
        "    operation.validate(pathParameters: pathParameters, query: query, body: body);",
        "    await _client.request(",
        "      operation.method,",
        "      operation.resolvePath(pathParameters),",
        "      body: _bodyJson(body),",
        "      query: query.isEmpty ? null : query,",
        "    );",
        "  }",
        "",
        "  ApiOperation _operation(String id) => apiV1Operations[id] ??",
        "      (throw ArgumentError.value(id, 'operationId', 'Unknown OpenAPI operation'));",
        "",
        "  Map<String, Object?>? _bodyJson(Object? body) {",
        "    if (body == null) return null;",
        "    if (body is ApiJsonModel) return body.toJson();",
        "    if (body is Map) return _apiMapObject(body);",
        "    throw ArgumentError.value(body, 'body', 'Expected an API model or JSON object');",
        "  }",
        "}",
        "",
        "Map<String, Object?> _apiMapObject(Map value) {",
        "  final result = <String, Object?>{};",
        "  for (final entry in value.entries) {",
        "    if (entry.key is! String) throw ArgumentError.value(entry.key, 'body', 'Expected string object keys');",
        "    result[entry.key as String] = entry.value;",
        "  }",
        "  return result;",
        "}",
        "",
    ])
    OPERATIONS.parent.mkdir(parents=True, exist_ok=True)
    OPERATIONS.write_text("\n".join(operation_lines), encoding="utf-8")
    print(
        f"Generated {len([s for s in schemas.values() if 'enum' in s])} enum schemas, "
        f"{len([s for s in schemas.values() if 'properties' in s and 'enum' not in s])} object schemas, "
        f"{sum(1 for item in spec['paths'].values() for method in item if method.lower() in {'get','post','put','patch','delete'})} operations."
    )


if __name__ == "__main__":
    main()
