import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/ls.dart';

class LsDirBlocItem {
  LsDirBlocItem(this.file, this.children);

  @override
  toString({bool isDeep = false}) {
    if (isDeep) {
      return "$runtimeType:${_toDeepString(0)}";
    } else {
      return "$runtimeType {"
          "file: '${file.path}', "
          "children: List {length: ${children.length}}, "
          "}";
    }
  }

  String _toDeepString(int level) {
    String product = "\n" + " " * (level * 2) + "-${file.path}";
    if (children != null) {
      for (final c in children) {
        product += c._toDeepString(level + 1);
      }
    }
    return product;
  }

  File file;

  /// Child directories under this directory
  ///
  /// Null if this dir is not listed, due to things like depth limitation
  List<LsDirBlocItem> children;
}

abstract class LsDirBlocEvent {
  const LsDirBlocEvent();
}

class LsDirBlocQuery extends LsDirBlocEvent {
  const LsDirBlocQuery(
    this.account,
    this.root, {
    this.depth = 1,
  });

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "root: '${root.path}', "
        "depth: $depth, "
        "}";
  }

  LsDirBlocQuery copyWith({
    Account account,
    File root,
    int depth,
  }) {
    return LsDirBlocQuery(
      account ?? this.account,
      root ?? this.root,
      depth: depth ?? this.depth,
    );
  }

  final Account account;
  final File root;
  final int depth;
}

abstract class LsDirBlocState {
  const LsDirBlocState(this._account, this._root, this._items);

  Account get account => _account;
  File get root => _root;
  List<LsDirBlocItem> get items => _items;

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "root: ${root.path}"
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account _account;
  final File _root;
  final List<LsDirBlocItem> _items;
}

class LsDirBlocInit extends LsDirBlocState {
  LsDirBlocInit() : super(null, File(path: ""), const []);
}

class LsDirBlocLoading extends LsDirBlocState {
  const LsDirBlocLoading(Account account, File root, List<LsDirBlocItem> items)
      : super(account, root, items);
}

class LsDirBlocSuccess extends LsDirBlocState {
  const LsDirBlocSuccess(Account account, File root, List<LsDirBlocItem> items)
      : super(account, root, items);
}

class LsDirBlocFailure extends LsDirBlocState {
  const LsDirBlocFailure(
      Account account, File root, List<LsDirBlocItem> items, this.exception)
      : super(account, root, items);

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
      yield LsDirBlocLoading(ev.account, ev.root, state.items);
      yield LsDirBlocSuccess(ev.account, ev.root, await _query(ev));
    } catch (e) {
      _log.severe("[_onEventQuery] Exception while request", e);
      yield LsDirBlocFailure(ev.account, ev.root, state.items, e);
    }
  }

  Future<List<LsDirBlocItem>> _query(LsDirBlocQuery ev) async {
    final product = <LsDirBlocItem>[];
    var files = _cache[ev.root.path];
    if (files == null) {
      files = (await Ls(FileRepo(FileWebdavDataSource()))(ev.account, ev.root))
          .where((f) => f.isCollection)
          .toList();
      _cache[ev.root.path] = files;
    }
    for (final f in files) {
      List<LsDirBlocItem> children;
      if (ev.depth > 1) {
        children = await _query(ev.copyWith(root: f, depth: ev.depth - 1));
      }
      product.add(LsDirBlocItem(f, children));
    }
    return product;
  }

  final _cache = <String, List<File>>{};

  static final _log = Logger("bloc.ls_dir.LsDirBloc");
}
