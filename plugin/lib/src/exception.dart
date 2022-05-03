/// Platform permission is not granted by user
class PermissionException implements Exception {
  const PermissionException([this.message]);

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
