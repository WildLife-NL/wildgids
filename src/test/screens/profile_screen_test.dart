import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/screens/profile/edit_profile_screen.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';

class _ProfileApi implements ProfileApiInterface {
  Profile profile = Profile(
    userID: 'test-user',
    userName: 'Een lange profielnaam voor kleine schermen',
    email: 'een.lang.emailadres.voor.testen@example.com',
  );
  Completer<Profile>? pending;
  bool fail = false;
  int deletions = 0;
  int fetches = 0;
  @override
  Future<Profile> fetchMyProfile() async {
    fetches++;
    if (fail) throw Exception('Offline');
    return pending?.future ?? profile;
  }

  @override
  Future<void> deleteMyProfile() async {
    deletions++;
  }

  @override
  Future<Profile> updateMyProfile(Profile updatedProfile) async =>
      updatedProfile;
  @override
  Future<Profile> updateReportAppTerms(bool accepted) async => profile;
  @override
  Future<void> setProfileDataInDeviceStorage() async {}
}

class _AppState extends AppStateProvider {
  bool notifications = true;
  int logouts = 0;
  int deletions = 0;
  @override
  bool get notificationsEnabled => notifications;
  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    notifications = enabled;
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    logouts++;
  }

  @override
  Future<void> deleteProfile() async {
    deletions++;
  }
}

class _MapState extends MapProvider {
  bool? vicinityEnabled;
  @override
  void setVicinityNotificationsEnabled(bool enabled) {
    vicinityEnabled = enabled;
  }
}

class _Tracing extends ChangeNotifier implements ContactTracingCoordinator {
  bool enabled = false;
  bool scanning = false;
  int scans = 0;
  @override
  bool get backgroundEnabled => enabled;
  @override
  bool get backgroundScanning => scanning;
  @override
  int get backgroundIntervalSeconds => 30;
  @override
  String get statusMessage => 'Uit';
  @override
  Future<bool> setBackgroundEnabled(bool value) async {
    enabled = value;
    notifyListeners();
    return !value;
  }

