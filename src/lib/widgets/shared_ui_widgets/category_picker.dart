import 'package:flutter/material.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';

/// Keeps the category list out of the animal grid until the user asks for it.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Categorie',
    this.sheetTitle = 'Kies een categorie',
    this.allLabel = 'Alle dieren',
    this.compact = false,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String label;
  final String sheetTitle;
  final String allLabel;
  final bool compact;

  Future<void> _open(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: GuideStyle.background,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sheetTitle,
                            style: const TextStyle(
                              color: GuideStyle.ink,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sluiten',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: GuideStyle.ink),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 16),
                      children:
                          categories
                              .map(
                                (category) => ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    category == 'Alle' ? allLabel : category,
                                    style: const TextStyle(
                                      color: GuideStyle.ink,
                                      fontSize: 16,
                                    ),
                                  ),
                                  selected: selected == category,
                                  selectedTileColor: GuideStyle.surface,
                                  trailing:
                                      selected == category
                                          ? const Icon(
                                            Icons.check,
                                            color: GuideStyle.ink,
                                          )
                                          : null,
                                  onTap: () => Navigator.pop(context, category),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (context.mounted && value != null && value != selected) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final description = '$label: ${selected == 'Alle' ? allLabel : selected}';
    if (compact) {
      return IconButton.outlined(
        tooltip: description,
        onPressed: enabled ? () => _open(context) : null,
        style: IconButton.styleFrom(
          foregroundColor: GuideStyle.ink,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: GuideStyle.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Semantics(
          label: description,
          excludeSemantics: true,
          child: Badge(
            isLabelVisible: selected != 'Alle',
            backgroundColor: GuideStyle.ink,
            label: const Text('1'),
            child: const Icon(Icons.tune_rounded),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: description,
        child: OutlinedButton(
          onPressed: enabled ? () => _open(context) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: GuideStyle.ink,
            backgroundColor: selected == 'Alle' ? null : GuideStyle.surface,
            side: const BorderSide(color: GuideStyle.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  selected == 'Alle' ? label : selected,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
