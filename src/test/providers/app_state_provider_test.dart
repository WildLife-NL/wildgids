import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import '../business/mock_generator.mocks.dart';

// Mock class for SightingReport to handle updateProperty
class MockSightingReport {
  String? description;
  DateTime systemDateTime;

  MockSightingReport({required this.systemDateTime});

  void updateProperty(String property, dynamic value) {
    if (property == 'description') {
      description = value;
    }
  }
}

void main() {
  late AppStateProvider appStateProvider;
  late BuildContext mockContext;

  setUp(() {
    appStateProvider = AppStateProvider();
    mockContext = MockBuildContext();
  });

  group('AppStateProvider', () {
    test('should initialize with default values', () {
      expect(appStateProvider.navigatorKey, isNotNull);
      expect(appStateProvider.currentReportType, isNull);
      expect(appStateProvider.cachedPosition, isNull);
      expect(appStateProvider.cachedAddress, isNull);
      expect(appStateProvider.lastLocationUpdate, isNull);
      expect(appStateProvider.isLocationCacheValid, isFalse);
      expect(appStateProvider.isLocationTrackingEnabled, isTrue);
    });

    test('should set and get screen state', () {
      // Arrange
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');
      final value = appStateProvider.getScreenState<String>(
        'testScreen',
        'testKey',
      );

      // Assert
      expect(value, 'testValue');
      expect(listenerCalled, isTrue);
    });

    test('should not set screen state when value is null', () {
      // Act
      appStateProvider.setScreenState('testScreen', 'testKey', null);
      final value = appStateProvider.getScreenState<String>(
        'testScreen',
        'testKey',
      );

      // Assert
      expect(value, isNull);
    });

    test('should not update screen state when value is the same', () {
      // Arrange
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');

      // Assert
      expect(listenerCalled, isFalse);
    });

    test('should warn on type mismatch for existing key', () {
      // Arrange
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.setScreenState('testScreen', 'testKey', 123);
      final value = appStateProvider.getScreenState<String>(
        'testScreen',
        'testKey',
      );

      // Assert
      expect(value, 'testValue'); // Value should not change
      expect(listenerCalled, isFalse);
    });

    test('should clear screen state', () {
      // Arrange
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.clearScreenState('testScreen');
      final value = appStateProvider.getScreenState<String>(
        'testScreen',
        'testKey',
      );

      // Assert
      expect(value, isNull);
      expect(listenerCalled, isTrue);
    });

    test('should initialize report based on report type', () {
      // Arrange
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.initializeReport(ReportType.waarneming);
      final report = appStateProvider.getCurrentReport();

      // Assert
      expect(appStateProvider.currentReportType, ReportType.waarneming);
      expect(report, isNotNull);
      expect(listenerCalled, isTrue);
    });

    // Skip the updateCurrentReport test since we can't easily mock the report classes
    test('should reset application state', () {
      // Arrange
      appStateProvider.setScreenState('testScreen', 'testKey', 'testValue');
      appStateProvider.initializeReport(ReportType.waarneming);
      bool listenerCalled = false;
      appStateProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      appStateProvider.resetApplicationState(mockContext);

      // Assert
      expect(
        appStateProvider.getScreenState<String>('testScreen', 'testKey'),
        isNull,
      );
      expect(appStateProvider.currentReportType, isNull);
      expect(appStateProvider.getCurrentReport(), isNull);
      expect(listenerCalled, isTrue);
    });

    // Test isLocationCacheValid without using reflection
    test('should report location cache as invalid when no data exists', () {
      expect(appStateProvider.isLocationCacheValid, isFalse);
    });

    test('loadLocationTrackingPreference always enables location sharing', () async {
      SharedPreferences.setMockInitialValues({
        'location_tracking_enabled': false,
      });

      await appStateProvider.loadLocationTrackingPreference();

      expect(appStateProvider.isLocationTrackingEnabled, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('location_tracking_enabled'), isTrue);
    });

    test('setLocationTrackingEnabled ignores disable requests', () async {
      SharedPreferences.setMockInitialValues({});

      await appStateProvider.setLocationTrackingEnabled(false);

      expect(appStateProvider.isLocationTrackingEnabled, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('location_tracking_enabled'), isTrue);
    });
  });
}

