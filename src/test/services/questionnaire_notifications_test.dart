import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/services/questionnaire_drafts_store.dart';
import 'package:wildgids/services/questionnaire_notifications.dart';
import 'package:wildgids/utils/notification_service.dart';

class RecordingNotifications extends NotificationService {
  final scheduled = <int, ({DateTime at, String payload})>{};
  final cancelled = <int>[];
  bool failScheduling = false;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (failScheduling) throw StateError('Notifications unavailable');
    if (pushEnabled) scheduled[id] = (at: scheduledAt, payload: payload);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }
}

Questionnaire questionnaire({String? notifyAfter}) => Questionnaire.fromJson({
  'ID': 'questionnaire-1',
  'name': 'Hoe was je wandeling?',
  if (notifyAfter != null) 'notifyAfter': notifyAfter,
  'questions': [
    {
      'ID': 'question-1',
      'text': 'Wat heb je gezien?',
      'description': 'Vertel over je wandeling.',
      'index': 1,
      'allowMultipleResponse': false,
      'allowOpenResponse': true,
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backend time of day', () {
    final afternoon = DateTime.utc(2026, 11, 18, 14);

    test(
      'preserves notifyAfter through API parsing and local serialization',
      () {
        final q = questionnaire(notifyAfter: '18:00:00+01:00');
        expect(
          Questionnaire.fromJson(q.toJson()).notifyAfter,
          '18:00:00+01:00',
        );
      },
    );

    test('resolves an explicit offset to an absolute instant', () {
      expect(
        questionnaireNotificationTime('18:00:00+01:00', afternoon),
        DateTime.utc(2026, 11, 18, 17),
      );
      expect(
        questionnaireNotificationTime('18:00:00-02:30', afternoon),
        DateTime.utc(2026, 11, 18, 20, 30),
      );
    });

    test('uses the date in the supplied offset around midnight', () {
      expect(
        questionnaireNotificationTime(
          '01:00:00+02:00',
          DateTime.utc(2026, 11, 18, 23, 30),
        ),
        DateTime.utc(2026, 11, 18, 23),
      );
    });

    test('uses device local time for an unzoned clock time', () {
      final received = DateTime(2026, 11, 18, 14);
      expect(
        questionnaireNotificationTime('18:00', received),
        DateTime(2026, 11, 18, 18),
      );
    });

    test('supports UTC and fractional seconds', () {
      expect(
        questionnaireNotificationTime('18:05:22.123456Z', afternoon),
        DateTime.utc(2026, 11, 18, 18, 5, 22, 123, 456),
      );
    });

    test('invalid or missing times fall back to normal presentation', () {
      for (final value in [
        null,
        '',
        'later',
        '24:00',
        '18:61',
        '18:00:60Z',
        '18:00+24:00',
        '18:00+01:60',
        '2026-11-18T18:00:00Z',
      ]) {
        expect(questionnaireNotificationTime(value, afternoon), isNull);
      }
    });
  });

  group('Questionnaire inbox and reminders', () {
    late RecordingNotifications notifications;
    late QuestionnaireNotifications service;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({'userID': 'user-1'});
      now = DateTime.utc(2026, 11, 18, 14);
      notifications = RecordingNotifications();
      service = QuestionnaireNotifications(
        notifications: notifications,
        now: () => now,
      );
    });

    test(
      'saves a future questionnaire immediately without opening it',
      () async {
        final show = await service.receive(
          questionnaire(notifyAfter: '18:00Z'),
          'event-1',
        );
        expect(show, isFalse);
        final drafts = await DraftsStore.getDrafts();
        expect(drafts.single.toQuestionnaire().questions, hasLength(1));
        expect(drafts.single.toQuestionnaire().notifyAfter, '18:00Z');
        expect(
          notifications.scheduled.values.single.at,
          DateTime.utc(2026, 11, 18, 18),
        );
      },
    );

    test(
      'past, equal, absent, and invalid times show normally and stay listed',
      () async {
        for (final value in ['13:00Z', '14:00Z', null, 'bad']) {
          expect(
            await service.receive(
              questionnaire(notifyAfter: value),
              'event-$value',
            ),
            isTrue,
          );
        }
        expect(await DraftsStore.getDrafts(), hasLength(4));
        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'a response without questions is neither saved nor scheduled',
      () async {
        final q = questionnaire(notifyAfter: '18:00Z')..questions = [];
        expect(await service.receive(q, 'event-1'), isFalse);
        expect(await DraftsStore.getDrafts(), isEmpty);
        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'completing early cancels the reminder and removes its inbox item',
      () async {
        await service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-1');
        final id = notifications.scheduled.keys.single;
        await service.remove('event-1');
        now = DateTime.utc(2026, 11, 18, 19);
        await service.restorePending();
        expect(notifications.cancelled, [id]);
        expect(notifications.scheduled, isEmpty);
        expect(await DraftsStore.getDrafts(), isEmpty);
      },
    );

    test(
      'different interactions with the same questionnaire have separate reminders',
      () async {
        await Future.wait([
          service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-1'),
          service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-2'),
        ]);
        expect(notifications.scheduled, hasLength(2));
        await service.remove('event-1');
        expect(
          notifications.scheduled.values.single.payload,
          'questionnaire:event-2',
        );
        expect((await DraftsStore.getDrafts()).single.interactionID, 'event-2');
      },
    );

    test(
      'restart restores the original schedule with the same native ID',
      () async {
        await service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-1');
        final original = Map.of(notifications.scheduled);
        notifications.scheduled.clear();
        final restarted = QuestionnaireNotifications(
          notifications: notifications,
          now: () => now,
        );
        await restarted.restorePending();
        expect(notifications.scheduled, original);
        await restarted.receive(
          questionnaire(notifyAfter: '18:00Z'),
          'event-1',
        );
        expect(notifications.scheduled, original);
        expect(await DraftsStore.getDrafts(), hasLength(1));
      },
    );

    test(
      'unfinished items do not expire or acquire a reminder for tomorrow',
      () async {
        await service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-1');
        notifications.scheduled.clear();
        now = DateTime.utc(2026, 12, 18, 14);
        await service.restorePending();
        expect(notifications.scheduled, isEmpty);
        expect(
          (await DraftsStore.getDrafts()).single.savedAt,
          DateTime.utc(2026, 11, 18, 14),
        );
        expect(
          await service.receive(
            questionnaire(notifyAfter: '18:00Z'),
            'event-1',
          ),
          isTrue,
        );
        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'notification failure or disabled settings never hides the inbox item',
      () async {
        notifications.failScheduling = true;
        expect(
          await service.receive(
            questionnaire(notifyAfter: '18:00Z'),
            'event-1',
          ),
          isFalse,
        );
        notifications.failScheduling = false;
        notifications.setPushEnabled(false);
        expect(
          await service.receive(
            questionnaire(notifyAfter: '18:00Z'),
            'event-2',
          ),
          isFalse,
        );
        expect(await DraftsStore.getDrafts(), hasLength(2));
        expect(notifications.scheduled, isEmpty);
      },
    );

    test(
      'cancels pending reminders on logout without deleting unfinished items',
      () async {
        await service.receive(questionnaire(notifyAfter: '18:00Z'), 'event-1');
        await service.cancelPending();
        expect(notifications.scheduled, isEmpty);
        expect(await DraftsStore.getDrafts(), hasLength(1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userID', 'user-2');
        expect(await DraftsStore.getDrafts(), isEmpty);
        await service.restorePending();
        expect(notifications.scheduled, isEmpty);
        await prefs.setString('userID', 'user-1');
        expect(await DraftsStore.getDrafts(), hasLength(1));
      },
    );

    test('manual save for later does not move the original reminder', () async {
      final q = questionnaire(notifyAfter: '18:00Z');
      await service.receive(q, 'event-1');
      final original = (await DraftsStore.getDrafts()).single;
      await DraftsStore.saveDraft(
        DraftQuestionnaire(
          interactionID: 'event-1',
          savedAt: now.add(const Duration(hours: 1)),
          questionnaireJson: q.toJson(),
        ),
      );
      final draft = (await DraftsStore.getDrafts()).single;
      expect(draft.notifyAt, original.notifyAt);
      expect(draft.notificationID, original.notificationID);
      expect(draft.savedAt, original.savedAt);
    });

    test(
      'migrates existing drafts and tolerates a malformed stored entry',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('questionnaire_drafts', [
          'bad json',
          jsonEncode(
            DraftQuestionnaire(
              interactionID: 'old-event',
              savedAt: now,
              questionnaireJson: questionnaire().toJson(),
            ).toJson(),
          ),
        ]);
        expect(
          (await DraftsStore.getDrafts()).single.interactionID,
          'old-event',
        );
        expect(prefs.containsKey('questionnaire_drafts'), isFalse);
      },
    );
  });
}
