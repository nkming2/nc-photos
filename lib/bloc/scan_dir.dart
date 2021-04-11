import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

abstract class ScanDirBlocEvent {
  const ScanDirBlocEvent();
}

class ScanDirBlocQuery extends ScanDirBlocEvent {
  const ScanDirBlocQuery(this.account, this.roots);

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

/// An external event has happened and may affect the state of this bloc
class _ScanDirBlocExternalEvent extends ScanDirBlocEvent {
  const _ScanDirBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class ScanDirBlocState {
  const ScanDirBlocState(this._account, this._files);

  Account get account => _account;
  List<File> get files => _files;

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "files: List {length: ${files.length}}, "
        "}";
  }

  final Account _account;
  final List<File> _files;
}

class ScanDirBlocInit extends ScanDirBlocState {
  const ScanDirBlocInit() : super(null, const []);
}

class ScanDirBlocLoading extends ScanDirBlocState {
  const ScanDirBlocLoading(Account account, List<File> files)
      : super(account, files);
}

class ScanDirBlocSuccess extends ScanDirBlocState {
  const ScanDirBlocSuccess(Account account, List<File> files)
      : super(account, files);
}

class ScanDirBlocFailure extends ScanDirBlocState {
  const ScanDirBlocFailure(Account account, List<File> files, this.exception)
      : super(account, files);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ScanDirBlocInconsistent extends ScanDirBlocState {
  const ScanDirBlocInconsistent(Account account, List<File> files)
      : super(account, files);
}

/// A bloc that return all files under a dir recursively
///
/// See [ScanDir]
class ScanDirBloc extends Bloc<ScanDirBlocEvent, ScanDirBlocState> {
  ScanDirBloc() : super(ScanDirBlocInit()) {
    _fileRemovedEventListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _fileMetadataUpdatedEventListener =
        AppEventListener<FileMetadataUpdatedEvent>(_onFileMetadataUpdatedEvent);
    _fileRemovedEventListener.begin();
    _fileMetadataUpdatedEventListener.begin();
  }

  static ScanDirBloc of(Account account) {
    final id =
        "${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer().resolve<ScanDirBloc>("ScanDirBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ScanDirBloc();
      KiwiContainer()
          .registerInstance<ScanDirBloc>(bloc, name: "ScanDirBloc($id)");
      return bloc;
    }
  }

  @override
  mapEventToState(ScanDirBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ScanDirBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _ScanDirBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  @override
  close() {
    _fileRemovedEventListener.end();
    _fileMetadataUpdatedEventListener.end();
    return super.close();
  }

  Stream<ScanDirBlocState> _onEventQuery(ScanDirBlocQuery ev) async* {
    yield ScanDirBlocLoading(ev.account, state.files);

    ScanDirBlocState cacheState = ScanDirBlocInit();
    await for (final s in _queryOffline(ev, () => cacheState)) {
      cacheState = s;
    }
    yield ScanDirBlocLoading(ev.account, cacheState.files);

    ScanDirBlocState newState = ScanDirBlocInit();
    if (cacheState.files.isEmpty) {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
        yield s;
      }
    } else {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
      }
      if (newState is ScanDirBlocSuccess) {
        yield newState;
      } else if (newState is ScanDirBlocFailure) {
        yield ScanDirBlocFailure(
            ev.account, cacheState.files, newState.exception);
      }
    }
  }

  Stream<ScanDirBlocState> _onExternalEvent(
      _ScanDirBlocExternalEvent ev) async* {
    yield ScanDirBlocInconsistent(state.account, state.files);
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ScanDirBlocExternalEvent());
  }

  void _onFileMetadataUpdatedEvent(FileMetadataUpdatedEvent ev) {
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ScanDirBlocExternalEvent());
  }

  Stream<ScanDirBlocState> _queryOffline(
          ScanDirBlocQuery ev, ScanDirBlocState Function() getState) =>
      _queryWithFileDataSource(ev, getState, FileAppDbDataSource());

  Stream<ScanDirBlocState> _queryOnline(
          ScanDirBlocQuery ev, ScanDirBlocState Function() getState) =>
      _queryWithFileDataSource(ev, getState, FileCachedDataSource());

  Stream<ScanDirBlocState> _queryWithFileDataSource(ScanDirBlocQuery ev,
      ScanDirBlocState Function() getState, FileDataSource dataSrc) async* {
    try {
      for (final r in ev.roots) {
        final dataStream = ScanDir(FileRepo(dataSrc))(ev.account, r);
        await for (final d in dataStream) {
          if (d is Exception || d is Error) {
            throw d;
          }
          yield ScanDirBlocLoading(ev.account, getState().files + d);
        }
      }
      yield ScanDirBlocSuccess(ev.account, getState().files);
    } catch (e) {
      _log.severe("[_queryWithFileDataSource] Exception while request", e);
      yield ScanDirBlocFailure(ev.account, getState().files, e);
    }
  }

  AppEventListener<FileRemovedEvent> _fileRemovedEventListener;
  AppEventListener<FileMetadataUpdatedEvent> _fileMetadataUpdatedEventListener;

  static final _log = Logger("bloc.scan_dir.ScanDirBloc");
}
