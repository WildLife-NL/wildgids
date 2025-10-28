import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/beta_models/interaction_model.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';
import 'package:wildrapport/utils/connection_checker.dart';

class InteractionManager implements InteractionInterface {
  final InteractionApiInterface interactionAPI;
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  bool _isRetryingSend = false;

  InteractionManager({
    required this.interactionAPI, 
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  void init() {
    debugPrint("[InteractionManager]: Initializing!");
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    debugPrint(results.toString());

    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      await _trySendCachedData();
    } else {
      debugPrint('No internet connection – future data will be cached.');
    }
  }

  void _scheduleRetryUntilSuccess() {
    if (_isRetryingSend) return;
    _isRetryingSend = true;

    _retryLoop();
  }

  void _retryLoop() async {
    while (true) {
      bool hasConnection = await ConnectionChecker.hasInternetConnection();
      if (hasConnection) {
        try {
          await _trySendCachedData();
          debugPrint("$greenLog Successfully sent cached data.");
          _isRetryingSend = false;
          break; // Stop retrying after success
        } catch (e) {
          debugPrint("$yellowLog Retry failed. Will try again in 10 seconds.");
        }
      } else {
        debugPrint("$yellowLog No internet. Will check again in 10 seconds.");
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  Future<void> _trySendCachedData() async {
    if (!await ConnectionChecker.hasInternetConnection()) {
      debugPrint("$yellowLog Internet not fully ready. Retry later.");
      _scheduleRetryUntilSuccess();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await _doesInteractionCacheExist()) {
      final List<Interaction> interactions =
          await _getAlreadyStoredInteractions();
      final List<Interaction> interactionsAfterSending = List.from(
        interactions,
      );
      int interactionIndex = 0;
      for (Interaction interaction in interactions) {
        try {
          await interactionAPI.sendInteraction(interaction);
          interactionsAfterSending.remove(interaction);
          debugPrint("$greenLog Interaction $interactionIndex Send!");
          interactionIndex++;
        } catch (e, stackTrace) {
          debugPrint("");
          debugPrint("$redLog Something went wrong at $interactionIndex");
          debugPrint("");
          debugPrint("$yellowLog ${prefs.getStringList('interaction_cache')}");
          debugPrint("");
          debugPrint("$redLog ${e.toString()}");
          debugPrint(stackTrace.toString());
          debugPrint("");
        }
      }
      _updateCache(interactionsAfterSending);
    }
  }

  Future<void> _updateCache(List<Interaction> interactionsAfterSending) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (interactionsAfterSending.isEmpty) {
      await prefs.setStringList('interaction_cache', []);
    } else {
      List<Interaction> cachedInteractions =
          await _getAlreadyStoredInteractions();
      if (cachedInteractions.isEmpty) {
        await prefs.setStringList('interaction_cache', []);
      } else {
        for (Interaction interaction in interactionsAfterSending) {
          cachedInteractions.remove(interaction);
        }
      }
    }
  }

  @override
  Future<InteractionResponse?> postInteraction(
    Reportable report,
    InteractionType type,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userID = prefs.getString("userID");

    if (userID == null) {
      throw Exception("User Profile Wasn't Loaded!");
    }

    final results = await _connectivity.checkConnectivity();
    debugPrint(results.toString());
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    final interaction = Interaction(
      interactionType: type,
      userID: userID,
      report: report,
    );

    if (hasConnection) {
      debugPrint("$yellowLog [InteractionManager]: Sending Interaction!");
      return interactionAPI.sendInteraction(interaction);
    } else {
      debugPrint("$yellowLog [InteractionManager]: Caching Interaction!");
      _cacheInteraction(interaction);
      return null;
    }
  }

  Future<bool> _doesInteractionCacheExist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList("interaction_cache") != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<Interaction>> _getAlreadyStoredInteractions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStringList = prefs.getStringList('interaction_cache');

    if (jsonStringList != null) {
      return jsonStringList
          .map((jsonString) => Interaction.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    //If No cache exists, return empty list
    return [];
  }

  Future<void> _cacheInteraction(Interaction interaction) async {
    debugPrint("[InteractionManager]: Starting Cache Process");
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<Interaction> interactions =
        await _getAlreadyStoredInteractions();
    debugPrint("[InteractionManager]: Got aready stored interactions");
    interactions.add(interaction);
    debugPrint("[InteractionManager]: Added interaction to cache list");

    List<String> interactionJson =
        interactions.map((obj) => jsonEncode(obj.toJson())).toList();

    for (String interactionString in interactionJson) {
      debugPrint(interactionString);
    }

    await prefs.setStringList('interaction_cache', interactionJson);
  }
}

