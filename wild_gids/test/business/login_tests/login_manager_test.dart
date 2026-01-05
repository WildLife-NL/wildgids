import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/exceptions/validation_exception.dart';
import 'package:wildrapport/interfaces/other/login_interface.dart';
import 'package:wildrapport/models/api_models/user.dart';
import '../helpers/login_helpers.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockAuthApiInterface mockAuthApi;
  late MockProfileApiInterface mockProfileApi;
  late LoginInterface loginManager;

  setUpAll(() async {
    // Load environment variables before all tests
    await TestHelpers.setupEnvironment();
  });

  setUp(() {
    mockAuthApi = TestHelpers.getMockAuthApi();
    mockProfileApi = TestHelpers.getMockProfileApi();
    loginManager = TestHelpers.getLoginManager(
      authApi: mockAuthApi,
      profileApi: mockProfileApi,
    );
  });

  group('Email validation', () {
    test('should return null for valid email', () {
      expect(loginManager.validateEmail('test@example.com'), isNull);
    });

    test('should return error message for empty email', () {
      expect(loginManager.validateEmail(''), isNotNull);
    });

    test('should return error message for invalid email format', () {
      expect(loginManager.validateEmail('invalid-email'), isNotNull);
    });
  });

  group('Send login code', () {
    test('should call authenticate and return true on success', () async {
      TestHelpers.setupSuccessfulAuthentication(mockAuthApi);
      
      final result = await loginManager.sendLoginCode('test@example.com');
      
  verify(mockAuthApi.authenticate('Wild Rapport', 'test@example.com')).called(1);
      expect(result, true);
    });

    test('should throw ValidationException for invalid email', () async {
      expect(
        () => loginManager.sendLoginCode('invalid-email'),
        throwsA(isA<ValidationException>()),
      );
      
      verifyNever(mockAuthApi.authenticate(any, any));
    });

    test('should throw Exception when authentication fails', () async {
      TestHelpers.setupFailedAuthentication(mockAuthApi);
      
      expect(
        () => loginManager.sendLoginCode('test@example.com'),
        throwsA(isA<Exception>()),
      );
      
  verify(mockAuthApi.authenticate('Wild Rapport', 'test@example.com')).called(1);
    });
  });

  group('Verify code', () {
    test('should call authorize and return user on success', () async {
      final mockUser = User(id: '123', email: 'test@example.com', name: 'Test User');
      TestHelpers.setupSuccessfulAuthorization(
        mockAuthApi, 
        mockProfileApi,
        user: mockUser,
      );
      
      final result = await loginManager.verifyCode('test@example.com', '123456');
      
      verify(mockAuthApi.authorize('test@example.com', '123456')).called(1);
      verify(mockProfileApi.setProfileDataInDeviceStorage()).called(1);
      expect(result, equals(mockUser));
    });

    test('should throw Exception when authorization fails', () async {
      TestHelpers.setupFailedAuthorization(mockAuthApi);
      
      expect(
        () => loginManager.verifyCode('test@example.com', '123456'),
        throwsA(isA<Exception>()),
      );
      
      verify(mockAuthApi.authorize('test@example.com', '123456')).called(1);
      verifyNever(mockProfileApi.setProfileDataInDeviceStorage());
    });
  });

  group('Resend code', () {
    test('should call authenticate and return true on success', () async {
      TestHelpers.setupSuccessfulAuthentication(mockAuthApi);
      
      final result = await loginManager.resendCode('test@example.com');
      
  verify(mockAuthApi.authenticate('Wild Rapport', 'test@example.com')).called(1);
      expect(result, true);
    });

    test('should throw Exception when authentication fails', () async {
      TestHelpers.setupFailedAuthentication(mockAuthApi);
      
      expect(
        () => loginManager.resendCode('test@example.com'),
        throwsA(isA<Exception>()),
      );
      
  verify(mockAuthApi.authenticate('Wild Rapport', 'test@example.com')).called(1);
    });
  });

  group('State management', () {
    test('should notify listeners when verification visibility changes', () {
      bool listenerCalled = false;
      loginManager.addListener(() {
        listenerCalled = true;
      });
      
      loginManager.setVerificationVisible(true);
      
      expect(listenerCalled, true);
    });

    test('should notify listeners when error state changes', () {
      bool listenerCalled = false;
      loginManager.addListener(() {
        listenerCalled = true;
      });
      
      loginManager.setError(true, 'Test error');
      
      expect(listenerCalled, true);
    });
  });
}
