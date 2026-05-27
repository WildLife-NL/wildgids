import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/models/api_models/contact_model.dart';

class ContactApi {
  ContactApi(this._client);

  final ApiClient _client;

  static const _activeContactIdKey = 'active_contact_id';
  static const _activeContactMacKey = 'active_contact_mac';

  Future<List<Contact>> getMyContacts() async {
    final response = await _client.get('contacts/me/', authenticated: true);
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Contacten laden mislukt (${response.statusCode}): ${response.body}',
      );
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
    final response = await _client.post(
      'contact/',
      {'contactHardwareAddress': contactHardwareAddress},
      authenticated: true,
    );
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Contact starten mislukt (${response.statusCode}): ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final contact = Contact.fromJson(body);
    await _saveActiveSession(contact.id, contactHardwareAddress);
    return contact;
  }

  Future<Contact> endContact(String contactId) async {
    final id = contactId.trim();
    if (id.isEmpty) {
      throw Exception('Geen contact-ID om te beëindigen');
    }

    final response = await _client.put(
      'contact/',
      {'contactID': id},
      authenticated: true,
    );
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Contact beëindigen mislukt (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    await clearActiveSession();
    debugPrint('[ContactApi] Contact ended: $id');
    return Contact.fromJson(decoded);
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
