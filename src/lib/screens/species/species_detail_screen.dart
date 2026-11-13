import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';

class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({
    super.key,
    required this.species,
    this.onTabSelected,
  });

  final Species species;
  final ValueChanged<NavTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final title =
        species.commonName.isNotEmpty
            ? species.commonName
            : species.latinName ?? 'Dier';
    final image = SpeciesImageResolver.drawingForCommonName(species.commonName);
    return Scaffold(
      backgroundColor: GuideStyle.background,
      appBar: AppBar(
        backgroundColor: GuideStyle.background,
        foregroundColor: GuideStyle.ink,
        title: const Text('Dierengids'),
        centerTitle: false,
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SpeciesHeader(
                      species: species,
                      title: title,
                      imagePath: image,
                    ),
                    const SizedBox(height: 16),
                    _GuideSection(
                      title: 'Gedrag',
                      body: species.behaviour,
                      icon: Icons.pets_outlined,
                      initiallyExpanded: true,
                    ),
                    _GuideSection(
                      title: 'Over dit dier',
                      body: species.description,
                      icon: Icons.info_outline_rounded,
                    ),
                    _GuideSection(
                      title: 'Rol in de natuur',
                      body: species.roleInNature,
                      icon: Icons.forest_outlined,
                    ),
                    _GuideSection(
                      title: 'Veilig ontmoeten',
                      body: species.advice,
                      icon: Icons.shield_outlined,
                      initiallyExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          onTabSelected == null
              ? null
              : SafeArea(
                top: false,
                child: CustomNavBar(
                  currentTab: NavTab.ontdekken,
                  onTabSelected: (tab) {
                    // Return through the library before changing the app destination.
                    Navigator.of(context).pop();
                    onTabSelected!(tab);
                  },
                ),
              ),
    );
  }
}

class _SpeciesHeader extends StatelessWidget {
  const _SpeciesHeader({
    required this.species,
    required this.title,
    required this.imagePath,
  });
  final Species species;
  final String title;
  final String? imagePath;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sideBySide =
          constraints.maxWidth >= 330 &&
          AnimalName.widthFor(
                context,
                title,
                const TextStyle(
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ) <=
              (constraints.maxWidth - 8) * 0.4 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.2;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimalName(
            title,
            style: TextStyle(
              color: GuideStyle.ink,
              fontSize: sideBySide ? 34 : 40,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (species.latinName?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            AnimalName(
              species.latinName!,
              style: const TextStyle(
                color: GuideStyle.muted,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (species.category.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GuideStyle.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                species.category,
                style: const TextStyle(color: GuideStyle.ink, fontSize: 13),
              ),
            ),
          ],
        ],
      );
      final artwork = SizedBox(
        height: sideBySide ? 260 : 245,
        child: AnimalArtwork(
          imagePath: imagePath,
          label: title,
          zoom: title.toLowerCase() == 'egel' ? 1.32 : 1.10,
        ),
      );
      if (sideBySide) {
        return Row(
          children: [
            Expanded(flex: 4, child: identity),
            const SizedBox(width: 8),
            Expanded(flex: 6, child: artwork),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [identity, const SizedBox(height: 8), artwork],
      );
    },
  );
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.body,
    required this.icon,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? body;
  final IconData icon;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GuideStyle.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: GuideStyle.ink,
          collapsedIconColor: GuideStyle.ink,
          leading: Icon(icon, color: GuideStyle.ink, size: 29),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: GuideStyle.ink,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                body?.trim().isNotEmpty == true
                    ? body!.trim()
                    : 'Er is nog geen informatie beschikbaar.',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: GuideStyle.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
