import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static Future<bool?> showToast(
    BuildContext context, {
    required String msg,
    required Duration duration,
  }) {
    return Fluttertoast.showToast(
      msg: msg,
      timeInSecForIosWeb: duration.inSeconds,
      backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
      textColor: Theme.of(context).snackBarTheme.contentTextStyle!.color,
    );
  }
}
