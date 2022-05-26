import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nc_photos/k.dart' as k;

enum UpdateCheckerResult {
  updateAvailable,
  alreadyLatest,
  error,
}

class UpdateChecker {
  const UpdateChecker();

  Future<UpdateCheckerResult> call() async {
    try {
      final uri = Uri.https("bit.ly", "3NyUYqv");
      final req = http.Request("GET", uri);
      final response =
          await http.Response.fromStream(await http.Client().send(req));
      if (response.statusCode != 200) {
        _log.severe("[call] Failed GETing URL: ${response.statusCode}");
        return UpdateCheckerResult.error;
      }
      final body = response.body;
      final json = jsonDecode(body) as Map;
      final latest = json[_buildVariant] as int;
      _log.info("[call] Latest: $latest Current: ${k.version}");
      if (latest > k.version) {
        return UpdateCheckerResult.updateAvailable;
      } else {
        return UpdateCheckerResult.alreadyLatest;
      }
    } catch (e, stackTrace) {
      _log.severe("[call] Exception", e, stackTrace);
      return UpdateCheckerResult.error;
    }
  }

  static const _buildVariant = "";

  static final _log = Logger("update_checker.UpdateChecker");
}
