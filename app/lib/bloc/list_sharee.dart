import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sharee/data_source.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'list_sharee.g.dart';

abstract class ListShareeBlocEvent {
  const ListShareeBlocEvent();
}

@toString
class ListShareeBlocQuery extends ListShareeBlocEvent {
  const ListShareeBlocQuery(this.account);

  @override
  String toString() => _$toString();

  final Account account;
}

@toString
abstract class ListShareeBlocState {
  const ListShareeBlocState(this.account, this.items);

  @override
  String toString() => _$toString();

  final Account? account;
  final List<Sharee> items;
}

class ListShareeBlocInit extends ListShareeBlocState {
  ListShareeBlocInit() : super(null, const []);
}

class ListShareeBlocLoading extends ListShareeBlocState {
  const ListShareeBlocLoading(Account? account, List<Sharee> items)
      : super(account, items);
}

class ListShareeBlocSuccess extends ListShareeBlocState {
  const ListShareeBlocSuccess(Account? account, List<Sharee> items)
      : super(account, items);
}

@toString
class ListShareeBlocFailure extends ListShareeBlocState {
  const ListShareeBlocFailure(
      Account? account, List<Sharee> items, this.exception)
      : super(account, items);

  @override
  String toString() => _$toString();

  final dynamic exception;
}

/// List all sharees of this account
@npLog
class ListShareeBloc extends Bloc<ListShareeBlocEvent, ListShareeBlocState> {
  ListShareeBloc() : super(ListShareeBlocInit()) {
    on<ListShareeBlocEvent>(_onEvent);
  }

  static ListShareeBloc of(Account account) {
    final name = bloc_util.getInstNameForAccount("ListShareeBloc", account);
    try {
      _log.fine("[of] Resolving bloc for '$name'");
      return KiwiContainer().resolve<ListShareeBloc>(name);
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListShareeBloc();
      KiwiContainer().registerInstance<ListShareeBloc>(bloc, name: name);
      return bloc;
    }
  }

  Future<void> _onEvent(
      ListShareeBlocEvent event, Emitter<ListShareeBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListShareeBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListShareeBlocQuery ev, Emitter<ListShareeBlocState> emit) async {
    try {
      emit(ListShareeBlocLoading(ev.account, state.items));
      emit(ListShareeBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.shout("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListShareeBlocFailure(ev.account, state.items, e));
    }
  }

  Future<List<Sharee>> _query(ListShareeBlocQuery ev) {
    final shareeRepo = ShareeRepo(ShareeRemoteDataSource());
    return shareeRepo.list(ev.account);
  }

  static final _log = _$ListShareeBlocNpLog.log;
}