  @override
  Future<void> triggerBackgroundScanNow({bool force = false}) async {
    scans++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (_) async => true,
        );
  });
  late _ProfileApi api;
  late _AppState app;
  late _MapState map;
  late _Tracing tracing;

  setUp(() {
    api = _ProfileApi();
    app = _AppState();
    map = _MapState();
    tracing = _Tracing();
    SharedPreferences.setMockInitialValues({'userName': 'Opgeslagen naam'});
    PackageInfo.setMockInitialValues(
      appName: 'WildGids',
      packageName: 'test',
      version: '1.0',
      buildNumber: '20261025',
      buildSignature: '',
    );
  });
  tearDown(() {
    app.dispose();
    map.dispose();
    tracing.dispose();
  });

  Future<void> showProfile(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ProfileApiInterface>.value(value: api),
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
          ChangeNotifierProvider<MapProvider>.value(value: map),
          ChangeNotifierProvider<ContactTracingCoordinator>.value(
            value: tracing,
          ),
        ],
        child: MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapControl(WidgetTester tester, String key) async {
    final control = find.byKey(ValueKey(key));
    if (control.evaluate().isEmpty) {
      if (key == 'profile-logout' || key == 'profile-delete') {
        await tapControl(tester, 'profile-account-section');
      } else if (key == 'profile-notifications' || key == 'profile-bluetooth') {
        await tapControl(tester, 'profile-preferences-section');
      }
    }
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('profile and confirmations fit $size at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await showProfile(tester, scale: scale);
        expect(find.text('Mijn profiel'), findsOneWidget);
        expect(find.text(api.profile.userName), findsOneWidget);
        expect(find.text(api.profile.email), findsOneWidget);
        expect(find.text('Altijd ingeschakeld'), findsNothing);
        expect(find.byKey(const ValueKey('profile-logout')), findsNothing);
        await tapControl(tester, 'profile-preferences-section');
        expect(find.text('Altijd ingeschakeld'), findsOneWidget);
        expect(find.byType(Card), findsNothing);
        expect(tester.takeException(), isNull);
        for (final key in ['profile-logout', 'profile-delete']) {
          await tapControl(tester, key);
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Annuleren'));
          await tester.tap(find.text('Annuleren'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
        }
        expect(api.deletions, 0);
        expect(app.deletions, 0);
        expect(app.logouts, 0);
        await tester.ensureVisible(find.text('Appversie: V2026-10-25'));
        await tester.pumpAndSettle();
        expect(
          find.text('Appversie: V2026-10-25').hitTestable(),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('loading disables editing and failed fetch keeps cached name', (
    tester,
  ) async {
    api.pending = Completer<Profile>();
    await showProfile(tester);
    expect(find.text('Opgeslagen naam'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('profile-edit')))
          .onPressed,
      isNull,
    );
    api.pending!.completeError(Exception('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Opgeslagen naam'), findsOneWidget);
    expect(find.text('Profiel laden...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sections expand individually and keep settings when collapsed', (
    tester,
  ) async {
    await showProfile(tester);
    expect(find.byType(Switch), findsNothing);
    await tapControl(tester, 'profile-preferences-section');
    expect(find.byType(Switch), findsNWidgets(2));
    await tapControl(tester, 'profile-notifications');
    expect(app.notifications, isFalse);
    await tapControl(tester, 'profile-account-section');
    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(const ValueKey('profile-logout')), findsOneWidget);
    await tapControl(tester, 'profile-preferences-section');
    expect(find.byKey(const ValueKey('profile-logout')), findsNothing);
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('profile-notifications')))
          .value,
      isFalse,
    );
    await tapControl(tester, 'profile-preferences-section');
    expect(find.byType(Switch), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification and Bluetooth controls keep existing callbacks', (
    tester,
  ) async {
    await showProfile(tester);
    await tapControl(tester, 'profile-notifications');
    expect(app.notifications, isFalse);
    expect(map.vicinityEnabled, isFalse);
    await tapControl(tester, 'profile-notifications');
    expect(app.notifications, isTrue);
    expect(map.vicinityEnabled, isTrue);
    expect(
      find.byKey(const ValueKey('profile-bluetooth-settings')),
      findsNothing,
    );
    await tapControl(tester, 'profile-bluetooth');
    expect(tracing.enabled, isTrue);
    expect(tracing.scans, 1);
    expect(
      find.byKey(const ValueKey('profile-bluetooth-settings')),
      findsOneWidget,
    );
    await tapControl(tester, 'profile-bluetooth');
    expect(tracing.enabled, isFalse);
    expect(
      find.byKey(const ValueKey('profile-bluetooth-settings')),
      findsNothing,
    );
  });

  testWidgets('scanning disables Bluetooth switch and shows progress', (
    tester,
  ) async {
    tracing.enabled = true;
    // Avoid pumpAndSettle while the progress indicator is active.
    await showProfile(tester);
    await tapControl(tester, 'profile-preferences-section');
    tracing.scanning = true;
    tracing.notifyListeners();
    await tester.pump();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('profile-bluetooth')))
          .onChanged,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    tracing.scanning = false;
    tracing.notifyListeners();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'edit still opens existing form and updates displayed returned profile',
    (tester) async {
      await showProfile(tester);
      await tapControl(tester, 'profile-edit');
      expect(find.byType(EditProfileScreen), findsOneWidget);
      final form = tester.widget<EditProfileScreen>(
        find.byType(EditProfileScreen),
      );
      expect(form.initialProfile, same(api.profile));
      Navigator.of(tester.element(find.byType(EditProfileScreen))).pop(
        Profile(
          userID: 'test-user',
          userName: 'Bijgewerkte naam',
          email: 'nieuw@example.com',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bijgewerkte naam'), findsOneWidget);
      expect(find.text('nieuw@example.com'), findsOneWidget);
    },
  );

  testWidgets('logout and deletion require confirmation before mock calls', (
    tester,
  ) async {
    await showProfile(tester);
    await tapControl(tester, 'profile-logout');
    expect(app.logouts, 0);
    await tester.tap(find.text('Ja, Uitloggen'));
    await tester.pumpAndSettle();
    expect(app.logouts, 1);
    await tapControl(tester, 'profile-delete');
    expect(api.deletions, 0);
    await tester.tap(find.text('Ja, Verwijderen'));
    await tester.pumpAndSettle();
    expect(api.deletions, 1);
    expect(app.deletions, 1);
  });
}
