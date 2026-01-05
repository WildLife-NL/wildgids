import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/screen_state_interface.dart';
import 'package:wildgids/providers/app_state_provider.dart';

/// Abstract base class to manage per-screen persistent state using AppStateProvider.
abstract class ScreenStateManager<T extends StatefulWidget> extends State<T>
    implements ScreenStateInterface {
  late AppStateProvider _provider;

  @override
  void initState() {
    super.initState();
    // Cache the provider after the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<AppStateProvider>();
      loadScreenState();
    });
  }

  @override
  void dispose() {
    // Use cached provider instead of context to avoid lookup errors
    saveScreenState();
    super.dispose();
  }

  /// Returns the default state values for this screen.
  Map<String, dynamic> getInitialState();

  /// A unique identifier for the screen (used for persisting values).
  String get screenName;

  @override
  void loadScreenState() {
    final initialState = getInitialState();
    final currentState = getCurrentState();

    initialState.forEach((key, defaultValue) {
      final savedValue = _provider.getScreenState<dynamic>(screenName, key);
      final value = savedValue ?? defaultValue;
      if (currentState[key] != value) {
        updateState(key, value);
      }
    });
  }

  @override
  void saveScreenState() {
    final currentState = getCurrentState();
    currentState.forEach((key, value) {
      _provider.setScreenState(screenName, key, value);
    });
  }

  /// Updates a specific state key with a new value.
  @override
  void updateState(String key, dynamic value);

  /// Returns the current state values for this screen.
  @override
  Map<String, dynamic> getCurrentState();

  /// Calls setState safely only if the widget is still mounted.
  @override
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}

