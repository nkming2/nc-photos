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
