import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart';
import 'dart:collection';

/// Global manager for encounter messages
/// Handles queuing, deduplication, and display coordination
class EncounterMessageManager extends ChangeNotifier {
  static final EncounterMessageManager _instance = EncounterMessageManager._internal();
  factory EncounterMessageManager() => _instance;
  EncounterMessageManager._internal();

  final Queue<TrackingNotice> _messageQueue = Queue<TrackingNotice>();
  final Map<String, DateTime> _shownMessages = <String, DateTime>{};
  bool _isShowingMessage = false;

  /// How long to remember shown messages (5 minutes)
  static const Duration _deduplicationWindow = Duration(minutes: 5);

  /// Check if currently showing a message
  bool get isShowingMessage => _isShowingMessage;
  
  /// Get the number of queued messages
  int get queueSize => _messageQueue.length;

  /// Add a notice to the queue (with time-based deduplication)
  void addNotice(TrackingNotice notice) {
    final key = _getNoticeKey(notice);
    final now = DateTime.now();
    
    debugPrint('[EncounterManager] addNotice called for: $key');
    
    // Clean up old entries
    _shownMessages.removeWhere((k, timestamp) => 
      now.difference(timestamp) > _deduplicationWindow
    );
    
    debugPrint('[EncounterManager] After cleanup: ${_shownMessages.length} messages in history');
    
    // Skip if shown recently
    if (_shownMessages.containsKey(key)) {
      final lastShown = _shownMessages[key]!;
      final timeSince = now.difference(lastShown);
      debugPrint('[EncounterManager] Skipping duplicate: $key (shown ${timeSince.inSeconds}s ago)');
      return;
    }

    // Add to queue
    _messageQueue.add(notice);
    _shownMessages[key] = now;

    debugPrint('[EncounterManager] ✓✓✓ Added notice to queue: $key (Queue size: ${_messageQueue.length})');
    debugPrint('[EncounterManager] About to call notifyListeners()...');
    notifyListeners();
    debugPrint('[EncounterManager] notifyListeners() called!');
  }

  /// Get the next message from the queue
  TrackingNotice? getNextMessage() {
    debugPrint('[EncounterManager] getNextMessage called - Queue: ${_messageQueue.length}, isShowing: $_isShowingMessage');
    
    if (_messageQueue.isEmpty) {
      debugPrint('[EncounterManager] Queue is empty, returning null');
      return null;
    }
    
    if (_isShowingMessage) {
      debugPrint('[EncounterManager] Already showing a message, returning null');
      return null;
    }
    
    _isShowingMessage = true;
    final notice = _messageQueue.removeFirst();
    debugPrint('[EncounterManager] ✓ Returning message: ${notice.text}');
    notifyListeners();
    return notice;
  }

  /// Mark current message as dismissed
  void markMessageDismissed() {
    _isShowingMessage = false;
    debugPrint('[EncounterManager] Message dismissed (Remaining: ${_messageQueue.length})');
    notifyListeners();
  }

  /// Get unique key for a notice
  String _getNoticeKey(TrackingNotice notice) {
    return '${notice.text}|${notice.severity ?? ''}';
  }

  /// Clear all messages and history
  void clear() {
    _messageQueue.clear();
    _shownMessages.clear();
    _isShowingMessage = false;
    debugPrint('[EncounterManager] ✓ Cleared all messages and history');
    notifyListeners();
  }

  /// Clear only the deduplication history (for testing)
  void clearHistory() {
    _shownMessages.clear();
    debugPrint('[EncounterManager] ✓ Cleared deduplication history');
  }

  /// Trigger vibration feedback
  Future<void> vibrate() async {
    try {
      await HapticFeedback.mediumImpact();
      // Additional vibration for emphasis
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('[EncounterManager] Vibration failed: $e');
    }
  }
}
