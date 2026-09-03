import 'dart:async';

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:np_platform_util/np_platform_util.dart';

import 'http_stub.dart'
    if (dart.library.js_interop) 'http_browser.dart'
    if (dart.library.io) 'http_io.dart';

String getAppUserAgent() => _userAgent;

Future<void> initHttp({
  required String appVersion,
  required bool isNewHttpEngine,
}) async {
  _userAgent = "nc-photos $appVersion";
  if (getRawPlatform() == NpPlatform.android) {
    try {
      final cronetEngine = CronetEngine.build(
        enableHttp2: true,
        enableQuic: true,
        enableBrotli: true,
        userAgent: _userAgent,
      );
      _newClient = CronetClient.fromCronetEngine(
        cronetEngine,
        closeEngine: true,
      );
      _log.info("Init cronet backend");
    } catch (e, stackTrace) {
      _log.severe("Failed creating CronetEngine", e, stackTrace);
    }
  } else if (getRawPlatform().isApple) {
    try {
      final urlConfig = URLSessionConfiguration.ephemeralSessionConfiguration()
        ..httpAdditionalHeaders = {"User-Agent": _userAgent};
      _newClient = CupertinoClient.fromSessionConfiguration(urlConfig);
      _log.info("Init cupertino backend");
    } catch (e, stackTrace) {
      _log.severe("Failed creating URLSessionConfiguration", e, stackTrace);
    }
  }
  _dartClient = makeHttpClientImpl(userAgent: _userAgent);
  _log.info("Init dart backend");
}

Future<StreamedResponse> sendHttpRequest(
  FutureOr<BaseRequest> Function() requestBuilder,
) async {
  var request = await requestBuilder();
  final domain = request.url.authority;
  try {
    return await _getHttpClientForDomain(domain).send(request);
  } on NetworkException catch (e) {
    final code = e.cronetInternalErrorCode.abs();
    // 200-299 Certificate errors
    // see https://chromium.googlesource.com/chromium/src/+/main/net/base/net_error_list.h
    if (code >= 200 && code < 300) {
      _log.warning(
        "Cronet certificate error(${e.cronetInternalErrorCode}), falling back to dart backend: $domain",
      );
    } else {
      rethrow;
    }
  }
  _useFallbackClientForDomain(domain);
  request = await requestBuilder();
  return _dartClient.send(request);
}

Client _getHttpClientForDomain(String domain) =>
    _domainClientMap.putIfAbsent(domain, () => _newClient ?? _dartClient);

Client _useFallbackClientForDomain(String domain) =>
    _domainClientMap[domain] = _dartClient;

Client? _newClient;
late final Client _dartClient;
final _domainClientMap = <String, Client>{};
late String _userAgent;

final _log = Logger("np_http");
