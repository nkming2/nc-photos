import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';

class DoubleTapExitHandler {
  factory DoubleTapExitHandler() => _inst;

  DoubleTapExitHandler._();

  /// Return if this back button event should actually exit the app
  bool call() {
    if (!Pref().isDoubleTapExitOr()) {
      return true;
    }
    final now = DateTime.now().toUtc();
    _lastBackButtonAt ??= now.subtract(const Duration(days: 1));
    if (now.difference(_lastBackButtonAt!) < const Duration(seconds: 5)) {
      return true;
    } else {
      _lastBackButtonAt = now;
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().doubleTapExitNotification),
        duration: k.snackBarDurationShort,
      ));
      return false;
    }
  }

  static final _inst = DoubleTapExitHandler._();

  DateTime? _lastBackButtonAt;
}
