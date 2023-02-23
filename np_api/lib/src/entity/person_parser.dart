import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:np_api/src/entity/entity.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/log.dart';
import 'package:np_common/type.dart';

part 'person_parser.g.dart';

@npLog
class PersonParser {
  Future<List<Person>> parse(String response) =>
      compute(_parsePersonsIsolate, response);

  List<Person> _parse(JsonObj json) {
    final jsons = json["ocs"]["data"].cast<JsonObj>();
    final products = <Person>[];
    for (final j in jsons) {
      try {
        products.add(_parseSingle(j));
      } catch (e) {
        _log.severe("[_parse] Failed parsing json: ${jsonEncode(j)}", e);
      }
    }
    return products;
  }

  Person _parseSingle(JsonObj json) {
    return Person(
      name: json["name"],
      thumbFaceId: json["thumbFaceId"],
      count: json["count"],
    );
  }
}

List<Person> _parsePersonsIsolate(String response) {
  initLog();
  final json = (jsonDecode(response) as Map).cast<String, dynamic>();
  return PersonParser()._parse(json);
}
