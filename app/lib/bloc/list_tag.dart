import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/use_case/list_tag.dart';

abstract class ListTagBlocEvent {
  const ListTagBlocEvent();
}

class ListTagBlocQuery extends ListTagBlocEvent {
  const ListTagBlocQuery(this.account);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "}";

  final Account account;
}

abstract class ListTagBlocState {
  const ListTagBlocState(this.account, this.items);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "items: List {length: ${items.length}}, "
      "}";

  final Account? account;
  final List<Tag> items;
}

class ListTagBlocInit extends ListTagBlocState {
  const ListTagBlocInit() : super(null, const []);
}

class ListTagBlocLoading extends ListTagBlocState {
  const ListTagBlocLoading(Account? account, List<Tag> items)
      : super(account, items);
}

class ListTagBlocSuccess extends ListTagBlocState {
  const ListTagBlocSuccess(Account? account, List<Tag> items)
      : super(account, items);
}

class ListTagBlocFailure extends ListTagBlocState {
  const ListTagBlocFailure(Account? account, List<Tag> items, this.exception)
      : super(account, items);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final dynamic exception;
}

/// List all tags for this account
class ListTagBloc extends Bloc<ListTagBlocEvent, ListTagBlocState> {
  ListTagBloc(this._c)
      : assert(require(_c)),
        assert(ListTag.require(_c)),
        super(const ListTagBlocInit());

  static bool require(DiContainer c) => true;

  static ListTagBloc of(Account account) {
    final name = bloc_util.getInstNameForAccount("ListTagBloc", account);
    try {
      _log.fine("[of] Resolving bloc for '$name'");
      return KiwiContainer().resolve<ListTagBloc>(name);
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListTagBloc(KiwiContainer().resolve<DiContainer>());
      KiwiContainer().registerInstance<ListTagBloc>(bloc, name: name);
      return bloc;
    }
  }

  @override
  mapEventToState(ListTagBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListTagBlocQuery) {
      yield* _onEventQuery(event);
    }
  }

  Stream<ListTagBlocState> _onEventQuery(ListTagBlocQuery ev) async* {
    try {
      yield ListTagBlocLoading(ev.account, state.items);
      yield ListTagBlocSuccess(ev.account, await _query(ev));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListTagBlocFailure(ev.account, state.items, e);
    }
  }

  Future<List<Tag>> _query(ListTagBlocQuery ev) => ListTag(_c)(ev.account);

  final DiContainer _c;

  static final _log = Logger("bloc.list_tag.ListTagBloc");
}
