import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

mixin BlocLogger {
  String? get tag => null;

  bool Function(dynamic currentState, dynamic nextState)? get shouldLog => null;
}

class BlocListenerT<B extends StateStreamable<S>, S, T>
    extends SingleChildStatelessWidget {
  const BlocListenerT({
    super.key,
    required this.selector,
    required this.listener,
  });

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          selector(previous) != selector(current),
      listener: (context, state) => listener(context, selector(state)),
      child: child,
    );
  }

  final BlocWidgetSelector<S, T> selector;
  final void Function(BuildContext context, T state) listener;
}

/// Wrap around a string such that two strings with the same value will fail
/// the identical check
class StateMessage {
  StateMessage(this.value);

  final String value;
}

extension EmitterExtension<State> on Emitter<State> {
  Future<void> forEachIgnoreError<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
  }) =>
      onEach<T>(
        stream,
        onData: (data) => call(onData(data)),
        onError: (_, __) {},
      );
}

extension BlocExtension<E, S> on Bloc<E, S> {
  void safeAdd(E event) {
    if (!isClosed) {
      add(event);
    }
  }
}
