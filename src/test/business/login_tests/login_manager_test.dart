import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/exceptions/validation_exception.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/models/api_models/user.dart';
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

      verify(
        mockAuthApi.authenticate('Wild Gids', 'test@example.com'),
      ).called(1);
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

      verify(
        mockAuthApi.authenticate('Wild Gids', 'test@example.com'),
      ).called(1);
    });
  });

  group('Verify code', () {
    test('should call authorize and return user on success', () async {
      final mockUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );
      TestHelpers.setupSuccessfulAuthorization(
        mockAuthApi,
        mockProfileApi,
        user: mockUser,
      );

      final result = await loginManager.verifyCode(
        'test@example.com',
        '123456',
      );

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

      verify(
        mockAuthApi.authenticate('Wild Gids', 'test@example.com'),
      ).called(1);
      expect(result, true);
    });

    test('should throw Exception when authentication fails', () async {
      TestHelpers.setupFailedAuthentication(mockAuthApi);

      expect(
        () => loginManager.resendCode('test@example.com'),
        throwsA(isA<Exception>()),
      );

      verify(
        mockAuthApi.authenticate('Wild Gids', 'test@example.com'),
      ).called(1);
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

  group('Reviewer login', () {
    const reviewerEmail = 'appreviewer-1@example.com';
    const reviewerPin = '654321';
    const reviewerToken = 'reviewer-test-token';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dotenv.loadFromString(envString: '''
REVIEWER_EMAIL=$reviewerEmail
REVIEWER_TOKEN=$reviewerToken
REVIEWER_PIN=$reviewerPin
''');
    });

    test('should skip authenticate for the reviewer email', () async {
      final result = await loginManager.sendLoginCode(reviewerEmail);

      expect(result, true);
      verifyNever(mockAuthApi.authenticate(any, any));
    });

    test('should still authenticate a normal email', () async {
      TestHelpers.setupSuccessfulAuthentication(mockAuthApi);

      final result = await loginManager.sendLoginCode('test@example.com');

      expect(result, true);
      verify(
        mockAuthApi.authenticate('Wild Gids', 'test@example.com'),
      ).called(1);
    });

    test('should store the reviewer token and skip authorize', () async {
      when(
        mockProfileApi.setProfileDataInDeviceStorage(),
      ).thenAnswer((_) => Future.value());

      final result = await loginManager.verifyCode(reviewerEmail, reviewerPin);

      verifyNever(mockAuthApi.authorize(any, any));
      verify(mockProfileApi.setProfileDataInDeviceStorage()).called(1);
      expect(result.email, reviewerEmail);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('bearer_token'), reviewerToken);
    });

    test('should reject an invalid reviewer pin', () async {
      expect(
        () => loginManager.verifyCode(reviewerEmail, '000000'),
        throwsA(isA<Exception>()),
      );
      verifyNever(mockAuthApi.authorize(any, any));
      verifyNever(mockProfileApi.setProfileDataInDeviceStorage());
    });
  });
}

