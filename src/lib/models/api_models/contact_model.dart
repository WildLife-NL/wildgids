DateTime? _parseOptionalEnd(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return _parseContactDate(raw);
}

DateTime _parseContactDate(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return DateTime.now();
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return DateTime.now();
  final hasTz = RegExp(r'(Z|[+\-]\d{2}:\d{2})$').hasMatch(raw);
  if (!hasTz) return parsed;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

class ContactConveyance {
  final String id;
  final DateTime timestamp;
  final String? messageName;
  final String? messageText;
  final int? messageSeverity;
  final String? animalName;

  ContactConveyance({
    required this.id,
    required this.timestamp,
    this.messageName,
    this.messageText,
    this.messageSeverity,
    this.animalName,
  });

  /// User-visible line for lists and notifications.
  String get displayText {
    final text = messageText?.trim();
    if (text != null && text.isNotEmpty) return text;
    final name = messageName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '';
  }

  factory ContactConveyance.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    String? messageName;
    String? messageText;
    int? messageSeverity;
    if (message is Map) {
      messageName = message['name']?.toString();
      messageText = message['text']?.toString();
      messageText ??= message['message']?.toString();
      final sev = message['severity'];
      if (sev is num) messageSeverity = sev.toInt();
    }

    final animal = json['animal'];
    String? animalName;
    if (animal is Map) {
      animalName =
          animal['commonName']?.toString() ?? animal['name']?.toString();
      final species = animal['species'];
      if ((animalName == null || animalName.isEmpty) && species is Map) {
        animalName = species['commonName']?.toString() ??
            species['name']?.toString();
      }
    }

    return ContactConveyance(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      timestamp: _parseContactDate(json['timestamp']?.toString()),
      messageName: messageName,
      messageText: messageText,
      messageSeverity: messageSeverity,
      animalName: animalName,
    );
  }
}

class Contact {
  final String id;
  final String? contactHardwareAddress;
  final DateTime start;
  final DateTime? end;
  final String? collarAnimalName;
  final String? collarAnimalSpecies;
  final String? collarAnimalId;
  final String? sensorId;
  final List<ContactConveyance> conveyances;

  Contact({
    required this.id,
    this.contactHardwareAddress,
    required this.start,
    this.end,
    this.collarAnimalName,
    this.collarAnimalSpecies,
    this.collarAnimalId,
    this.sensorId,
    this.conveyances = const [],
  });

  bool get isActive {
    if (id.isEmpty) return false;
    return end == null;
  }

  String get animalDisplayLabel {
    final name = collarAnimalName?.trim();
    final species = collarAnimalSpecies?.trim();
    if (name != null &&
        name.isNotEmpty &&
        species != null &&
        species.isNotEmpty) {
      return '$name ($species)';
    }
    if (name != null && name.isNotEmpty) return name;
    if (species != null && species.isNotEmpty) return species;
    return 'Onbekend dier';
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    final deployment = json['borneSensorDeployment'];
    String? animalName;
    String? animalSpecies;
    String? animalId;
    String? sensorId;
    if (deployment is Map<String, dynamic>) {
      sensorId = deployment['sensorID']?.toString();
      final animal = deployment['animal'];
      if (animal is Map<String, dynamic>) {
        animalName =
            animal['commonName']?.toString() ?? animal['name']?.toString();
        final species = animal['species'];
        if (species is Map) {
          animalSpecies = species['commonName']?.toString() ??
              species['name']?.toString();
        } else if (species != null) {
          animalSpecies = species.toString();
        }
        animalId = (animal['ID'] ?? animal['id'])?.toString();
      }
    }

    final conveyancesRaw = json['conveyances'];
    final conveyances = <ContactConveyance>[];
    if (conveyancesRaw is List) {
      for (final item in conveyancesRaw) {
        if (item is Map<String, dynamic>) {
          conveyances.add(ContactConveyance.fromJson(item));
        } else if (item is Map) {
          conveyances.add(
            ContactConveyance.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Contact(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      contactHardwareAddress: json['contactHardwareAddress']?.toString(),
      start: _parseContactDate(json['start']?.toString()),
      end: _parseOptionalEnd(json['end']),
      collarAnimalName: animalName,
      collarAnimalSpecies: animalSpecies,
      collarAnimalId: animalId,
      sensorId: sensorId,
      conveyances: conveyances,
    );
  }
}
