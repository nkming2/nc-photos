import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/use_case/find_file.dart';

class ListSharingItem {
  ListSharingItem(this.share, this.file);

  final Share share;
  final File file;
}

abstract class ListSharingBlocEvent {
  const ListSharingBlocEvent();
}

class ListSharingBlocQuery extends ListSharingBlocEvent {
  const ListSharingBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

class _ListSharingBlocShareRemoved extends ListSharingBlocEvent {
  const _ListSharingBlocShareRemoved(this.share);

  @override
  toString() {
    return "$runtimeType {"
        "share: $share, "
        "}";
  }

  final Share share;
}

abstract class ListSharingBlocState {
  const ListSharingBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<ListSharingItem> items;
}

class ListSharingBlocInit extends ListSharingBlocState {
  ListSharingBlocInit() : super(null, const []);
}

class ListSharingBlocLoading extends ListSharingBlocState {
  const ListSharingBlocLoading(Account? account, List<ListSharingItem> items)
      : super(account, items);
}

class ListSharingBlocSuccess extends ListSharingBlocState {
  const ListSharingBlocSuccess(Account? account, List<ListSharingItem> items)
      : super(account, items);

  ListSharingBlocSuccess copyWith({
    Account? account,
    List<ListSharingItem>? items,
  }) =>
      ListSharingBlocSuccess(
        account ?? this.account,
        items ?? this.items,
      );
}

class ListSharingBlocFailure extends ListSharingBlocState {
  const ListSharingBlocFailure(
      Account? account, List<ListSharingItem> items, this.exception)
      : super(account, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  ListSharingBlocFailure copyWith({
    Account? account,
    List<ListSharingItem>? items,
    dynamic exception,
  }) =>
      ListSharingBlocFailure(
        account ?? this.account,
        items ?? this.items,
        exception ?? this.exception,
      );

  final dynamic exception;
}

/// List all shares from a given file
class ListSharingBloc extends Bloc<ListSharingBlocEvent, ListSharingBlocState> {
  ListSharingBloc() : super(ListSharingBlocInit()) {
    _shareRemovedListener.begin();
  }

  static ListSharingBloc of(Account account) {
    final id =
        "${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer().resolve<ListSharingBloc>("ListSharingBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListSharingBloc();
      KiwiContainer().registerInstance<ListSharingBloc>(bloc,
          name: "ListSharingBloc($id)");
      return bloc;
    }
  }

  @override
  mapEventToState(ListSharingBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListSharingBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _ListSharingBlocShareRemoved) {
      yield* _onEventShareRemoved(event);
    }
  }

  Stream<ListSharingBlocState> _onEventQuery(ListSharingBlocQuery ev) async* {
    try {
      yield ListSharingBlocLoading(ev.account, state.items);
      yield ListSharingBlocSuccess(ev.account, await _query(ev));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListSharingBlocFailure(ev.account, state.items, e);
    }
  }

  Stream<ListSharingBlocState> _onEventShareRemoved(
      _ListSharingBlocShareRemoved ev) async* {
    if (state is! ListSharingBlocSuccess && state is! ListSharingBlocFailure) {
      return;
    }
    final newItems = List.of(state.items)
        .where((element) => !identical(element.share, ev.share))
        .toList();
    // i love hacks :)
    yield (state as dynamic).copyWith(
      items: newItems,
    ) as ListSharingBlocState;
  }

  void _onShareRemovedEvent(ShareRemovedEvent ev) {
    add(_ListSharingBlocShareRemoved(ev.share));
  }

  Future<List<ListSharingItem>> _query(ListSharingBlocQuery ev) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final shares = await shareRepo.listAll(ev.account);
    final futures = shares.map((e) async {
      if (!file_util.isSupportedMime(e.mimeType)) {
        return null;
      }
      if (ev.account.roots
          .every((r) => r.isNotEmpty && !e.path.startsWith("/$r/"))) {
        // ignore files not under root dirs
        return null;
      }

      try {
        final file = await FindFile()(ev.account, e.itemSource);
        return ListSharingItem(e, file);
      } catch (_) {
        _log.warning("[_query] File not found: ${e.itemSource}");
        return null;
      }
    });
    return (await Future.wait(futures)).whereType<ListSharingItem>().toList();
  }

  late final _shareRemovedListener =
      AppEventListener<ShareRemovedEvent>(_onShareRemovedEvent);

  static final _log = Logger("bloc.list_share.ListSharingBloc");
}
