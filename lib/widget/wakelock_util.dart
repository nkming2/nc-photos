import 'package:flutter/widgets.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:wakelock/wakelock.dart';

class WakelockControllerDisposable implements Disposable {
  @override
  init(State state) {
    Wakelock.enable();
  }

  @override
  dispose(State state) {
    Wakelock.disable();
  }
}
