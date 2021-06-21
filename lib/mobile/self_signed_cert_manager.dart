import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:nc_photos/mobile/android/self_signed_cert.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class SelfSignedCertManager {
  factory SelfSignedCertManager() => _inst;

  SelfSignedCertManager._() {
    _readAllCerts().then((infos) {
      _whitelist = infos;
    });
  }

  void init() {
    HttpOverrides.global = _CustomHttpOverrides();
  }

  /// Verify [cert] and return if it's registered in the whitelist for [host]
  bool verify(X509Certificate cert, String host, int port) {
    final fingerprint = _sha1BytesToString(cert.sha1);
    return _whitelist.any((info) =>
        fingerprint == info.sha1 &&
        host.toLowerCase() == info.host.toLowerCase());
  }

  String getLastBadCertHost() => _latestBadCert.host;

  String getLastBadCertFingerprint() =>
      _sha1BytesToString(_latestBadCert.cert.sha1);

  /// Whitelist the last bad cert
  Future<void> whitelistLastBadCert() async {
    final info = await _writeCert(_latestBadCert.host, _latestBadCert.cert);
    _whitelist.add(info);
    return SelfSignedCert.reload();
  }

  /// Clear all whitelisted certs and they will no longer be allowed afterwards
  Future<void> clearWhitelist() async {
    final certDir = await _openCertsDir();
    await certDir.delete(recursive: true);
    _whitelist.clear();
    return SelfSignedCert.reload();
  }

  /// Read and return all persisted certificate infos
  Future<List<_CertInfo>> _readAllCerts() async {
    final products = <_CertInfo>[];
    final certDir = await _openCertsDir();
    final certFiles = (await certDir.list().toList()).whereType<File>();
    for (final f in certFiles) {
      if (!f.path.endsWith(".json")) {
        continue;
      }
      try {
        final info = _CertInfo.fromJson(jsonDecode(await f.readAsString()));
        _log.info(
            "[_readAllCerts] Found certificate info: ${path.basename(f.path)} for host: ${info.host}");
        products.add(info);
      } catch (e, stacktrace) {
        _log.severe(
            "[_readAllCerts] Failed to read certificate file: ${path.basename(f.path)}",
            e,
            stacktrace);
      }
    }
    return products;
  }

  /// Persist a new cert and return the info object
  Future<_CertInfo> _writeCert(String host, X509Certificate cert) async {
    final certDir = await _openCertsDir();
    while (true) {
      final fileName = Uuid().v4();
      final certF = File("${certDir.path}/$fileName");
      if (await certF.exists()) {
        continue;
      }
      await certF.writeAsString(cert.pem, flush: true);

      final siteF = File("${certDir.path}/$fileName.json");
      final certInfo = _CertInfo.fromX509Certificate(host, cert);
      await siteF.writeAsString(jsonEncode(certInfo.toJson()), flush: true);
      _log.info(
          "[_persistBadCert] Persisted cert at '${certF.path}' for host '${_latestBadCert.host}'");
      return certInfo;
    }
  }

  Future<Directory> _openCertsDir() async {
    final privateDir = await getApplicationSupportDirectory();
    final certDir = Directory("${privateDir.path}/certs");
    if (!await certDir.exists()) {
      return certDir.create();
    } else {
      return certDir;
    }
  }

  _BadCertInfo _latestBadCert;
  var _whitelist = <_CertInfo>[];

  static SelfSignedCertManager _inst = SelfSignedCertManager._();

  static final _log =
      Logger("mobile.self_signed_cert_manager.SelfSignedCertManager");
}

// Modifications to this class must also reflect on Android side
class _CertInfo {
  _CertInfo(this.host, this.sha1, this.subject, this.issuer, this.startValidity,
      this.endValidity);

  factory _CertInfo.fromX509Certificate(String host, X509Certificate cert) {
    return _CertInfo(
      host,
      _sha1BytesToString(cert.sha1),
      cert.subject,
      cert.issuer,
      cert.startValidity,
      cert.endValidity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "host": host,
      "sha1": sha1,
      "subject": subject,
      "issuer": issuer,
      "startValidity": startValidity.toUtc().toIso8601String(),
      "endValidity": endValidity.toUtc().toIso8601String(),
    };
  }

  factory _CertInfo.fromJson(Map<String, dynamic> json) {
    return _CertInfo(
      json["host"],
      json["sha1"],
      json["subject"],
      json["issuer"],
      DateTime.parse(json["startValidity"]),
      DateTime.parse(json["endValidity"]),
    );
  }

  final String host;
  final String sha1;
  final String subject;
  final String issuer;
  final DateTime startValidity;
  final DateTime endValidity;
}

class _BadCertInfo {
  _BadCertInfo(this.cert, this.host, this.port);

  final X509Certificate cert;
  final String host;
  final int port;
}

class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        try {
          if (SelfSignedCertManager().verify(cert, host, port)) {
            // _log.warning(
            //     "[badCertificateCallback] Allowing whitelisted self-signed cert");
            return true;
          }
        } catch (e, stacktrace) {
          _log.shout("[badCertificateCallback] Failed while verifying cert", e,
              stacktrace);
        }
        SelfSignedCertManager()._latestBadCert = _BadCertInfo(cert, host, port);
        return false;
      };
  }

  static final _log =
      Logger("mobile.self_signed_cert_manager._CustomHttpOverrides");
}

String _sha1BytesToString(Uint8List bytes) =>
    bytes.map((e) => e.toRadixString(16).padLeft(2, "0")).join();
