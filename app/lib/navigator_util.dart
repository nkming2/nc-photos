import 'package:rxdart/rxdart.dart';
import 'package:to_string/to_string.dart';

part 'navigator_util.g.dart';

@toString
class InterruptPageRoute {
  const InterruptPageRoute({required this.name, required this. arguments});

  @override
  String toString() => _$toString();

  final String name;
  final Object? arguments;
}

class InterruptPageHandler {
  InterruptPageHandler._();

  factory InterruptPageHandler() {
    return _inst ??= InterruptPageHandler._();
  }

  ValueStream<InterruptPageRoute> get stream => _controller.stream;

  void pushRoute(InterruptPageRoute route) {
    _controller.add(route);
  }

  final _controller = BehaviorSubject<InterruptPageRoute>();

  static InterruptPageHandler? _inst;
}
