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
  ApiException({
    required this.response,
    this.message,
  });

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

/// A download job has failed
class DownloadException implements Exception {
  DownloadException([this.message]);

  @override
  toString() {
    return "DownloadException: $message";
  }

  final dynamic message;
}

/// A running job has been canceled
class JobCanceledException implements Exception {
  JobCanceledException([this.message]);

  @override
  toString() {
    return "JobCanceledException: $message";
  }

  final dynamic message;
}

/// Trying to downgrade an Album
class AlbumDowngradeException implements Exception {
  const AlbumDowngradeException([this.message]);

  @override
  toString() {
    return "AlbumDowngradeException: $message";
  }

  final dynamic message;
}

class InterruptedException implements Exception {
  const InterruptedException([this.message]);

  @override
  toString() => "InterruptedException: $message";

  final dynamic message;
}
