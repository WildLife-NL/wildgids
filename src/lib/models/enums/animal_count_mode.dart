/// Whether an encounter was counted, seen as an uncounted group, or uncertain.
enum AnimalCountMode {
  exact,
  group,
  unsure;

  String get label => switch (this) {
    exact => 'Exact',
    group => 'Groep',
    unsure => 'Onzeker',
  };

  String get note => switch (this) {
    exact => '',
    group => 'Aantal: groep (niet geteld).',
    unsure => 'Aantal: onbekend.',
  };

  String summary(int? count) => switch (this) {
    exact => '${count ?? 0} ${(count ?? 0) == 1 ? 'dier' : 'dieren'}',
    group => 'Groep · aantal onbekend',
    unsure => 'Aantal onbekend',
  };

  static AnimalCountMode fromNotes(String? notes) {
    final lines = (notes ?? '').split('\n').map((line) => line.trim());
    if (lines.contains(group.note)) return group;
    if (lines.contains(unsure.note)) return unsure;
    return exact;
  }

  static AnimalCountMode fromJson(Object? value) =>
      values.firstWhere((mode) => mode.name == value, orElse: () => exact);
}
