import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/cache_favorite.dart';
import 'package:nc_photos/use_case/list_favorite.dart';
import 'package:nc_photos/use_case/list_favorite_offline.dart';

abstract class ListFavoriteBlocEvent {
  const ListFavoriteBlocEvent();
}

class ListFavoriteBlocQuery extends ListFavoriteBlocEvent {
  const ListFavoriteBlocQuery(this.account);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "}";

  final Account account;
}

abstract class ListFavoriteBlocState {
  const ListFavoriteBlocState(this.account, this.items);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "items: List {length: ${items.length}}, "
      "}";

  final Account? account;
  final List<File> items;
}

class ListFavoriteBlocInit extends ListFavoriteBlocState {
  const ListFavoriteBlocInit() : super(null, const []);
}

class ListFavoriteBlocLoading extends ListFavoriteBlocState {
  const ListFavoriteBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class ListFavoriteBlocSuccess extends ListFavoriteBlocState {
  const ListFavoriteBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

class ListFavoriteBlocFailure extends ListFavoriteBlocState {
  const ListFavoriteBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final dynamic exception;
}

/// List all favorites for this account
class ListFavoriteBloc
    extends Bloc<ListFavoriteBlocEvent, ListFavoriteBlocState> {
  ListFavoriteBloc(this._c)
      : assert(require(_c)),
        assert(ListFavorite.require(_c)),
        super(const ListFavoriteBlocInit()) {
    on<ListFavoriteBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) => true;

  static ListFavoriteBloc of(Account account) {
    final name =
        bloc_util.getInstNameForRootAwareAccount("ListFavoriteBloc", account);
    try {
      _log.fine("[of] Resolving bloc for '$name'");
      return KiwiContainer().resolve<ListFavoriteBloc>(name);
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListFavoriteBloc(KiwiContainer().resolve<DiContainer>());
      KiwiContainer().registerInstance<ListFavoriteBloc>(bloc, name: name);
      return bloc;
    }
  }

  Future<void> _onEvent(
      ListFavoriteBlocEvent event, Emitter<ListFavoriteBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListFavoriteBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListFavoriteBlocQuery ev, Emitter<ListFavoriteBlocState> emit) async {
    List<File>? cache;
    try {
      emit(ListFavoriteBlocLoading(ev.account, state.items));
      cache = await _queryOffline(ev);
      if (cache != null) {
        emit(ListFavoriteBlocLoading(ev.account, cache));
      }
      final remote = await _queryOnline(ev);
      emit(ListFavoriteBlocSuccess(ev.account, remote));

      if (cache != null) {
        unawaited(
          CacheFavorite(_c)(ev.account, remote.map((f) => f.fileId!))
              .onError((e, stackTrace) {
            _log.shout(
                "[_onEventQuery] Failed while CacheFavorite", e, stackTrace);
            return -1;
          }),
        );
      }
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListFavoriteBlocFailure(ev.account, cache ?? state.items, e));
    }
  }

  Future<List<File>?> _queryOffline(ListFavoriteBlocQuery ev) async {
    try {
      return await ListFavoriteOffline(_c)(ev.account);
    } catch (e, stackTrace) {
      _log.shout("[_query] Failed", e, stackTrace);
      return null;
    }
  }

  Future<List<File>> _queryOnline(ListFavoriteBlocQuery ev) {
    return ListFavorite(_c)(ev.account);
  }

  final DiContainer _c;

  static final _log = Logger("bloc.list_favorite.ListFavoriteBloc");
}
