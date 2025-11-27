import 'package:flutter/material.dart';
import 'package:wildrapport/managers/encounter_message_manager.dart';
import 'package:wildrapport/screens/overlay/encounter_message_overlay.dart';

/// Global widget that listens to encounter messages and displays them
/// This works across all screens without needing individual listeners
class GlobalEncounterHandler extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const GlobalEncounterHandler({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<GlobalEncounterHandler> createState() => _GlobalEncounterHandlerState();
}

class _GlobalEncounterHandlerState extends State<GlobalEncounterHandler> {
  final _manager = EncounterMessageManager();
  bool _isShowingOverlay = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[GlobalEncounterHandler] Widget initialized, adding listener');
    _manager.addListener(_checkForMessages);
    
    // Check immediately if there are any queued messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForMessages();
    });
  }

  @override
  void dispose() {
    _manager.removeListener(_checkForMessages);
    super.dispose();
  }

  void _checkForMessages() {
    // Safety: If flag is stuck but manager says not showing and queue has messages, force reset
    if (_isShowingOverlay && !_manager.isShowingMessage && _manager.queueSize > 0) {
      debugPrint('[GlobalEncounterHandler] Flag desync detected - resetting');
      _isShowingOverlay = false;
    }
    
    // Prevent showing multiple overlays
    if (_isShowingOverlay) {
      return;
    }

    final notice = _manager.getNextMessage();
    if (notice == null) {
      return;
    }

    debugPrint('[GlobalEncounterHandler] Showing overlay: ${notice.text.substring(0, notice.text.length > 50 ? 50 : notice.text.length)}...');
    _isShowingOverlay = true;

    // Trigger vibration
    _manager.vibrate();

    // Use the navigatorKey to get the correct context
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null) {
      debugPrint('[GlobalEncounterHandler] Navigator context is null, resetting flag');
      _isShowingOverlay = false;
      _manager.markMessageDismissed();
      return;
    }

    showDialog(
        context: navContext,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.28),
        builder: (context) => EncounterMessageOverlay(
          message: notice.text,
          title: notice.severity == 1
              ? 'Waarschuwing'
              : (notice.severity == 2 ? 'Melding' : 'Informatie'),
          severity: notice.severity,
        ),
      ).then((_) {
        // When overlay is dismissed, mark it and check for next message
        _isShowingOverlay = false;
        _manager.markMessageDismissed();
        
        // Check if there are more messages to show
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _checkForMessages();
          }
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
