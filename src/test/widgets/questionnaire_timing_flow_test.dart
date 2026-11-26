import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/data_apis/questionnaire_api_interface.dart';
import 'package:wildgids/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildgids/interfaces/reporting/response_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/managers/other/questionnaire_manager.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/beta_models/response_model.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/saved_questionnaires_screen.dart';
import 'package:wildgids/screens/questionnaire/questionnaire_completion_screen.dart';
import 'package:wildgids/screens/questionnaire/questionnaire_screen.dart';
import 'package:wildgids/services/questionnaire_drafts_store.dart';
import 'package:wildgids/services/questionnaire_notifications.dart';
import 'package:wildgids/utils/sighting_submit_navigation.dart';

import '../services/questionnaire_notifications_test.dart' show questionnaire;

class RecordingNavigation extends Fake implements NavigationStateInterface {
  Widget? destination;

  @override
  void pushAndRemoveUntil(BuildContext context, Widget screen) {
    destination = screen;
  }
}

class UnusedQuestionnaireApi extends Fake
    implements QuestionnaireApiInterface {}

class RecordingResponses extends Fake implements ResponseInterface {
  final stored = <Response>[];
  bool submitted = false;

  @override
  Future<void> storeResponse(
    Response response,
    String questionnaireID,
    String questionID,
  ) async {
    stored.add(response);
  }

  @override
  Future<void> submitResponses() async {
    submitted = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  late RecordingNavigation navigation;
  late RecordingResponses responses;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({'userID': 'user-1'});
    navigation = RecordingNavigation();
    responses = RecordingResponses();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails') {
            return {'notificationLaunchedApp': false};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget app(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppStateProvider()),
      Provider<NavigationStateInterface>.value(value: navigation),
      Provider<QuestionnaireInterface>.value(
        value: QuestionnaireManager(UnusedQuestionnaireApi()),
      ),
      Provider<ResponseInterface>.value(value: responses),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets(
    'future questionnaires skip the automatic screen and can be opened early',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final q = questionnaire(notifyAfter: '23:59:59.999999Z');
      late BuildContext reportContext;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              reportContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await navigateAfterSightingSubmit(
        reportContext,
        InteractionResponse(questionnaire: q, interactionID: 'event-1'),
        showSuccessToast: false,
      );
      expect(navigation.destination, isA<KaartOverviewScreen>());
      expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));

      await tester.pumpWidget(app(const SavedQuestionnairesScreen()));
      await tester.pumpAndSettle();
      expect(find.text(q.name), findsOneWidget);
      await tester.tap(find.text('Hervat'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionnaireScreen), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      // Merely opening the questionnaire must not cancel the pending reminder.
      expect(calls.where((c) => c.method == 'cancel'), isEmpty);
    },
  );

  testWidgets(
    'normal questionnaires still open immediately and stay in the list',
    (tester) async {
      late BuildContext reportContext;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              reportContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await navigateAfterSightingSubmit(
        reportContext,
        InteractionResponse(
          questionnaire: questionnaire(),
          interactionID: 'event-1',
        ),
        showSuccessToast: false,
      );
      expect(navigation.destination, isA<QuestionnaireScreen>());
      expect(await DraftsStore.getDrafts(), hasLength(1));
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
    },
  );

  testWidgets(
    'finishing early submits answers, cancels the reminder, and removes the item',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final q = questionnaire(notifyAfter: '23:59:59.999999Z');
      await QuestionnaireNotifications.instance.receive(q, 'event-1');
      final id = (await DraftsStore.getDrafts()).single.notificationID;
      await tester.pumpWidget(
        app(QuestionnaireScreen(questionnaire: q, interactionID: 'event-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ik heb een ree gezien.');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volgende'));
      await tester.pumpAndSettle();
      expect(responses.submitted, isTrue);
      expect(responses.stored.single.text, 'Ik heb een ree gezien.');
      expect(navigation.destination, isA<QuestionnaireCompletionScreen>());
      expect(
        (calls.singleWhere((c) => c.method == 'cancel').arguments as Map)['id'],
        id,
      );
      expect(await DraftsStore.getDrafts(), isEmpty);
    },
  );
}
