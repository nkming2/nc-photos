import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/exception.dart';

abstract class AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocEvent();
}

class AppPasswordExchangeBlocInitiateLogin
    extends AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocInitiateLogin(this.uri);

  @override
  toString() {
    return "$runtimeType {"
        "uri: $uri, "
        "}";
  }

  final Uri uri;
}

class AppPasswordExchangeBlocPoll extends AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocPoll(this.pollOptions);

  @override
  toString() {
    return "$runtimeType {"
        "pollOptions: $pollOptions, "
        "}";
  }

  final api_util.InitiateLoginPollOptions pollOptions;
}

class AppPasswordExchangeBlocCancel extends AppPasswordExchangeBlocEvent {
  const AppPasswordExchangeBlocCancel();

  @override
  String toString() => "AppPasswordExchangeBlocCancel {}";
}

class _AppPasswordExchangeBlocAppPwReceived
    extends AppPasswordExchangeBlocEvent {
  const _AppPasswordExchangeBlocAppPwReceived(this.appPasswordResponse);

  @override
  toString() {
    return "$runtimeType {"
        "appPasswordResponse: $appPasswordResponse, "
        "}";
  }

  final api_util.AppPasswordSuccess appPasswordResponse;
}

class _AppPasswordExchangeBlocAppPwFailed extends AppPasswordExchangeBlocEvent {
  const _AppPasswordExchangeBlocAppPwFailed(this.exception);

  @override
  toString() {
    return "$runtimeType {"
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

abstract class AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocState();
}

class AppPasswordExchangeBlocInit extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocInit();
}

class AppPasswordExchangeBlocInitiateLoginSuccess
    extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocInitiateLoginSuccess(this.result);

  @override
  toString() {
    return "$runtimeType {"
        "result: $result, "
        "}";
  }

  final api_util.InitiateLoginResponse result;
}

class AppPasswordExchangeBlocAppPwSuccess extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocAppPwSuccess(this.result);

  @override
  toString() {
    return "$runtimeType {"
        "result: $result, "
        "}";
  }

  final api_util.AppPasswordSuccess result;
}

