import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/screens/login/login_screen.dart';
import '../business/mock_generator.mocks.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets('login motion respects reduced motion: $reduceMotion', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final manager = MockLoginInterface();
      when(manager.validateEmail(any)).thenReturn(null);
      when(manager.sendLoginCode(any)).thenAnswer((_) async => true);
      final reduced = ValueNotifier(reduceMotion);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        Provider<LoginInterface>.value(
          value: manager,
          child: MaterialApp(
            builder:
                (context, child) => ValueListenableBuilder<bool>(
                  valueListenable: reduced,
                  builder:
                      (context, value, _) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(disableAnimations: value),
                        child: child!,
                      ),
                ),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final deer = find.byType(Image);
      final deerBefore = tester.getRect(deer);
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.getRect(deer), deerBefore);
      final fades = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(fades.any((fade) => fade.opacity < 1), !reduceMotion);
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getRect(deer), deerBefore);
      // Changing the system preference mid-animation immediately stops motion.
      reduced.value = true;
      await tester.pump();
      expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .every((fade) => fade.opacity == 1),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
      verify(manager.sendLoginCode('test@example.com')).called(1);
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('login steps fit $size at text scale $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        final manager = MockLoginInterface();
        when(manager.validateEmail(any)).thenReturn(null);
        when(manager.sendLoginCode(any)).thenAnswer((_) async => true);
        when(
          manager.verifyCode(any, any),
        ).thenAnswer((_) async => throw Exception('Invalid code'));
        await tester.pumpWidget(
          Provider<LoginInterface>.value(
            value: manager,
            child: MaterialApp(
              builder:
                  (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.only(top: 44, bottom: 34),
                    ),
                    child: child!,
                  ),
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final illustration = find.byKey(const ValueKey('login-illustration'));
        final imageSize = tester.getSize(illustration);
        final title = tester.getRect(find.text('Welkom terug'));
        expect(
          title.bottom,
          lessThanOrEqualTo(tester.getRect(illustration).top),
        );
        expect(tester.takeException(), isNull);
        final button = find.byType(ElevatedButton);
        if (scale == 1 && size.height >= 800) {
          expect(
            tester.getRect(button).bottom,
            lessThanOrEqualTo(size.height - 34),
          );
          // The form uses the lower screen instead of leaving a large empty tail.
          expect(tester.getRect(button).bottom, greaterThan(size.height * 0.7));
        }
        await tester.enterText(
          find.byType(TextField),
          'een.lang.emailadres.voor.testen@example.com',
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('Controleer uw e-mail'), findsOneWidget);
        expect(tester.getSize(illustration), imageSize);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(button);
        expect(button.hitTestable(), findsOneWidget);

        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pumpAndSettle();
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(button).bottom,
          lessThanOrEqualTo(size.height - 280),
        );
        await tester.tap(button);
        await tester.pumpAndSettle();
        verify(
          manager.verifyCode(
            'een.lang.emailadres.voor.testen@example.com',
            '123456',
          ),
        ).called(1);
        expect(find.text('Ongeldige verificatiecode'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('E-mailadres wijzigen'));
        await tester.tap(find.text('E-mailadres wijzigen'));
        await tester.pumpAndSettle();
        expect(find.text('Welkom terug'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'een.lang.emailadres.voor.testen@example.com',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
