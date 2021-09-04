import 'package:equatable/equatable.dart';
import 'package:exifdart/exifdart.dart';
import 'package:intl/intl.dart';
import 'package:nc_photos/type.dart';

class Exif with EquatableMixin {
  Exif(this.data);

  dynamic operator [](String key) => data[key];

  @override
  // ignore: hash_and_equals
  bool operator ==(Object? other) => equals(other, isDeep: true);

  /// Compare two Exif objects
  ///
  /// If [isDeep] is false, two Exif objects are considered identical if they
  /// contain the same number of fields. This hack is to save time comparing a
  /// large amount of data that are mostly immutable
  bool equals(Object? other, {bool isDeep = false}) {
    if (isDeep) {
      return super == other;
    } else {
      return identical(this, other) ||
          other is Exif && data.keys.length == other.data.keys.length;
    }
  }

  bool containsKey(String key) => data.containsKey(key);

  JsonObj toJson() {
    return Map.fromIterable(
      data.entries.where((e) => e.key != "MakerNote").map((e) {
        var jsonValue;
        if (e.value is Rational) {
          jsonValue = e.value.toJson();
        } else if (e.value is List) {
          jsonValue = e.value.map((e) {
            if (e is Rational) {
              return e.toJson();
            } else {
              return e;
            }
          }).toList();
        } else {
          jsonValue = e.value;
        }
        return MapEntry(e.key, jsonValue);
      }),
      key: (e) => e.key,
      value: (e) => e.value,
    );
  }

  factory Exif.fromJson(JsonObj json) {
    return Exif(Map.fromIterable(
      // we are filtering out MakerNote here because it's generally very large
      // and could exceed the 1MB cursor size limit on Android. Second, the
      // content is proprietary and thus useless to us anyway
      json.entries.where((e) => e.key != "MakerNote").map((e) {
        var exifValue;
        if (e.value is Map) {
          exifValue = Rational.fromJson(e.value.cast<String, dynamic>());
        } else if (e.value is List) {
          exifValue = e.value.map((e) {
            if (e is Map) {
              return Rational.fromJson(e.cast<String, dynamic>());
            } else {
              return e;
            }
          }).toList();
        } else {
          exifValue = e.value;
        }
        return MapEntry(e.key, exifValue);
      }),
      key: (e) => e.key,
      value: (e) => e.value,
    ));
  }

  @override
  toString() {
    final dataStr = data.entries.map((e) {
      return "${e.key}: '${e.value}'";
    }).join(", ");
    return "$runtimeType {$dataStr}";
  }

  /// 0x010f Make
  String? get make => data["Make"];

  /// 0x0110 Model
  String? get model => data["Model"];

  /// 0x9003 DateTimeOriginal
  DateTime? get dateTimeOriginal => data.containsKey("DateTimeOriginal") &&
          (data["DateTimeOriginal"] as String).isNotEmpty
      ? dateTimeFormat.parse(data["DateTimeOriginal"]).toUtc()
      : null;

  /// 0x829a ExposureTime
  Rational? get exposureTime => data["ExposureTime"];

  /// 0x829d FNumber
  Rational? get fNumber => data["FNumber"];

  /// 0x8827 ISO/ISOSpeedRatings/PhotographicSensitivity
  int? get isoSpeedRatings => data["ISOSpeedRatings"];

  /// 0x920a FocalLength
  Rational? get focalLength => data["FocalLength"];

  /// 0x8825 GPS tags
  String? get gpsLatitudeRef => data["GPSLatitudeRef"];
  List<Rational>? get gpsLatitude => data["GPSLatitude"].cast<Rational>();
  String? get gpsLongitudeRef => data["GPSLongitudeRef"];
  List<Rational>? get gpsLongitude => data["GPSLongitude"].cast<Rational>();

  @override
  get props => [
        data,
      ];

  final Map<String, dynamic> data;

  static final dateTimeFormat = DateFormat("yyyy:MM:dd HH:mm:ss");
}
