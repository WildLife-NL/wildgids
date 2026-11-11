import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';

class ReportLayout extends StatelessWidget {
  const ReportLayout({
    super.key,
    required this.title,
    required this.stage,
    required this.child,
    this.footer,
    this.onBack,
    this.scroll = true,
  });
  final String title;
  final String stage;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final bool scroll;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GuideStyle.background,
    appBar: AppBar(
      backgroundColor: GuideStyle.background,
      foregroundColor: GuideStyle.ink,
      title: const Text('Waarneming'),
      leading: BackButton(onPressed: onBack),
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage,
                      style: const TextStyle(
                        color: GuideStyle.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: GuideStyle.ink,
                        fontSize: 30,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    scroll
                        ? SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: child,
                        )
                        : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: child,
                        ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar:
        footer == null
            ? null
            : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: footer,
                  ),
                ),
              ),
            ),
  );
}

class ReportAction extends StatelessWidget {
  const ReportAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final content =
        busy
            ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
            : Text(label, textAlign: TextAlign.center);
    if (secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GuideStyle.ink,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: const BorderSide(color: GuideStyle.border),
          textStyle: const TextStyle(
            fontFamily: 'Overpass',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: content,
      );
    }
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: GuideStyle.primaryButton,
      child: content,
    );
  }
}

class ReportAnimal extends StatelessWidget {
  const ReportAnimal({super.key, required this.animal, this.height = 180});
  final AnimalModel? animal;
  final double height;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: height,
        width: double.infinity,
        child: AnimalArtwork(
          imagePath:
              SpeciesImageResolver.drawingForCommonName(animal?.animalName) ??
              animal?.animalImagePath,
        ),
      ),
      if (animal != null)
        AnimalName(
          animal!.animalName,
          alignment: Alignment.center,
          style: const TextStyle(
            color: GuideStyle.ink,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

class ReportSurface extends StatelessWidget {
  const ReportSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: GuideStyle.border),
    ),
    child: child,
  );
}

class ReportChoices<T> extends StatelessWidget {
  const ReportChoices({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });
  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) labelFor;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: GuideStyle.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            values
                .map(
                  (value) => ChoiceChip(
                    label: Text(labelFor(value)),
                    selected: value == selected,
                    selectedColor: GuideStyle.surface,
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(
                      color: GuideStyle.ink,
                      fontSize: 15,
                    ),
                    side: const BorderSide(color: GuideStyle.border),
                    onSelected: (_) => onSelected(value),
                  ),
                )
                .toList(),
      ),
    ],
  );
}
