import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/utils/ble_mac_format.dart';

class ContactRequestException implements Exception {
  const ContactRequestException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ContactApi {
  ContactApi(this._client, {Future<Position> Function()? currentPosition})
    : _currentPosition = currentPosition ?? _readCurrentPosition;

  final ApiClient _client;
  final Future<Position> Function() _currentPosition;

  static const locationTimeout = Duration(seconds: 15);
  static const requestTimeout = Duration(seconds: 20);

  Future<T> _request<T>(Future<T> request) async {
    try {
      return await request.timeout(requestTimeout);
    } on TimeoutException {
      throw const ContactRequestException(
        'De server reageert niet. Controleer je internetverbinding en probeer opnieuw.',
      );
    }
  }

  ContactRequestException _requestError(
    int status,
  ) => ContactRequestException(switch (status) {
    401 ||
    403 => 'Geen toegang tot de server. Log opnieuw in en probeer opnieuw.',
    404 =>
      'Deze tracker is niet geregistreerd bij de server. Vraag de beheerder om de tracker te registreren.',
    409 =>
      'Er is al een actief contact. Controleer je contacten en probeer opnieuw.',
    _ =>
      'Contact bijwerken mislukt. Controleer je internetverbinding en probeer opnieuw.',
  }, statusCode: status);

  static const _activeContactIdKey = 'active_contact_id';
  static const _activeContactMacKey = 'active_contact_mac';

  static Future<Position> _readCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Zet locatievoorzieningen aan om contact te registreren.',
      );
    }
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      // Contact tracing may run automatically: permission prompts belong in
      // the existing foreground location gate, not in this request method.
      throw StateError(
        'Locatietoestemming is nodig om contact te registreren.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: locationTimeout,
        ),
      );
    } on TimeoutException {
      throw StateError(
        'Huidige locatie ophalen duurt te lang. Probeer opnieuw.',
      );
    }
  }

  Future<Map<String, double>> _locationForRequest() async {
    // Fetch again for every start AND end. A cached map position or the
    // contact's starting position cannot represent where it ends.
    final position = await _currentPosition();
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      throw StateError('Geen geldige huidige locatie beschikbaar.');
    }
    return {'latitude': position.latitude, 'longitude': position.longitude};
  }

  Future<List<Contact>> getMyContacts() async {
    final response = await _request(
      _client.get('contacts/me/', authenticated: true),
    );
    if (response.statusCode != HttpStatus.ok) {
      throw _requestError(response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (decoded is Map && decoded['contacts'] is List) {
      return (decoded['contacts'] as List)
          .whereType<Map>()
          .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<Contact> startContact(String contactHardwareAddress) async {
    final mac = formatBleHardwareAddress(contactHardwareAddress);
    if (!isValidBleHardwareAddress(mac)) {
      throw ArgumentError(
        'Een volledig Bluetooth-MAC-adres is nodig om de tracker te registreren.',
      );
    }
    final location = await _locationForRequest();
    final response = await _request(
      _client.post('contact/', {
        'contactHardwareAddress': mac,
        'location': location,
      }, authenticated: true),
    );
    if (response.statusCode != HttpStatus.ok) {
      throw _requestError(response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final contact = Contact.fromJson(body);
    await _saveActiveSession(contact.id, mac);
    return contact;
  }

  Future<Contact> endContact(String contactId) async {
    final id = contactId.trim();
    if (id.isEmpty) {
      throw Exception('Geen contact-ID om te beëindigen');
    }

    final location = await _locationForRequest();
    final response = await _request(
      _client.put('contact/', {
        'contactID': id,
        'location': location,
      }, authenticated: true),
    );
    if (response.statusCode != HttpStatus.ok) {
      throw _requestError(response.statusCode);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final contact = Contact.fromJson(decoded);
    await clearActiveSession();
    debugPrint('[ContactApi] Contact ended: $id');
    return contact;
  }

  Future<Contact?> findActiveContactOnServer() async {
    final contacts = await getMyContacts();
    for (final c in contacts) {
      if (c.isActive) return c;
    }
    return null;
  }

  Future<({String? id, String? mac})> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      id: prefs.getString(_activeContactIdKey),
      mac: prefs.getString(_activeContactMacKey),
    );
  }

  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeContactIdKey);
    await prefs.remove(_activeContactMacKey);
  }

  Future<void> _saveActiveSession(String id, String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeContactIdKey, id);
    await prefs.setString(_activeContactMacKey, mac);
    debugPrint('[ContactApi] Active session: $id @ $mac');
  }
}
