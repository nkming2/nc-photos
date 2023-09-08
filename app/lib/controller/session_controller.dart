import 'package:rxdart/rxdart.dart';

/// Manage volatile global variables bonded to an account session, when the
/// session ends (i.e., sign out), the variables are cleared
class SessionController {
  SessionController();

  void dispose() {
    _hasFiredMetadataTaskController.close();
  }

  ValueStream<bool> get hasFiredMetadataTask =>
      _hasFiredMetadataTaskController.stream;

  void setFiredMetadataTask(bool value) {
    _hasFiredMetadataTaskController.add(value);
  }

  final _hasFiredMetadataTaskController = BehaviorSubject.seeded(false);
}
