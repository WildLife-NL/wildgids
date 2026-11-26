import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/services/collar_identity_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'UUID-to-MAC pairing survives reload with a canonical address',
    () async {
      await CollarIdentityStore.save(
        'e006b3a7-ef7b-4980-a668-1f8005f84383',
        'aa-bb-cc-dd-ee-ff',
      );
      expect(await CollarIdentityStore.load(), {
        'E006B3A7-EF7B-4980-A668-1F8005F84383': 'AA:BB:CC:DD:EE:FF',
      });
    },
  );

  test(
    'UUIDs and partial Smart Parks names cannot become hardware addresses',
    () async {
      for (final value in [
        'SP123456',
        '12:34:56',
        'e006b3a7-ef7b-4980-a668-1f8005f84383',
      ]) {
        expect(CollarIdentityStore.validate(value), isNotNull);
        await expectLater(
          CollarIdentityStore.save('uuid', value),
          throwsArgumentError,
        );
      }
      expect(await CollarIdentityStore.load(), isEmpty);
    },
  );

  test('default Smart Parks name must match the entered address suffix', () {
    expect(
      CollarIdentityStore.validate(
        'AA:BB:CC:12:34:56',
        advertisedName: 'SP123456',
      ),
      isNull,
    );
    expect(
      CollarIdentityStore.validate(
        'AA:BB:CC:65:43:21',
        advertisedName: 'SP123456',
      ),
      contains('hoort niet bij'),
    );
  });

  test('unreadable stored data does not prevent scanning', () async {
    SharedPreferences.setMockInitialValues({
      'collar_device_hardware_addresses': 'broken',
    });
    expect(await CollarIdentityStore.load(), isEmpty);
  });
}
