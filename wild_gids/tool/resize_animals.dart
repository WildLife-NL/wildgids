import 'dart:io';
import 'package:image/image.dart' as img;

/// Resize large PNGs in assets/animals to reduce APK size.
/// - Max dimension: 1024 px
/// - Overwrites the original files (keeps code references unchanged)
Future<void> main() async {
  final dir = Directory('assets/animals');
  if (!await dir.exists()) {
    stderr.writeln('Directory not found: assets/animals');
    exit(1);
  }

  final files = await dir
      .list(recursive: false)
      .where((e) => e is File && e.path.toLowerCase().endsWith('.png'))
      .cast<File>()
      .toList();

  if (files.isEmpty) {
    stdout.writeln('No PNG files found in assets/animals');
    return;
  }

  const maxDim = 1024;
  int processed = 0;
  int skipped = 0;

  for (final file in files) {
    try {
      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;
      final image = img.decodePng(originalBytes);
      if (image == null) {
        stderr.writeln('Failed to decode PNG: ${file.path}');
        skipped++;
        continue;
      }

      final w = image.width;
      final h = image.height;
      final needsResize = w > maxDim || h > maxDim;

      img.Image out = image;
      if (needsResize) {
        final scale = w > h ? maxDim / w : maxDim / h;
        final newW = (w * scale).round();
        final newH = (h * scale).round();
        out = img.copyResize(image, width: newW, height: newH, interpolation: img.Interpolation.cubic);
      }

      // Re-encode PNG with max compression. Note: This doesn't do color quantization.
      final encoded = img.encodePng(out, level: 9);
      await file.writeAsBytes(encoded, flush: true);

      final newSize = encoded.length;
      processed++;
      stdout.writeln('[OK] ${file.path}: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)}MB -> ${(newSize / (1024 * 1024)).toStringAsFixed(2)}MB (${newSize < originalSize ? '-' : '+'}${(100 * (1 - newSize / originalSize)).toStringAsFixed(1)}%)');
    } catch (e) {
      stderr.writeln('Error processing ${file.path}: $e');
      skipped++;
    }
  }

  stdout.writeln('Done. Processed: $processed, Skipped: $skipped');
}
