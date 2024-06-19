import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/exception.dart';

/// Convert an exception to a user-facing string
///
/// Typically used with SnackBar to show a proper error message
String toUserString(Object? exception) {
  if (exception is ApiException) {
    if (exception.response.statusCode == 401) {
      return L10n.global().errorUnauthenticated;
    } else if (exception.response.statusCode == 404) {
      return "HTTP 404 not found";
    } else if (exception.response.statusCode == 423) {
      return L10n.global().errorLocked;
    } else if (exception.response.statusCode == 500) {
      return L10n.global().errorServerError;
    }
  } else if (exception is SocketException) {
    return L10n.global().errorDisconnected;
  } else if (exception is InvalidBaseUrlException) {
    return L10n.global().errorInvalidBaseUrl;
  } else if (exception is AlbumDowngradeException) {
    return L10n.global().errorAlbumDowngrade;
  }
  return exception?.toString() ?? "Unknown error";
}

(String text, SnackBarAction? action) exceptionToSnackBarData(
    Object? exception) {
  if (exception is ApiException) {
    if (exception.response.statusCode == 401) {
      return (L10n.global().errorUnauthenticated, null);
    } else if (exception.response.statusCode == 404) {
      return ("HTTP 404 not found", null);
    } else if (exception.response.statusCode == 423) {
      return (L10n.global().errorLocked, null);
    } else if (exception.response.statusCode == 500) {
      return (L10n.global().errorServerError, null);
    }
  } else if (exception is SocketException) {
    return (L10n.global().errorDisconnected, null);
  } else if (exception is InvalidBaseUrlException) {
    return (L10n.global().errorInvalidBaseUrl, null);
  } else if (exception is AlbumDowngradeException) {
    return (L10n.global().errorAlbumDowngrade, null);
  }
  return (exception?.toString() ?? "Unknown error", null);
}
