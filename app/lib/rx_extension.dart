import 'package:rxdart/rxdart.dart';

extension BehaviorSubjectExtension<T> on BehaviorSubject<T> {
  void addWithValue(T Function(T value) adder) {
    add(adder(value));
  }
}
