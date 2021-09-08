import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';

class NotifiedAction {
  NotifiedAction(
    this.action,
    this.processingText,
    this.successText, {
    this.failureText,
  });

  Future<void> call() async {
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;
    if (processingText != null) {
      controller = SnackBarManager().showSnackBar(SnackBar(
        content: Text(processingText!),
        duration: k.snackBarDurationShort,
      ));
    }
    controller?.closed.whenComplete(() {
      controller = null;
    });
    try {
      await action();
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(successText),
        duration: k.snackBarDurationNormal,
      ));
    } catch (e) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            (failureText?.isNotEmpty == true ? "$failureText: " : "") +
                exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      rethrow;
    }
  }

  final FutureOr<void> Function() action;

  /// Message to be shown before performing [action]
  final String? processingText;

  /// Message to be shown after [action] finished without throwing
  final String successText;

  /// Message to be shown if [action] threw, prepending the exception
  final String? failureText;
}
