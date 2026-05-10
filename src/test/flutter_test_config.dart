import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _transparentImageBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, 0xE7, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const String _minimalLottieJson =
    '{"v":"5.7.0","fr":30,"ip":0,"op":1,"w":1,"h":1,"nm":"test","ddd":0,"assets":[],"layers":[]}';

Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final StandardMessageCodec codec = const StandardMessageCodec();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        if (message == null) {
          return null;
        }

        final String assetKey = utf8.decode(message.buffer.asUint8List());
        if (assetKey.endsWith('AssetManifest.bin')) {
          return codec.encodeMessage(<String, Object>{});
        }

        if (assetKey.endsWith('AssetManifest.json')) {
          final Uint8List bytes = Uint8List.fromList(utf8.encode('{}'));
          return ByteData.sublistView(bytes);
        }

        if (assetKey.endsWith('FontManifest.json')) {
          final Uint8List bytes = Uint8List.fromList(utf8.encode('[]'));
          return ByteData.sublistView(bytes);
        }

        if (assetKey.endsWith('.json')) {
          final Uint8List bytes = Uint8List.fromList(
            utf8.encode(_minimalLottieJson),
          );
          return ByteData.sublistView(bytes);
        }

        if (assetKey.endsWith('.png') ||
            assetKey.endsWith('.jpg') ||
            assetKey.endsWith('.jpeg') ||
            assetKey.endsWith('.webp')) {
          return ByteData.sublistView(_transparentImageBytes);
        }

        return null;
      });

  await testMain();
}
