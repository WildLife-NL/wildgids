import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/models/api_models/questionaire.dart';

class DraftQuestionnaire {
  final String interactionID;
  final DateTime savedAt;
  final Map<String, dynamic> questionnaireJson;
  final DateTime? notifyAt;
  final int? notificationID;

  DraftQuestionnaire({
    required this.interactionID,
    required this.savedAt,
    required this.questionnaireJson,
    this.notifyAt,
    this.notificationID,
  });

  Map<String, dynamic> toJson() => {
    'interactionID': interactionID,
    'savedAt': savedAt.toIso8601String(),
    'questionnaire': questionnaireJson,
    if (notifyAt != null) 'notifyAt': notifyAt!.toIso8601String(),
    if (notificationID != null) 'notificationID': notificationID,
  };

  factory DraftQuestionnaire.fromJson(Map<String, dynamic> json) =>
      DraftQuestionnaire(
        interactionID: json['interactionID'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        questionnaireJson: Map<String, dynamic>.from(
          json['questionnaire'] as Map,
        ),
        notifyAt: DateTime.tryParse(json['notifyAt']?.toString() ?? ''),
        notificationID: json['notificationID'] as int?,
      );

  Questionnaire toQuestionnaire() => Questionnaire.fromJson(questionnaireJson);
}

/// The inbox is local, persistent, and scoped to the signed-in user. There is no
/// client-side expiry: notification timing does not limit questionnaire access.
class DraftsStore {
  static const _legacyKey = 'questionnaire_drafts';
  static Future<void>? _pending;

  // Serialize read/modify/write operations so concurrent report submissions
  // cannot overwrite one another's questionnaires.
  static Future<T> _withStore<T>(
    Future<T> Function(SharedPreferences prefs, String key) action,
  ) {
    final previous = _pending;
    final done = Completer<void>();
    _pending = done.future;
    return (() async {
      if (previous != null) await previous;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userID = prefs.getString('userID');
        final key = userID == null ? _legacyKey : '${_legacyKey}_$userID';
        if (key != _legacyKey && prefs.containsKey(_legacyKey)) {
          final legacy = prefs.getStringList(_legacyKey) ?? [];
          final current = prefs.getStringList(key) ?? [];
          await prefs.setStringList(key, [...legacy, ...current]);
          await prefs.remove(_legacyKey);
        }
        return await action(prefs, key);
      } finally {
        if (identical(_pending, done.future)) _pending = null;
        done.complete();
      }
    })();
  }

  static List<DraftQuestionnaire> _read(SharedPreferences prefs, String key) {
    final drafts = <String, DraftQuestionnaire>{};
    for (final encoded in prefs.getStringList(key) ?? <String>[]) {
      try {
        final draft = DraftQuestionnaire.fromJson(
          Map<String, dynamic>.from(jsonDecode(encoded) as Map),
        );
        drafts[draft.interactionID] = draft;
      } catch (_) {
        debugPrint('[DraftsStore] Skipping an unreadable questionnaire draft');
      }
    }
    return drafts.values.toList();
  }

  static Future<void> saveDraft(DraftQuestionnaire draft) =>
      _withStore((prefs, key) async {
        final drafts = _read(prefs, key);
        final index = drafts.indexWhere(
          (d) => d.interactionID == draft.interactionID,
        );
        if (index < 0) {
          drafts.add(draft);
        } else {
          final existing = drafts[index];
          drafts[index] = DraftQuestionnaire(
            interactionID: draft.interactionID,
            savedAt: existing.savedAt,
            questionnaireJson: draft.questionnaireJson,
            notifyAt: draft.notifyAt ?? existing.notifyAt,
            notificationID: draft.notificationID ?? existing.notificationID,
          );
        }
        await prefs.setStringList(
          key,
          drafts.map((d) => jsonEncode(d.toJson())).toList(),
        );
      });

  static Future<List<DraftQuestionnaire>> getDrafts() =>
      _withStore((prefs, key) async => _read(prefs, key));

  static Future<int> nextNotificationID() => _withStore((prefs, _) async {
    // Separate from the timestamp IDs used by immediate notifications.
    final id = prefs.getInt('next_questionnaire_notification_id') ?? 0x40000000;
    await prefs.setInt('next_questionnaire_notification_id', id + 1);
    return id;
  });

  static Future<void> removeDraft(String interactionID) =>
      _withStore((prefs, key) async {
        final drafts = _read(prefs, key)
          ..removeWhere((d) => d.interactionID == interactionID);
        await prefs.setStringList(
          key,
          drafts.map((d) => jsonEncode(d.toJson())).toList(),
        );
      });
}
