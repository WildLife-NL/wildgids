import 'dart:convert';

import 'package:wildgids/interfaces/reporting/reportable_interface.dart';

/// Preserves the submitted API payload when a sighting is queued offline.
class CachedSightingReport implements Reportable {
  CachedSightingReport(Map<String, dynamic> payload)
    : _encodedPayload = jsonEncode(payload);

  final String _encodedPayload;

  @override
  Map<String, dynamic> toJson() =>
      jsonDecode(_encodedPayload) as Map<String, dynamic>;
}
