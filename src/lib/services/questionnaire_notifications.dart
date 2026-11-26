import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/services/questionnaire_drafts_store.dart';
import 'package:wildgids/utils/notification_service.dart';

/// Resolves the backend's time-of-day against the day of receipt, never tomorrow.
/// Explicit RFC 3339 offsets are respected; a time without an offset is local.
/// Missing or malformed values preserve the existing immediate presentation.
DateTime? questionnaireNotificationTime(
  String? notifyAfter,
  DateTime receivedAt,
) {
  final match = RegExp(
    r'^(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?(Z|[+-]\d{2}:\d{2})?$',
    caseSensitive: false,
  ).firstMatch(notifyAfter?.trim() ?? '');
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  final second = int.parse(match[3] ?? '0');
  final micros = int.parse((match[4] ?? '').padRight(6, '0'));
  if (hour > 23 || minute > 59 || second > 59) return null;

  final zone = match[5]?.toUpperCase();
  if (zone == null) {
    final local = receivedAt.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      hour,
      minute,
      second,
      micros ~/ 1000,
      micros % 1000,
    );
  }
  var offset = Duration.zero;
  if (zone != 'Z') {
    final offsetHours = int.parse(zone.substring(1, 3));
    final offsetMinutes = int.parse(zone.substring(4, 6));
    if (offsetHours > 23 || offsetMinutes > 59) return null;
    offset = Duration(hours: offsetHours, minutes: offsetMinutes);
    if (zone.startsWith('-')) offset = -offset;
  }
  final day = receivedAt.toUtc().add(offset);
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
    hour,
    minute,
    second,
    micros ~/ 1000,
    micros % 1000,
  ).subtract(offset);
}

class QuestionnaireNotifications {
  QuestionnaireNotifications({
    NotificationService? notifications,
    DateTime Function()? now,
  }) : _notifications = notifications ?? NotificationService.instance,
       _now = now ?? DateTime.now;

  static final instance = QuestionnaireNotifications();
  static const payloadPrefix = 'questionnaire:';
  final NotificationService _notifications;
  final DateTime Function() _now;
  Future<void>? _pending;

  Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _pending;
    final done = Completer<void>();
    _pending = done.future;
    return (() async {
      if (previous != null) await previous;
      try {
        return await action();
      } finally {
        if (identical(_pending, done.future)) _pending = null;
        done.complete();
      }
    })();
  }

  /// Returns whether the report flow should open the questionnaire immediately.
  Future<bool> receive(
    Questionnaire questionnaire,
    String interactionID,
  ) => _serial(() async {
    if (questionnaire.questions?.isNotEmpty != true) return false;
    final existing = await DraftsStore.getDrafts();
    DraftQuestionnaire? previous;
    for (final draft in existing) {
      if (draft.interactionID == interactionID) previous = draft;
    }
    final receivedAt = previous?.savedAt ?? _now();
    final notifyAt =
        previous?.notifyAt ??
        questionnaireNotificationTime(questionnaire.notifyAfter, receivedAt);
    final delayed = notifyAt != null && notifyAt.isAfter(_now());
    final draft = DraftQuestionnaire(
      interactionID: interactionID,
      savedAt: receivedAt,
      questionnaireJson: questionnaire.toJson(),
      notifyAt: delayed ? notifyAt : previous?.notifyAt,
      notificationID:
          previous?.notificationID ??
          (delayed ? await DraftsStore.nextNotificationID() : null),
    );
    // Persist before scheduling, so failure/denial cannot lose the questions.
    await DraftsStore.saveDraft(draft);
    if (delayed) await _schedule(draft);
    return !delayed;
  });

  Future<void> _schedule(DraftQuestionnaire draft) async {
    if (draft.notifyAt == null ||
        draft.notificationID == null ||
        !draft.notifyAt!.isAfter(_now())) {
      return;
    }
    try {
      await _notifications.schedule(
        id: draft.notificationID!,
        title: 'Nieuwe vragenlijst',
        body:
            '${draft.toQuestionnaire().name} staat klaar in je vragenlijsten.',
        scheduledAt: draft.notifyAt!,
        payload: '$payloadPrefix${draft.interactionID}',
      );
    } catch (error) {
      // Permissions/platform delivery must not turn a successful report into an
      // error or cause the user to submit the same report again.
      debugPrint('[QuestionnaireNotifications] Scheduling unavailable: $error');
    }
  }

  /// Native schedules survive app termination. Re-register future reminders
  /// using their saved IDs after restart; never turn them into daily reminders.
  Future<void> restorePending() => _serial(() async {
    for (final draft in await DraftsStore.getDrafts()) {
      await _schedule(draft);
    }
  });

  Future<void> remove(String interactionID) => _serial(() async {
    for (final draft in await DraftsStore.getDrafts()) {
      if (draft.interactionID == interactionID &&
          draft.notificationID != null) {
        await _notifications.cancel(draft.notificationID!);
      }
    }
    await DraftsStore.removeDraft(interactionID);
  });

  Future<void> cancelPending() => _serial(() async {
    for (final draft in await DraftsStore.getDrafts()) {
      if (draft.notificationID != null) {
        await _notifications.cancel(draft.notificationID!);
      }
    }
  });
}
