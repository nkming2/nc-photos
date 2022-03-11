/// Hold non-persisted global variables
class SessionStorage {
  factory SessionStorage() {
    return _inst;
  }

  SessionStorage._();

  /// Whether the range select notification has been shown to user
  bool hasShowRangeSelectNotification = false;

  /// Whether the drag to rearrange notification has been shown
  bool hasShowDragRearrangeNotification = false;

  static final _inst = SessionStorage._();
}
