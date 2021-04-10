import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/ls.dart';

class LsDirBlocItem {
  LsDirBlocItem(this.file, this.children);

  File file;

  /// Child directories under this directory, or null if this isn't a directory
  List<LsDirBlocItem> children;
}

abstract class LsDirBlocEvent {
  const LsDirBlocEvent();
}

class LsDirBlocQuery extends LsDirBlocEvent {
  const LsDirBlocQuery(this.account, this.roots);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "roots: ${roots.map((e) => e.path).toReadableString()}, "
        "}";
  }

  final Account account;
  final List<File> roots;
}

abstract class LsDirBlocState {
  const LsDirBlocState(this._account, this._items);

  Account get account => _account;
  List<LsDirBlocItem> get items => _items;

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account _account;
  final List<LsDirBlocItem> _items;
}

class LsDirBlocInit extends LsDirBlocState {
  const LsDirBlocInit() : super(null, const []);
}

class LsDirBlocLoading extends LsDirBlocState {
  const LsDirBlocLoading(Account account, List<LsDirBlocItem> items)
      : super(account, items);
}

class LsDirBlocSuccess extends LsDirBlocState {
  const LsDirBlocSuccess(Account account, List<LsDirBlocItem> items)
      : super(account, items);
}

class LsDirBlocFailure extends LsDirBlocState {
  const LsDirBlocFailure(
      Account account, List<LsDirBlocItem> items, this.exception)
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

/// A bloc that return all directories under a dir recursively
class LsDirBloc extends Bloc<LsDirBlocEvent, LsDirBlocState> {
  LsDirBloc() : super(LsDirBlocInit());

  @override
  mapEventToState(LsDirBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is LsDirBlocQuery) {
      yield* _onEventQuery(event);
    }
  }

  Stream<LsDirBlocState> _onEventQuery(LsDirBlocQuery ev) async* {
    try {
      yield LsDirBlocLoading(ev.account, state.items);

      final products = <LsDirBlocItem>[];
      for (final r in ev.roots) {
        products.addAll(await _query(ev, r));
      }
      yield LsDirBlocSuccess(ev.account, products);
    } catch (e) {
      _log.severe("[_onEventQuery] Exception while request", e);
      yield LsDirBlocFailure(ev.account, state.items, e);
    }
  }

  Future<List<LsDirBlocItem>> _query(LsDirBlocQuery ev, File root) async {
    final products = <LsDirBlocItem>[];
    final files = await Ls(FileRepo(FileWebdavDataSource()))(ev.account, root);
    for (final f in files) {
      if (f.isCollection) {
        products.add(LsDirBlocItem(f, await _query(ev, f)));
      }
      // we don't want normal files
    }
    return products;
  }

  static final _log = Logger("bloc.ls_dir.LsDirBloc");
}
