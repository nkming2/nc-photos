import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/exception.dart';

/// Convert an exception to a user-facing string
///
/// Typically used with SnackBar to show a proper error message
String toUserString(dynamic exception, BuildContext context) {
  if (exception is ApiException) {
    if (exception.response.statusCode == 401) {
      return L10n.of(context).errorUnauthenticated;
    } else if (exception.response.statusCode == 423) {
      return L10n.of(context).errorLocked;
    } else if (exception.response.statusCode == 500) {
      return L10n.of(context).errorServerError;
    }
  } else if (exception is SocketException) {
    return L10n.of(context).errorDisconnected;
  } else if (exception is InvalidBaseUrlException) {
    return L10n.of(context).errorInvalidBaseUrl;
  }
  return exception.toString();
}
