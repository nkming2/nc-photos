import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ValueStreamBuilder<T> extends StreamBuilder<T> {
  ValueStreamBuilder({
    super.key,
    ValueStream<T>? stream,
    required super.builder,
  }) : super(
          stream: stream,
          initialData: stream?.value,
        );
}
