/// Hold non-persisted global variables
class SessionStorage {
  factory SessionStorage() {
    return _inst;
  }

  SessionStorage._();

  /// Whether the range select notification has been shown to user
  bool hasShowRangeSelectNotification = false;

  static SessionStorage _inst = SessionStorage._();
}
