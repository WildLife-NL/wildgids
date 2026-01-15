class SpeciesImageResolver {
  static const String _blackIconsDir = 'assets/black_icons_animal';
  static const String _realDir = 'assets/real_animal_pics_no_bg';

  // Canonical base names used by both directories (case-sensitive as per files)
  static final Map<String, String> _base = {
    'vos': 'vos',
    'wolf': 'wolf',
    'ree': 'ree',
    'damhert': 'Damhert',
    'edelhert': 'Edelhert',
    'bever': 'bever',
    'eekhoorn': 'eekhoorn',
    'konijn': 'konijn',
    'haas': 'haas',
    'das': 'das',
    'steenmarter': 'steenmarter',
    'boommarter': 'Boommarter',
    'bunzing': 'Bunzing',
    'wilde kat': 'wilde_kat',
    'wild kat': 'wilde_kat',
    'konik': 'Konikpaard',
    'konikpaard': 'Konikpaard',
    'shetland pony': 'Shetland_pony',
    'pony': 'Shetland_pony',
    'ponys': 'Shetland_pony',
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
    'wild zwijn': 'Wild_Zwijn',
    'zwijn': 'Wild_Zwijn',
  };

  static String _normalize(String? name) => (name ?? '').trim().toLowerCase();

  // Not-clicked => return black icon
  static String? drawingForCommonName(String? commonName) {
    final base = _base[_normalize(commonName)];
    if (base == null) return null;
    return '$_blackIconsDir/${base}_black_icon-removebg-preview.png';
  }

  // Map canonical base to the exact filename base used in real_animal_pics_no_bg
  static final Map<String, String> _realFileBase = {
    'bever': 'bever',
    'Boommarter': 'Boommarter',
    'Bunzing': 'Bunzing',
    'Damhert': 'Damhert',
    'das': 'das',
    'Edelhert': 'Edelhert',
    'eekhoorn': 'eekhoorn',
    'egel': 'egel',
    'Europese_Nerts': 'Europese_Nerts',
    'Exmoor_Pony': 'Exmoor_Pony',
    'Galloway': 'Galloway',
    'Goudjakhals': 'Goudjakhals',
    'haas': 'haas',
    'Hermelijn': 'Hermelijn',
    'Hooglander': 'Hooglander',
    'konijn': 'konijn',
    'Konikpaard': 'Konikpaard',
    'otter': 'otter',
    'ree': 'ree',
    'Shetland_pony': 'Shetland_pony',
    'steenmarter': 'steenmarter',
    'Tauros': 'Tauros',
    'vos': 'vos',
    'wezel': 'wezel',
    'wilde_kat': 'wilde_kat',
    'Wild_Zwijn': 'Wild_Zwijn',
    'Wisent': 'Wisen', // real folder uses Wisen
    'wolf': 'wolf',
    // Intentionally omit entries that have no real image (e.g., 'woelrat') to trigger paw fallback
  };

  // Clicked => return real photo if available; otherwise null so UI shows paw
  static String? realForCommonName(String? commonName) {
    final base = _base[_normalize(commonName)];
    if (base == null) return null;
    final realBase = _realFileBase[base];
    if (realBase == null) return null;
    return '$_realDir/real_${realBase}.png';
  }
}
