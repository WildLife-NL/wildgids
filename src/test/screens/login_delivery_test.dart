import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/auth_api.dart';
import 'package:wildgids/exceptions/login_code_delivery_uncertain_exception.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/managers/other/login_manager.dart';
import 'package:wildgids/screens/login/login_screen.dart';
import 'package:wildgids/widgets/overlay/error_overlay.dart';

import '../business/mock_generator.mocks.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('504 is preserved through the real API and login manager', () async {
    final profile = MockProfileApiInterface();
    final manager = LoginManager(
      AuthApi(ApiClient('https://example.com/')),
      profile,
    );
    await http.runWithClient(
      () async {
        await expectLater(
          manager.sendLoginCode('test@example.com'),
          throwsA(isA<LoginCodeDeliveryUncertainException>()),
        );
        await expectLater(
          manager.resendCode('test@example.com'),
          throwsA(isA<LoginCodeDeliveryUncertainException>()),
        );
      },
      () => MockClient(
        (_) async => http.Response('<html>Gateway Timeout</html>', 504),
      ),
    );
    verifyNever(profile.setProfileDataInDeviceStorage());
    expect(
      (await SharedPreferences.getInstance()).getString('bearer_token'),
      isNull,
    );
  });

  test('normal success and definite rejection remain distinct', () async {
    final api = AuthApi(ApiClient('https://example.com/'));
    await http.runWithClient(() async {
      expect(await api.authenticate('Wild Gids', 'test@example.com'), isEmpty);
    }, () => MockClient((_) async => http.Response('{}', 200)));
    await http.runWithClient(
      () async {
        await expectLater(
          api.authenticate('Wild Gids', 'test@example.com'),
          throwsA(isNot(isA<LoginCodeDeliveryUncertainException>())),
        );
      },
      () =>
          MockClient((_) async => http.Response('{"detail":"Rejected"}', 400)),
    );
  });

  Future<void> openLogin(WidgetTester tester, LoginInterface manager) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Provider<LoginInterface>.value(
        value: manager,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'test@example.com');
    await tester.ensureVisible(find.text('Code versturen'));
    await tester.tap(find.text('Code versturen'));
    await tester.pump();
  }

  testWidgets(
    'late code can be submitted after 504 and is still checked by the backend',
    (tester) async {
      final manager = MockLoginInterface();
      when(manager.validateEmail(any)).thenReturn(null);
      when(manager.sendLoginCode(any)).thenAnswer((_) async {
        throw const LoginCodeDeliveryUncertainException();
      });
      when(
        manager.verifyCode(any, any),
      ).thenAnswer((_) async => throw Exception('Invalid code'));
      await openLogin(tester, manager);
      await tester.pumpAndSettle();
      expect(find.text('Controleer uw e-mail'), findsOneWidget);
      expect(
        find.text(
          'De e-mail kan vertraagd zijn. Controleer uw inbox en spammap.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ErrorOverlay), findsNothing);
      expect(find.textContaining('Verzonden naar'), findsNothing);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.ensureVisible(find.text('Verifieer'));
      await tester.tap(find.text('Verifieer'));
      await tester.pumpAndSettle();
      verify(manager.verifyCode('test@example.com', '123456')).called(1);
      expect(find.text('Ongeldige verificatiecode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('client timeout also keeps code entry available', (tester) async {
    final pending = Completer<http.Response>();
    final manager = LoginManager(
      AuthApi(ApiClient('https://example.com/')),
      MockProfileApiInterface(),
    );
    await http.runWithClient(
      () => openLogin(tester, manager),
      () => MockClient((_) => pending.future),
    );
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('Verifieer'), findsOneWidget);
    expect(
      find.textContaining('De e-mail kan vertraagd zijn.'),
      findsOneWidget,
    );
    pending.complete(http.Response('{}', 200));
    await tester.pump();
  });

  testWidgets(
    'changing email ignores a late failure from the previous request',
    (tester) async {
      final manager = MockLoginInterface();
      final pending = Completer<bool>();
      when(manager.validateEmail(any)).thenReturn(null);
      when(manager.sendLoginCode(any)).thenAnswer((_) => pending.future);
      await openLogin(tester, manager);
      await tester.ensureVisible(find.text('E-mailadres wijzigen'));
      await tester.tap(find.text('E-mailadres wijzigen'));
      pending.completeError(const LoginCodeDeliveryUncertainException());
      await tester.pumpAndSettle();
      expect(find.text('Welkom terug'), findsOneWidget);
      expect(
        find.textContaining('De e-mail kan vertraagd zijn.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
