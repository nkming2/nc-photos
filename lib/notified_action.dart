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

class NotifiedListAction<T> {
  NotifiedListAction({
    required this.list,
    required this.action,
    this.processingText,
    required this.successText,
    this.getFailureText,
    this.onActionError,
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
    final failedItems = <T>[];
    for (final item in list) {
      try {
        await action(item);
      } catch (e, stackTrace) {
        onActionError?.call(item, e, stackTrace);
        failedItems.add(item);
      }
    }
    if (failedItems.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(successText),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      final failureText = getFailureText?.call(failedItems);
      if (failureText?.isNotEmpty == true) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(failureText!),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
  }

  final List<T> list;

  /// Action to be applied to every items in [list]
  final FutureOr<void> Function(T item) action;

  /// Message to be shown before performing [action]
  final String? processingText;

  /// Message to be shown after [action] finished for each elements in [list]
  /// without throwing
  final String successText;

  /// Message to be shown if one or more [action] threw
  final String Function(List<T> failedItems)? getFailureText;

  /// Called when [action] threw when processing [item]
  final void Function(T item, Object e, StackTrace stackTrace)? onActionError;
}
