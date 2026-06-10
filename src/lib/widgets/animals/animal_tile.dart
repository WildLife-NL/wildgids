import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/utils/species_image_resolver.dart';

class AnimalTile extends StatefulWidget {
  final AnimalModel animal;
  final VoidCallback onTap;
  final bool isSelected;
  final int? selectionNumber;

  const AnimalTile({
    super.key,
    required this.animal,
    required this.onTap,
    this.isSelected = false,
    this.selectionNumber,
  });

  @override
  State<AnimalTile> createState() => _AnimalTileState();
}

class _AnimalTileState extends State<AnimalTile> {
  String? get _resolvedImagePath =>
      SpeciesImageResolver.drawingForCommonName(widget.animal.animalName) ??
      widget.animal.animalImagePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: widget.isSelected
                      ? const Color(0xFF4CAF50)
                      : const Color.fromARGB(64, 0, 0, 0),
                  width: widget.isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        color: Color(0xFFE6DCCD),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: SizedBox.expand(
                          child: _resolvedImagePath != null
                              ? _buildImageWithFallback()
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Geen afbeelding',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: widget.isSelected
                        ? const Color(0xFF4CAF50)
                        : const Color.fromARGB(84, 0, 0, 0),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.isSelected ? const Color(0xFFF0F4ED) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: Text(
                      widget.animal.animalName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: widget.isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            if (widget.isSelected && widget.selectionNumber != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.selectionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithFallback() {
    final imagePath = _resolvedImagePath;
    if (imagePath == null) {
      return const SizedBox.shrink();
    }

    return Image(
      image: AssetImage(imagePath),
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '[AnimalTile] Error loading image: $imagePath',
        );

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 50,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}