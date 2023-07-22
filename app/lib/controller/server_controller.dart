import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/entity_converter.dart';
import 'package:nc_photos/entity/server_status.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';
import 'package:rxdart/rxdart.dart';

part 'server_controller.g.dart';

enum ServerFeature {
  ncAlbum,
}

@npLog
class ServerController {
  ServerController({
    required this.account,
  });

  void dispose() {
    _statusStreamContorller.close();
  }

  ValueStream<ServerStatus> get status {
    if (!_statusStreamContorller.hasValue) {
      unawaited(_load());
    }
    return _statusStreamContorller.stream;
  }

  bool isSupported(ServerFeature feature) {
    switch (feature) {
      case ServerFeature.ncAlbum:
        return !_statusStreamContorller.hasValue ||
            _statusStreamContorller.value.majorVersion >= 25;
    }
  }

  Future<void> _load() => _getStatus();

  Future<void> _getStatus() async {
    try {
      final response = await ApiUtil.fromAccount(account).status().get();
      if (!response.isGood) {
        _log.severe("[_getStatus] Failed requesting server: $response");
        return;
      }
      final apiStatus = await api.StatusParser().parse(response.body);
      final status = ApiStatusConverter.fromApi(apiStatus);
      _log.info("[_getStatus] Server status: $status");
      _statusStreamContorller.add(status);
    } catch (e, stackTrace) {
      _log.severe("[_getStatus] Failed while get", e, stackTrace);
      return;
    }
  }

  final Account account;

  final _statusStreamContorller = BehaviorSubject<ServerStatus>();
}
