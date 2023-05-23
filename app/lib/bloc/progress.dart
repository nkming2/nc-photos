import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'progress.g.dart';

abstract class ProgressBlocEvent {
  const ProgressBlocEvent();
}

@toString
class ProgressBlocUpdate extends ProgressBlocEvent {
  const ProgressBlocUpdate(this.progress, [this.text]);

  @override
  String toString() => _$toString();

  final double progress;
  final String? text;
}

@toString
class ProgressBlocState with EquatableMixin {
  const ProgressBlocState(this.progress, this.text);

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [progress, text];

  final double progress;
  final String? text;
}

/// A generic bloc to bubble progress update for some events
@npLog
class ProgressBloc extends Bloc<ProgressBlocEvent, ProgressBlocState> {
  ProgressBloc() : super(const ProgressBlocState(0, null)) {
    on<ProgressBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(
      ProgressBlocEvent ev, Emitter<ProgressBlocState> emit) async {
    _log.info("[_onEvent] $ev");
    if (ev is ProgressBlocUpdate) {
      await _onEventUpdate(ev, emit);
    }
  }

  Future<void> _onEventUpdate(
      ProgressBlocUpdate ev, Emitter<ProgressBlocState> emit) async {
    emit(ProgressBlocState(ev.progress, ev.text));
  }
}
