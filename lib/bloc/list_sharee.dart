import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sharee/data_source.dart';

abstract class ListShareeBlocEvent {
  const ListShareeBlocEvent();
}

class ListShareeBlocQuery extends ListShareeBlocEvent {
  const ListShareeBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

abstract class ListShareeBlocState {
  const ListShareeBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

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

class ListShareeBlocFailure extends ListShareeBlocState {
  const ListShareeBlocFailure(
      Account? account, List<Sharee> items, this.exception)
      : super(account, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// List all sharees of this account
class ListShareeBloc extends Bloc<ListShareeBlocEvent, ListShareeBlocState> {
  ListShareeBloc() : super(ListShareeBlocInit());

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

  @override
  mapEventToState(ListShareeBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListShareeBlocQuery) {
      yield* _onEventQuery(event);
    }
  }

  Stream<ListShareeBlocState> _onEventQuery(ListShareeBlocQuery ev) async* {
    try {
      yield ListShareeBlocLoading(ev.account, state.items);
      yield ListShareeBlocSuccess(ev.account, await _query(ev));
    } catch (e, stackTrace) {
      _log.shout("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListShareeBlocFailure(ev.account, state.items, e);
    }
  }

  Future<List<Sharee>> _query(ListShareeBlocQuery ev) {
    final shareeRepo = ShareeRepo(ShareeRemoteDataSource());
    return shareeRepo.list(ev.account);
  }

  static final _log = Logger("bloc.list_sharee.ListShareeBloc");
}