class AppPasswordExchangeBlocFailure extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocFailure(this.exception);

  @override
  toString() {
    return "$runtimeType {"
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

class AppPasswordExchangeBlocResult extends AppPasswordExchangeBlocState {
  const AppPasswordExchangeBlocResult(this.result);

  @override
  String toString() => "AppPasswordExchangeBlocResult {"
      "result: $result, "
      "}";

  final Account? result;
}

/// Business Logic Component (BLoC) which handles the App password exchange.
///
/// The flow followed by this component is described in the Nextcloud documentation under
/// https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
///
/// ```
/// Event [AppPasswordExchangeBlocInitiateLogin]  -> State [AppPasswordExchangeBlocInitiateLoginSuccess]
///                                               -> State [AppPasswordExchangeBlocFailure]
/// Event [AppPasswordExchangeBlocPoll]           -> Event [AppPasswordExchangeBlocAppPwReceived]
///                                               -> Event [AppPasswordExchangeBlocAppPwFailed]
/// Event [AppPasswordExchangeBlocAppPwReceived]  -> State [AppPasswordExchangeBlocAppPwSuccess]
///                                               -> State [AppPasswordExchangeBlocFailure]
/// Event [AppPasswordExchangeBlocAppPwFailed]    -> State [AppPasswordExchangeBlocFailure]
/// ```
class AppPasswordExchangeBloc
    extends Bloc<AppPasswordExchangeBlocEvent, AppPasswordExchangeBlocState> {
  AppPasswordExchangeBloc() : super(const AppPasswordExchangeBlocInit()) {
    on<AppPasswordExchangeBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(AppPasswordExchangeBlocEvent event,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (_isCanceled) {
      _log.fine("[_onEvent] canceled = true, ignore event");
      return;
    }
    if (event is AppPasswordExchangeBlocInitiateLogin) {
      await _onEventInitiateLogin(event, emit);
    } else if (event is AppPasswordExchangeBlocPoll) {
      await _onEventPoll(event, emit);
    } else if (event is _AppPasswordExchangeBlocAppPwReceived) {
      await _onEventAppPasswordReceived(event, emit);
    } else if (event is _AppPasswordExchangeBlocAppPwFailed) {
      await _onEventAppPasswordFailure(event, emit);
    } else if (event is AppPasswordExchangeBlocCancel) {
      await _onEventCancel(event, emit);
    }
  }

  Future<void> _onEventInitiateLogin(AppPasswordExchangeBlocInitiateLogin ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    final uri = ev.uri;
    try {
      final initiateLoginResponse = await api_util.initiateLogin(uri);
      emit(AppPasswordExchangeBlocInitiateLoginSuccess(initiateLoginResponse));
    } on InvalidBaseUrlException catch (e) {
      _log.warning("[_onEventInitiateLogin] Invalid base url");
      emit(AppPasswordExchangeBlocFailure(e));
    } on HandshakeException catch (e) {
      _log.info("[_onEventInitiateLogin] Self-signed cert");
      emit(AppPasswordExchangeBlocFailure(e));
    } catch (e, stacktrace) {
      _log.shout("[_onEventInitiateLogin] Failed while exchanging password", e,
          stacktrace);
      emit(AppPasswordExchangeBlocFailure(e));
    }
  }

  Future<void> _onEventPoll(AppPasswordExchangeBlocPoll ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    final pollOptions = ev.pollOptions;
    try {
      await _pollPasswordSubscription?.cancel();
      _pollPasswordSubscription = api_util
          .pollAppPassword(pollOptions)
          .listen(_pollAppPasswordStreamListener);
    } catch (e, stacktrace) {
      await _pollPasswordSubscription?.cancel();
      _log.shout(
          "[_onEventPoll] Failed while polling for password", e, stacktrace);
      emit(AppPasswordExchangeBlocFailure(e));
    }
  }

  Future<void> _pollAppPasswordStreamListener(event) async {
    try {
      final appPasswordResponse = await event;
      if (appPasswordResponse is api_util.AppPasswordSuccess) {
        await _pollPasswordSubscription?.cancel();
        add(_AppPasswordExchangeBlocAppPwReceived(appPasswordResponse));
      }
    } catch (e, stacktrace) {
      _log.shout(
          "[_pollAppPasswordStreamListener] Failed while polling for password",
          e,
          stacktrace);
      add(_AppPasswordExchangeBlocAppPwFailed(e));
    }
  }

  Future<void> _onEventAppPasswordReceived(
      _AppPasswordExchangeBlocAppPwReceived ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    try {
      final response = ev.appPasswordResponse;
      final account = Account(
        Account.newId(),
        response.server.scheme,
        response.server.authority,
        response.loginName.toCi(),
        response.loginName,
        response.appPassword,
        [""],
      );
      emit(AppPasswordExchangeBlocResult(account));
    } catch (e, stacktrace) {
      _log.shout(
          "[_onEventAppPasswordReceived] Failed while exchanging password",
          e,
          stacktrace);
      emit(AppPasswordExchangeBlocFailure(e));
    }
  }

  Future<void> _onEventAppPasswordFailure(
      _AppPasswordExchangeBlocAppPwFailed ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    await _pollPasswordSubscription?.cancel();
    emit(AppPasswordExchangeBlocFailure(ev.exception));
  }

  Future<void> _onEventCancel(AppPasswordExchangeBlocCancel ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    await _pollPasswordSubscription?.cancel();
    _isCanceled = true;
    emit(const AppPasswordExchangeBlocResult(null));
  }

  @override
  Future<void> close() {
    _pollPasswordSubscription?.cancel();
    return super.close();
  }

  static final _log =
      Logger("bloc.app_password_exchange.AppPasswordExchangeBloc");

  StreamSubscription<Future<api_util.AppPasswordResponse>>?
      _pollPasswordSubscription;
  bool _isCanceled = false;
}
