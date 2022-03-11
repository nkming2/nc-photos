import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/face/data_source.dart';
import 'package:nc_photos/entity/person.dart';

abstract class ListFaceBlocEvent {
  const ListFaceBlocEvent();
}

class ListFaceBlocQuery extends ListFaceBlocEvent {
  const ListFaceBlocQuery(this.account, this.person);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "person: $person, "
        "}";
  }

  final Account account;
  final Person person;
}

abstract class ListFaceBlocState {
  const ListFaceBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<Face> items;
}

class ListFaceBlocInit extends ListFaceBlocState {
  ListFaceBlocInit() : super(null, const []);
}

class ListFaceBlocLoading extends ListFaceBlocState {
  const ListFaceBlocLoading(Account? account, List<Face> items)
      : super(account, items);
}

class ListFaceBlocSuccess extends ListFaceBlocState {
  const ListFaceBlocSuccess(Account? account, List<Face> items)
      : super(account, items);
}

class ListFaceBlocFailure extends ListFaceBlocState {
  const ListFaceBlocFailure(Account? account, List<Face> items, this.exception)
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

/// List all people recognized in an account
class ListFaceBloc extends Bloc<ListFaceBlocEvent, ListFaceBlocState> {
  ListFaceBloc() : super(ListFaceBlocInit());

  @override
  mapEventToState(ListFaceBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListFaceBlocQuery) {
      yield* _onEventQuery(event);
    }
  }

  Stream<ListFaceBlocState> _onEventQuery(ListFaceBlocQuery ev) async* {
    try {
      yield ListFaceBlocLoading(ev.account, state.items);
      yield ListFaceBlocSuccess(ev.account, await _query(ev));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListFaceBlocFailure(ev.account, state.items, e);
    }
  }

  Future<List<Face>> _query(ListFaceBlocQuery ev) {
    const personRepo = FaceRepo(FaceRemoteDataSource());
    return personRepo.list(ev.account, ev.person);
  }

  static final _log = Logger("bloc.list_personListFaceBloc");
}
