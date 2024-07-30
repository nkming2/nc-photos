import 'package:cronet_http/cronet_http.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:np_platform_util/np_platform_util.dart';

import 'http_stub.dart'
    if (dart.library.js_interop) 'http_browser.dart'
    if (dart.library.io) 'http_io.dart';

Future<void> initHttp(String appVersion) async {
  _userAgent = "nc-photos $appVersion";
  if (getRawPlatform() == NpPlatform.android) {
    try {
      _cronetEngine = CronetEngine.build(
        enableHttp2: true,
        userAgent: _userAgent,
      );
    } catch (e, stackTrace) {
      _log.severe("Failed creating CronetEngine", e, stackTrace);
    }
  }
}

Client makeHttpClient() {
  if (getRawPlatform() == NpPlatform.android && _cronetEngine != null) {
    return CronetClient.fromCronetEngine(_cronetEngine!);
  } else {
    return makeHttpClientImpl(userAgent: _userAgent);
  }
}

late final String _userAgent;
CronetEngine? _cronetEngine;

final _log = Logger("np_http");
