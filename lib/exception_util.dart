import 'dart:io';

import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/exception.dart';

/// Convert an exception to a user-facing string
///
/// Typically used with SnackBar to show a proper error message
String toUserString(dynamic exception) {
  if (exception is ApiException) {
    if (exception.response.statusCode == 401) {
      return L10n.global().errorUnauthenticated;
    } else if (exception.response.statusCode == 404) {
      return "404 not found";
    } else if (exception.response.statusCode == 423) {
      return L10n.global().errorLocked;
    } else if (exception.response.statusCode == 500) {
      return L10n.global().errorServerError;
    }
  } else if (exception is SocketException) {
    return L10n.global().errorDisconnected;
  } else if (exception is InvalidBaseUrlException) {
    return L10n.global().errorInvalidBaseUrl;
  }
  return exception.toString();
}
