import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/populate_person.dart';

abstract class ListFaceFileBlocEvent {
  const ListFaceFileBlocEvent();
}

class ListFaceFileBlocQuery extends ListFaceFileBlocEvent {
  const ListFaceFileBlocQuery(this.account, this.person);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "person: $person, "
      "}";

  final Account account;
  final Person person;
}

abstract class ListFaceFileBlocState {
  const ListFaceFileBlocState(this.account, this.items);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "items: List {length: ${items.length}}, "
      "}";

  final Account? account;
  final List<File> items;
}

class ListFaceFileBlocInit extends ListFaceFileBlocState {
  ListFaceFileBlocInit() : super(null, const []);
}

class ListFaceFileBlocLoading extends ListFaceFileBlocState {
  const ListFaceFileBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class ListFaceFileBlocSuccess extends ListFaceFileBlocState {
  const ListFaceFileBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

class ListFaceFileBlocFailure extends ListFaceFileBlocState {
  const ListFaceFileBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final Object exception;
}

/// List all people recognized in an account
class ListFaceFileBloc
    extends Bloc<ListFaceFileBlocEvent, ListFaceFileBlocState> {
  ListFaceFileBloc(this._c)
      : assert(require(_c)),
        assert(PopulatePerson.require(_c)),
        super(ListFaceFileBlocInit()) {
    on<ListFaceFileBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) => DiContainer.has(c, DiType.faceRepo);

  Future<void> _onEvent(
      ListFaceFileBlocEvent event, Emitter<ListFaceFileBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListFaceFileBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListFaceFileBlocQuery ev, Emitter<ListFaceFileBlocState> emit) async {
    try {
      emit(ListFaceFileBlocLoading(ev.account, state.items));
      emit(ListFaceFileBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListFaceFileBlocFailure(ev.account, state.items, e));
    }
  }

  Future<List<File>> _query(ListFaceFileBlocQuery ev) async {
    final faces = await _c.faceRepo.list(ev.account, ev.person);
    final files = await PopulatePerson(_c)(ev.account, faces);
    final rootDirs = ev.account.roots
        .map((e) => File(path: file_util.unstripPath(ev.account, e)))
        .toList();
    return files
        .where((f) =>
            file_util.isSupportedFormat(f) &&
            rootDirs.any((dir) => file_util.isUnderDir(f, dir)))
        .toList();
  }

  final DiContainer _c;

  static final _log = Logger("bloc.list_face_file.ListFaceFileBloc");
}
