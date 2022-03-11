import 'package:flutter/widgets.dart';

abstract class Disposable {
  void init(State state);
  void dispose(State state);
}

mixin DisposableManagerMixin<T extends StatefulWidget> on State<T> {
  @override
  initState() {
    super.initState();
    for (final d in _disposables) {
      d.init(this);
    }
  }

  @override
  dispose() {
    for (final d in _disposables) {
      d.dispose(this);
    }
    super.dispose();
  }

  /// Return a list of [Disposable] to be managed
  @mustCallSuper
  List<Disposable> initDisposables() {
    return [];
  }

  late final _disposables = initDisposables();
}
