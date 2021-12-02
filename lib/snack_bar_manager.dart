import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Showing snack bars
///
/// This manager helps showing a snack bar even after the context was
/// invalidated by having another widget (presumably top-level) to handle such
/// request in a decoupled way
class SnackBarManager {
  factory SnackBarManager() => _inst;

  SnackBarManager._();

  void registerHandler(SnackBarHandler handler) {
    _handlers.add(handler);
  }

  void unregisterHandler(SnackBarHandler handler) {
    _handlers.remove(handler);
  }

  /// Show a snack bar if possible
  ///
  /// If the snack bar can't be shown at this time, return null.
  ///
  /// If [canBeReplaced] is true, this snackbar will be dismissed by the next
  /// snack bar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
    SnackBar snackBar, {
    bool canBeReplaced = false,
  }) {
    if (_canPrevBeReplaced) {
      _prevController?.close();
    }
    _canPrevBeReplaced = canBeReplaced;
    for (final h in _handlers.reversed) {
      final result = h.showSnackBar(snackBar);
      if (result != null) {
        _prevController = result;
        result.closed.whenComplete(() {
          if (identical(_prevController, result)) {
            _prevController = null;
          }
        });
        return result;
      }
    }
    _log.warning("[showSnackBar] No handler available");
    _prevController = null;
    return null;
  }

  final _handlers = <SnackBarHandler>[];
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _prevController;
  var _canPrevBeReplaced = false;

  static final _inst = SnackBarManager._();

  final _log = Logger("snack_bar_manager.SnackBarManager");
}

abstract class SnackBarHandler {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
      SnackBar snackBar);
}
