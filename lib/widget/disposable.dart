import 'package:flutter/widgets.dart';

abstract class Disposable {
  void init(State state);
  void dispose(State state);
}

mixin DisposableManagerMixin<T extends StatefulWidget> on State<T> {
  @override
  initState() {
    super.initState();
    for (final d in disposables) {
      d.init(this);
    }
  }

  @override
  dispose() {
    for (final d in disposables) {
      d.dispose(this);
    }
    super.dispose();
  }

  List<Disposable> get disposables;
}
