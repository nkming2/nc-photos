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
  /// If the snack bar can't be shown at this time, return null
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
      SnackBar snackBar) {
    for (final h in _handlers.reversed) {
      final result = h.showSnackBar(snackBar);
      if (result != null) {
        return result;
      }
    }
    _log.warning("[showSnackBar] No handler available");
    return null;
  }

  final _handlers = <SnackBarHandler>[];

  static final _inst = SnackBarManager._();

  final _log = Logger("snack_bar_manager.SnackBarManager");
}

abstract class SnackBarHandler {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSnackBar(
      SnackBar snackBar);
}
