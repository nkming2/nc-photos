import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/exception.dart';

/// Convert an exception to a user-facing string
///
/// Typically used with SnackBar to show a proper error message
String toUserString(dynamic exception, BuildContext context) {
  if (exception is ApiException) {
    if (exception.response.statusCode == 401) {
      return AppLocalizations.of(context).errorUnauthenticated;
    }
  } else if (exception is SocketException) {
    return AppLocalizations.of(context).errorDisconnected;
  }
  return exception.toString();
}
