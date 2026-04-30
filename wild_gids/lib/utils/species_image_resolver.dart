class SpeciesImageResolver {
  static const String _colorAnimalsDir = 'assets/images/color-animals';
  static const String _realDir = 'assets/real_animal_pics_no_bg';

  // Map API/common names → canonical base name
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

  // Map canonical base → actual filename (LOWERCASE!)
  static final Map<String, String> _colorFileBase = {
    'Galloway': 'galloway',
    'Hooglander': 'hooglander',
    'Damhert': 'damhert',
    'Europese_Nerts': 'europesenerts',
    'Bunzing': 'bunzing',
    'Wisent': 'wisent',
    'Goudjakhals': 'goudjakhals',
    'Edelhert': 'edelhert',
    'Konikpaard': 'konikpaard',
    'wilde_kat': 'wildkat',
    'Boommarter': 'boommarter',
    'Hermelijn': 'hermelijn',
    'Wild_Zwijn': 'wildzwijn',
    'Taurus': 'taurus',
    'bever': 'bever',
    'das': 'das',
    'eekhoorn': 'eekhoorn',
    'egel': 'egel',
    'haas': 'haas',
    'konijn': 'konijn',
    'otter': 'otter',
    'ree': 'ree',
    'steenmarter': 'steenmarter',
    'vos': 'vos',
    'wezel': 'wezel',
    'wolf': 'wolf',
    'woelrat': 'woelrat',
    'Shetland_pony': 'shetlandpony',
    'Exmoor_Pony': 'exmoorpony',

  };

  // Real image mapping (keep as-is mostly)
  static final Map<String, String> _realFileBase = {
    'bever': 'bever',
    'Boommarter': 'boommarter',
    'Bunzing': 'bunzing',
    'Damhert': 'damhert',
    'das': 'das',
    'Edelhert': 'edelhert',
    'eekhoorn': 'eekhoorn',
    'egel': 'egel',
    'Europese_Nerts': 'europese_Nerts',
    'Exmoor_Pony': 'Exmoor_Pony',
    'Galloway': 'galloway',
    'Goudjakhals': 'Goudjakhals',
    'haas': 'haas',
    'Hermelijn': 'Hermelijn',
    'Hooglander': 'Hooglander',
    'konijn': 'konijn',
    'Konikpaard': 'konikpaard',
    'otter': 'otter',
    'ree': 'ree',
    'Shetland_pony': 'shetland_pony',
    'steenmarter': 'steenmarter',
    'Tauros': 'taurus',
    'vos': 'vos',
    'wezel': 'wezel',
    'wilde_kat': 'wilde_kat',
    'Wild_Zwijn': 'wild_zwijn',
    'Wisent': 'wisen', // intentional (your folder naming)
    'wolf': 'wolf',
  };

  static String _normalize(String? name) =>
      (name ?? '').trim().toLowerCase();

  /// Used in grid (initial hidden/preview state)
  static String? drawingForCommonName(String? commonName) {
    final base = _base[_normalize(commonName)];
    if (base == null) return null;

    final colorBase = _colorFileBase[base];
    if (colorBase == null) return null;

    return '$_colorAnimalsDir/$colorBase.png';
  }

    /// Used after clicking (real photo)
  static String? realForCommonName(String? commonName) {
    final base = _base[_normalize(commonName)];
    if (base == null) return null;

    final realBase = _realFileBase[base];
    if (realBase == null) return null;

    return '$_realDir/real_$realBase.png';
  }
}
