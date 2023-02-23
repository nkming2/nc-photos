import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:np_api/src/entity/entity.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/log.dart';
import 'package:np_common/type.dart';

part 'face_parser.g.dart';

@npLog
class FaceParser {
  Future<List<Face>> parse(String response) =>
      compute(_parseFacesIsolate, response);

  List<Face> _parse(JsonObj json) {
    final jsons = json["ocs"]["data"].cast<JsonObj>();
    final products = <Face>[];
    for (final j in jsons) {
      try {
        products.add(_parseSingle(j));
      } catch (e) {
        _log.severe("[_parse] Failed parsing json: ${jsonEncode(j)}", e);
      }
    }
    return products;
  }

  Face _parseSingle(JsonObj json) {
    return Face(
      id: json["id"],
      fileId: json["fileId"],
    );
  }
}

List<Face> _parseFacesIsolate(String response) {
  initLog();
  final json = (jsonDecode(response) as Map).cast<String, dynamic>();
  return FaceParser()._parse(json);
}
