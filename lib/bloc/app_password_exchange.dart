import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;

abstract class AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocEvent();
}

class AppPasswordExchangeBlocConnect extends AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocConnect(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

abstract class AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocState();
}

class AppPasswordExchangeBlocInit extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocInit();
}

class AppPasswordExchangeBlocSuccess extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocSuccess(this.password);

  @override
  toString() {
    return "$runtimeType {"
        "password: ${kDebugMode ? password : '***'}, "
        "}";
  }

  final String password;
}

class AppPasswordExchangeBlocFailure extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocFailure(this.exception);

  @override
  toString() {
    return "$runtimeType {"
        "exception: $exception, "
        "}";
  }

  final exception;
}

class AppPasswordExchangeBloc
    extends Bloc<AppPasswordExchangeBlocEvent, AppPasswordExchangeBlocState> {
  AppPasswordExchangeBloc() : super(AppPasswordExchangeBlocInit());

  @override
  mapEventToState(AppPasswordExchangeBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is AppPasswordExchangeBlocConnect) {
      yield* _exchangePassword(event.account);
    }
  }

  Stream<AppPasswordExchangeBlocState> _exchangePassword(
      Account account) async* {
    try {
      final appPwd = await api_util.exchangePassword(account);
      yield AppPasswordExchangeBlocSuccess(appPwd);
    } catch (e, stacktrace) {
      _log.severe("[_exchangePassword] Failed while exchanging password", e,
          stacktrace);
      yield AppPasswordExchangeBlocFailure(e);
    }
  }

  static final _log =
      Logger("bloc.app_password_exchange.AppPasswordExchangeBloc");
}
