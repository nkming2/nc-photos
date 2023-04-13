import 'dart:convert';

import 'package:np_api/src/entity/entity.dart';
import 'package:np_common/type.dart';

class StatusParser {
  Future<Status> parse(String response) async {
    final json = (jsonDecode(response) as Map).cast<String, dynamic>();
    return _parse(json);
  }

  Status _parse(JsonObj json) {
    return Status(
      version: json["version"],
      versionString: json["versionstring"],
    );
  }
}
