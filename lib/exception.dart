import 'package:nc_photos/api/api.dart';

class CacheNotFoundException implements Exception {
  CacheNotFoundException([this.message]);

  @override
  toString() {
    if (message == null) {
      return "CacheNotFoundException";
    } else {
      return "CacheNotFoundException: $message";
    }
  }

  final dynamic message;
}

class ApiException implements Exception {
  ApiException({this.response, this.message});

  @override
  toString() {
    if (message == null) {
      return "ApiException";
    } else {
      return "ApiException: $message";
    }
  }

  final Response response;
  final dynamic message;
}

/// Platform permission is not granted by user
class PermissionException implements Exception {
  PermissionException([this.message]);

  @override
  toString() {
    if (message == null) {
      return "PermissionException";
    } else {
      return "PermissionException: $message";
    }
  }

  final dynamic message;
}

/// The Nextcloud base URL address is invalid
class InvalidBaseUrlException implements Exception {
  InvalidBaseUrlException([this.message]);

  @override
  toString() {
    if (message == null) {
      return "InvalidBaseUrlException";
    } else {
      return "InvalidBaseUrlException: $message";
    }
  }

  final dynamic message;
}
