import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/beta_models/interaction_model.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';

class InteractionManager implements InteractionInterface {
  final InteractionApiInterface interactionAPI;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSendingCachedData = false;

  InteractionManager({required this.interactionAPI, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    if (results.any((result) => result != ConnectivityResult.none)) {
      await _trySendCachedData();
    }
  }

  Future<void> _trySendCachedData() async {
    if (_isSendingCachedData) return;
    _isSendingCachedData = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString('userID');
      if (userID == null) return;
      final pending = List<String>.from(
        prefs.getStringList('interaction_cache') ?? [],
      );
      for (final encoded in pending.toSet()) {
        try {
          final interaction = Interaction.fromJson(
            jsonDecode(encoded) as Map<String, dynamic>,
          );
          if (interaction.userID != userID) continue;
          await interactionAPI.sendInteraction(interaction);
          await _removeCachedPayload(prefs, encoded);
        } catch (e) {
          // Keep unreadable and failed entries without blocking other reports.
          debugPrint('[InteractionManager] Cached report retained: $e');
        }
      }
    } finally {
      _isSendingCachedData = false;
    }
  }

  Future<void> _removeCachedPayload(
    SharedPreferences prefs,
    String encoded,
  ) async {
    // Read the current queue so reports added during a request are preserved.
    final remaining = List<String>.from(
      prefs.getStringList('interaction_cache') ?? [],
    )..removeWhere((entry) => entry == encoded);
    await prefs.setStringList('interaction_cache', remaining);
  }

  @override
  Future<InteractionResponse?> postInteraction(
    Reportable report,
    InteractionType type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    if (userID == null) {
      throw Exception("User Profile Wasn't Loaded!");
    }
    final interaction = Interaction(
      interactionType: type,
      userID: userID,
      report: report,
    );

    // Connectivity hints can report none while the API is still reachable.
    // Use the actual request to decide whether the report must be queued.
    try {
      final response = await interactionAPI.sendInteraction(interaction);
      await _removeCachedPayload(prefs, jsonEncode(interaction.toJson()));
      return response;
    } on SocketException {
      await _cacheInteraction(interaction);
      return null;
    } on http.ClientException {
      await _cacheInteraction(interaction);
      return null;
    }
  }

  Future<void> _cacheInteraction(Interaction interaction) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = List<String>.from(
      prefs.getStringList('interaction_cache') ?? [],
    );
    final encoded = jsonEncode(interaction.toJson());
    if (!pending.contains(encoded)) {
      pending.add(encoded);
      await prefs.setStringList('interaction_cache', pending);
    }
  }
}
