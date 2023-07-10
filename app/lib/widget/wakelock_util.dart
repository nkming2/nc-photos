import 'package:flutter/widgets.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockControllerDisposable implements Disposable {
  @override
  void init(State state) {
    WakelockPlus.enable();
  }

  @override
  void dispose(State state) {
    WakelockPlus.disable();
  }
}
