import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/exception.dart';

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

  final dynamic exception;
}

class AppPasswordExchangeBloc
    extends Bloc<AppPasswordExchangeBlocEvent, AppPasswordExchangeBlocState> {
  AppPasswordExchangeBloc() : super(const AppPasswordExchangeBlocInit()) {
    on<AppPasswordExchangeBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(AppPasswordExchangeBlocEvent event,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is AppPasswordExchangeBlocConnect) {
      await _onEventConnect(event, emit);
    }
  }

  Future<void> _onEventConnect(AppPasswordExchangeBlocConnect ev,
      Emitter<AppPasswordExchangeBlocState> emit) async {
    final account = ev.account;
    try {
      final appPwd = await api_util.exchangePassword(account);
      emit(AppPasswordExchangeBlocSuccess(appPwd));
    } on InvalidBaseUrlException catch (e) {
      _log.warning("[_exchangePassword] Invalid base url");
      emit(AppPasswordExchangeBlocFailure(e));
    } on HandshakeException catch (e) {
      _log.info("[_exchangePassword] Self-signed cert");
      emit(AppPasswordExchangeBlocFailure(e));
    } catch (e, stacktrace) {
      if (e is ApiException && e.response.statusCode == 401) {
        // wrong password, normal
        _log.warning(
            "[_exchangePassword] Server response 401, wrong password?");
      } else {
        _log.shout("[_exchangePassword] Failed while exchanging password", e,
            stacktrace);
      }
      emit(AppPasswordExchangeBlocFailure(e));
    }
  }

  static final _log =
      Logger("bloc.app_password_exchange.AppPasswordExchangeBloc");
}
