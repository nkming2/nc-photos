import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/scan_local_dir.dart';

abstract class ScanLocalDirBlocEvent {
  const ScanLocalDirBlocEvent();
}

class ScanLocalDirBlocQuery extends ScanLocalDirBlocEvent {
  const ScanLocalDirBlocQuery(this.relativePaths);

  @override
  toString() => "$runtimeType {"
      "relativePaths: ${relativePaths.toReadableString()}, "
      "}";

  final List<String> relativePaths;
}

class _ScanLocalDirBlocFileDeleted extends ScanLocalDirBlocEvent {
  const _ScanLocalDirBlocFileDeleted(this.files);

  @override
  toString() => "$runtimeType {"
      "files: ${files.map((f) => f.logTag).toReadableString()}, "
      "}";

  final List<LocalFile> files;
}

abstract class ScanLocalDirBlocState {
  const ScanLocalDirBlocState(this.files);

  @override
  toString() => "$runtimeType {"
      "files: List {length: ${files.length}}, "
      "}";

  final List<LocalFile> files;
}

class ScanLocalDirBlocInit extends ScanLocalDirBlocState {
  const ScanLocalDirBlocInit() : super(const []);
}

class ScanLocalDirBlocLoading extends ScanLocalDirBlocState {
  const ScanLocalDirBlocLoading(List<LocalFile> files) : super(files);
}

class ScanLocalDirBlocSuccess extends ScanLocalDirBlocState {
  const ScanLocalDirBlocSuccess(List<LocalFile> files) : super(files);
}

class ScanLocalDirBlocFailure extends ScanLocalDirBlocState {
  const ScanLocalDirBlocFailure(List<LocalFile> files, this.exception)
      : super(files);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final dynamic exception;
}

class ScanLocalDirBloc
    extends Bloc<ScanLocalDirBlocEvent, ScanLocalDirBlocState> {
  ScanLocalDirBloc() : super(const ScanLocalDirBlocInit()) {
    on<ScanLocalDirBlocQuery>(_onScanLocalDirBlocQuery);
    on<_ScanLocalDirBlocFileDeleted>(_onScanLocalDirBlocFileDeleted);

    _fileDeletedEventListener.begin();
  }

  @override
  close() {
    _fileDeletedEventListener.end();
    return super.close();
  }

  Future<void> _onScanLocalDirBlocQuery(
      ScanLocalDirBlocQuery event, Emitter<ScanLocalDirBlocState> emit) async {
    final shouldEmitIntermediate = state.files.isEmpty;
    try {
      emit(ScanLocalDirBlocLoading(state.files));
      final c = KiwiContainer().resolve<DiContainer>();
      final products = <LocalFile>[];
      for (final p in event.relativePaths) {
        if (shouldEmitIntermediate) {
          emit(ScanLocalDirBlocLoading(products));
        }
        final files = await ScanLocalDir(c)(p);
        products.addAll(files);
      }
      emit(ScanLocalDirBlocSuccess(products));
    } catch (e, stackTrace) {
      _log.severe(
          "[_onScanLocalDirBlocQuery] Exception while request", e, stackTrace);
      emit(ScanLocalDirBlocFailure(state.files, e));
    }
  }

  Future<void> _onScanLocalDirBlocFileDeleted(
      _ScanLocalDirBlocFileDeleted event,
      Emitter<ScanLocalDirBlocState> emit) async {
    final newFiles = state.files
        .where((f) => !event.files.any((d) => d.compareIdentity(f)))
        .toList();
    if (newFiles.length != state.files.length) {
      emit(ScanLocalDirBlocSuccess(newFiles));
    }
  }

  void _onFileDeletedEvent(LocalFileDeletedEvent ev) {
    if (state is ScanLocalDirBlocInit) {
      return;
    }
    add(_ScanLocalDirBlocFileDeleted(ev.files));
  }

  late final _fileDeletedEventListener =
      AppEventListener<LocalFileDeletedEvent>(_onFileDeletedEvent);

  static final _log = Logger("bloc.scan_local_dir.ScanLocalDirBloc");
}
