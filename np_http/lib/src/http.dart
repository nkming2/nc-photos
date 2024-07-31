import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
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
  } else if (getRawPlatform().isApple) {
    try {
      _urlConfig = URLSessionConfiguration.ephemeralSessionConfiguration()
        ..httpAdditionalHeaders = {"User-Agent": _userAgent};
    } catch (e, stackTrace) {
      _log.severe("Failed creating URLSessionConfiguration", e, stackTrace);
    }
  }
}

Client makeHttpClient() {
  if (getRawPlatform() == NpPlatform.android && _cronetEngine != null) {
    return CronetClient.fromCronetEngine(_cronetEngine!);
  } else if (getRawPlatform().isApple && _urlConfig != null) {
    return CupertinoClient.fromSessionConfiguration(_urlConfig!);
  } else {
    return makeHttpClientImpl(userAgent: _userAgent);
  }
}

late final String _userAgent;
CronetEngine? _cronetEngine;
URLSessionConfiguration? _urlConfig;

final _log = Logger("np_http");
