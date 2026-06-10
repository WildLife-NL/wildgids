import 'dart:io';

import 'package:wildgids/utils/species_image_resolver.dart';

void main() {
  final names = SpeciesImageResolver.supportedCommonNames();

  var missingCount = 0;
  var unresolvedCount = 0;

  stdout.writeln('Checking ${names.length} species card image mappings...');

  for (final name in names) {
    final path = SpeciesImageResolver.drawingForCommonName(name);
    if (path == null || path.isEmpty) {
      unresolvedCount++;
      stdout.writeln('UNRESOLVED  $name');
      continue;
    }

    final exists = File(path).existsSync();
    if (!exists) {
      missingCount++;
      stdout.writeln('MISSING     $name -> $path');
    } else {
      stdout.writeln('OK          $name -> $path');
    }
  }

  stdout.writeln('');
  stdout.writeln('Summary:');
  stdout.writeln('  species checked: ${names.length}');
  stdout.writeln('  unresolved:      $unresolvedCount');
  stdout.writeln('  missing files:   $missingCount');

  if (unresolvedCount > 0 || missingCount > 0) {
    exitCode = 1;
    stdout.writeln('Result: FAILED');
    return;
  }

  stdout.writeln('Result: PASSED');
}
