import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/use_case/ls.dart';

class LsDirBlocItem with EquatableMixin {
  LsDirBlocItem(this.file, this.isE2ee, this.children);

  @override
  toString({bool isDeep = false}) {
    if (isDeep) {
      return "$runtimeType:${_toDeepString(0)}";
    } else {
      final childrenStr =
          children == null ? "null" : "List {length: ${children!.length}}";
      return "$runtimeType {"
          "file: '${file.path}', "
          "children: $childrenStr, "
          "}";
    }
  }

  String _toDeepString(int level) {
    String product = "\n" + " " * (level * 2) + "-${file.path}";
    if (children != null) {
      for (final c in children!) {
        product += c._toDeepString(level + 1);
      }
    }
    return product;
  }

  @override
  get props => [
        file,
        children,
      ];

  final File file;
  final bool isE2ee;

  /// Child directories under this directory
  ///
  /// Null if this dir is not listed, due to things like depth limitation
  List<LsDirBlocItem>? children;
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
    Account? account,
    File? root,
    int? depth,
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

abstract class LsDirBlocState with EquatableMixin {
  const LsDirBlocState(this.account, this.root, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "root: ${root.path}, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  @override
  get props => [
        account,
        root,
        items,
      ];

  final Account? account;
  final File root;
  final List<LsDirBlocItem> items;
}

class LsDirBlocInit extends LsDirBlocState {
  LsDirBlocInit() : super(null, File(path: ""), const []);
}

class LsDirBlocLoading extends LsDirBlocState {
  const LsDirBlocLoading(Account? account, File root, List<LsDirBlocItem> items)
      : super(account, root, items);
}

class LsDirBlocSuccess extends LsDirBlocState {
  const LsDirBlocSuccess(Account? account, File root, List<LsDirBlocItem> items)
      : super(account, root, items);
}

class LsDirBlocFailure extends LsDirBlocState {
  const LsDirBlocFailure(
      Account? account, File root, List<LsDirBlocItem> items, this.exception)
      : super(account, root, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  @override
  get props => [
        ...super.props,
        exception,
      ];

  final dynamic exception;
}

/// A bloc that return all directories under a dir recursively
class LsDirBloc extends Bloc<LsDirBlocEvent, LsDirBlocState> {
  LsDirBloc(this.fileRepo) : super(LsDirBlocInit());

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
      files = (await Ls(fileRepo)(ev.account, ev.root))
          .where((f) => f.isCollection ?? false)
          .toList();
      _cache[ev.root.path] = files;
    }
    final removes = <File>[];
    for (final f in files) {
      try {
        List<LsDirBlocItem>? children;
        if (ev.depth > 1) {
          children = await _query(ev.copyWith(root: f, depth: ev.depth - 1));
        }
        product.add(LsDirBlocItem(f, false, children));
      } on ApiException catch (e) {
        if (e.response.statusCode == 404) {
          // this could happen when the server db contains dangling entries
          _log.warning(
              "[call] HTTP404 error while listing dir: ${logFilename(f.path)}");
          removes.add(f);
        } else if (f.isCollection == true && e.response.statusCode == 403) {
          // e2ee dir
          _log.warning("[call] HTTP403 error, likely E2EE dir: ${f.path}");
          product.add(LsDirBlocItem(f, true, []));
        } else {
          rethrow;
        }
      }
    }
    if (removes.isNotEmpty) {
      files.removeWhere((f) => removes.contains(f));
    }
    return product;
  }

  final FileRepo fileRepo;

  final _cache = <String, List<File>>{};

  static final _log = Logger("bloc.ls_dir.LsDirBloc");
}
