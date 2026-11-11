import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/screens/species/species_detail_screen.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/animal_name.dart';

void main() {
  testWidgets(
    'Every known animal heading stays complete on one line within the screen',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final names =
          SpeciesImageResolver.supportedCommonNames()
              .map((name) => '${name[0].toUpperCase()}${name.substring(1)}')
              .toList();
      for (final width in [320.0, 393.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 844));
        for (final scale in [1.0, 1.4]) {
          for (final name in names) {
            await tester.pumpWidget(
              MaterialApp(
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                home: SpeciesDetailScreen(
                  species: Species(
                    id: name,
                    commonName: name,
                    category: 'Grote grazers',
                  ),
                ),
              ),
            );
            await tester.pump();
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(name).first,
            );
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: name.length),
            );
            expect(boxes.length, 1, reason: '$name / $width / $scale');
            expect(paragraph.didExceedMaxLines, isFalse, reason: name);
            final left =
                paragraph
                    .localToGlobal(Offset(boxes.single.left, boxes.single.top))
                    .dx;
            final right =
                paragraph
                    .localToGlobal(
                      Offset(boxes.single.right, boxes.single.bottom),
                    )
                    .dx;
            expect(left, greaterThanOrEqualTo(19.5), reason: name);
            expect(right, lessThanOrEqualTo(width - 19.5), reason: name);
            expect(
              tester.takeException(),
              isNull,
              reason: '$name / $width / $scale',
            );
          }
        }
      }
    },
  );

  testWidgets('Long card names remain complete when space is limited', (
    tester,
  ) async {
    for (final name in [
      'Galloway',
      'Hooglander',
      'Goudjakhals',
      'Europese nerts',
      'Shetland pony',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                child: AnimalName(name, style: const TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
      expect(
        paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: name.length),
            )
            .length,
        1,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    }
  });
}
