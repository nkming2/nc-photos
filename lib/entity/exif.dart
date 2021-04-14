import 'dart:convert';

import 'package:exifdart/exifdart.dart';
import 'package:intl/intl.dart';

class Exif {
  Exif(this.data);

  dynamic operator [](String key) => data[key];

  bool containsKey(String key) => data.containsKey(key);

  Map<String, dynamic> toJson() {
    return data.map((key, value) {
      var jsonValue;
      if (key == "MakerNote") {
        jsonValue = base64UrlEncode(value);
      } else if (value is Rational) {
        jsonValue = value.toJson();
      } else if (value is List) {
        jsonValue = value.map((e) {
          if (e is Rational) {
            return e.toJson();
          } else {
            return e;
          }
        }).toList();
      } else {
        jsonValue = value;
      }
      return MapEntry(key, jsonValue);
    });
  }

  factory Exif.fromJson(Map<String, dynamic> json) {
    return Exif(json.map((key, value) {
      var exifValue;
      if (key == "MakerNote") {
        exifValue = base64Decode(value);
      } else if (value is Map) {
        exifValue = Rational.fromJson(value.cast<String, dynamic>());
      } else if (value is List) {
        exifValue = value.map((e) {
          if (e is Map) {
            return Rational.fromJson(e.cast<String, dynamic>());
          } else {
            return e;
          }
        }).toList();
      } else {
        exifValue = value;
      }
      return MapEntry(key, exifValue);
    }));
  }

  @override
  toString() {
    final dataStr = data.entries.map((e) {
      if (e.key == "MakerNote") {
        return "${e.key}: '${base64UrlEncode(e.value)}'";
      } else {
        return "${e.key}: '${e.value}'";
      }
    }).join(", ");
    return "$runtimeType {$dataStr}";
  }

  /// 0x010f Make
  String get make => data["Make"];

  /// 0x0110 Model
  String get model => data["Model"];

  /// 0x9003 DateTimeOriginal
  DateTime get dateTimeOriginal => data.containsKey("DateTimeOriginal")
      ? dateTimeFormat.parse(data["DateTimeOriginal"])
      : null;

  /// 0x829a ExposureTime
  Rational get exposureTime => data["ExposureTime"];

  /// 0x829d FNumber
  Rational get fNumber => data["FNumber"];

  /// 0x8827 ISO/ISOSpeedRatings/PhotographicSensitivity
  int get isoSpeedRatings => data["ISOSpeedRatings"];

  /// 0x920a FocalLength
  Rational get focalLength => data["FocalLength"];

  /// 0x8825 GPS tags
  String get gpsLatitudeRef => data["GPSLatitudeRef"];
  List<Rational> get gpsLatitude => data["GPSLatitude"].cast<Rational>();
  String get gpsLongitudeRef => data["GPSLongitudeRef"];
  List<Rational> get gpsLongitude => data["GPSLongitude"].cast<Rational>();

  static final dateTimeFormat = DateFormat("yyyy:MM:dd HH:mm:ss");

  final Map<String, dynamic> data;
}
