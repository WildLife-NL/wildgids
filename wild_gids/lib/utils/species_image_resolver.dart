class SpeciesImageResolver {
  static const String _drawingsDir = 'assets/animal_drawings_no_bg';
  static const String _realDir = 'assets/real_animal_pics_no_bg';

  // Map lowercased common names to the canonical asset base names used in files
  // Include common aliases to improve matching.
  static final Map<String, String> _baseName = {
    'vos': 'vos',
    'wolf': 'wolf',
    'ree': 'ree',
    'damhert': 'Damhert',
    'edelhert': 'Edelhert',
    'hert': 'deer', // fallback (may not exist for real/drawing split)
    'wild zwijn': 'Wild_Zwijn',
    'zwijn': 'Wild_Zwijn',
    'bever': 'Bever',
    'eekhoorn': 'eekhoorn',
    'konijn': 'konijn',
    'haas': 'haas',
    'das': 'Das',
    'steenmarter': 'steenmarter',
    'boommarter': 'Boommarter',
    'bunzing': 'Bunzing',
    'wilde kat': 'wilde_kat',
    'konik': 'Konikpaard',
    'konikpaard': 'Konikpaard',
    'shetland pony': 'Shetland_pony',
    'pony': 'Shetland_pony',
    'galloway': 'Galloway',
    'wisent': 'Wisent',
    'tauros': 'Tauros',
    'hermelijn': 'Hermelijn',
    'wezel': 'wezel',
    'woelrat': 'woelrat',
    'egel': 'egel',
    'europese nerts': 'Europese_Nerts',
    'exmoor pony': 'Exmoor_Pony',
    'hooglander': 'Hooglander',
    'goudjakhals': 'Goudjakhals',
    'otter': 'otter',
  };

  static String _normalize(String? name) {
    return (name ?? '').trim().toLowerCase();
  }

  static String? drawingForCommonName(String? commonName) {
    final key = _normalize(commonName);
    final base = _baseName[key];
    if (base == null) return null;
    return '$_drawingsDir/${base}_drawing.png';
  }

  static String? realForCommonName(String? commonName) {
    final key = _normalize(commonName);
    final base = _baseName[key];
    if (base == null) return null;
    // Notable exception: Wisent file is misspelled as Wisen in real images
    final realBase = (base == 'Wisent') ? 'Wisen' : base;
    return '$_realDir/real_$realBase.png';
  }
}
