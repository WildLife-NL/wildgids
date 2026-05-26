import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wildgids/data_managers/api_client.dart';

class SightingReportSchema {
  SightingReportSchema({
    required this.humanActivityValues,
    required this.perceivedAnimalActivityValues,
  });

  final List<String> humanActivityValues;
  final List<String> perceivedAnimalActivityValues;

  static const String schemaPath = '/schemas/SightingReport.json';

  static SightingReportSchema fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    if (props is! Map) {
      throw const FormatException('SightingReport schema: missing properties');
    }
    final properties = props is Map<String, dynamic>
        ? props
        : Map<String, dynamic>.from(props);

    return SightingReportSchema(
      humanActivityValues: _enumValues(properties['humanActivity']),
      perceivedAnimalActivityValues:
          _enumValues(properties['perceivedAnimalActivity']),
    );
  }

  static List<String> _enumValues(Object? field) {
    if (field is! Map) return [];
    final map = field is Map<String, dynamic>
        ? field
        : Map<String, dynamic>.from(field);
    final values = map['enum'];
    if (values is! List) return [];
    return values.map((e) => e.toString()).toList();
  }
}

class SightingReportSchemaLoader {
  SightingReportSchemaLoader(this._apiClient);

  final ApiClient _apiClient;

  static const String _tag = 'SightingReportSchema';

  Future<SightingReportSchema> fetch() async {
    final res = await _apiClient.get(
      SightingReportSchema.schemaPath,
      authenticated: false,
    );

    final body = res.body;
    final preview = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    debugPrint(
      '[$_tag] GET ${SightingReportSchema.schemaPath} => ${res.statusCode}',
    );
    debugPrint('[$_tag] body preview: $preview');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        '[$_tag] failed (${res.statusCode}): $body',
      );
    }

    final decoded = json.decode(body);
    if (decoded is! Map) {
      throw FormatException(
        '[$_tag] expected JSON object, got ${decoded.runtimeType}',
      );
    }

    final schema = SightingReportSchema.fromJson(
      decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded),
    );

    debugPrint(
      '[$_tag] humanActivity enum (${schema.humanActivityValues.length}): '
      '${schema.humanActivityValues}',
    );
    debugPrint(
      '[$_tag] perceivedAnimalActivity enum '
      '(${schema.perceivedAnimalActivityValues.length}): '
      '${schema.perceivedAnimalActivityValues}',
    );

    return schema;
  }
}

