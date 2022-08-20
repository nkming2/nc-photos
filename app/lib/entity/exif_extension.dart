import 'package:exifdart/exifdart.dart';
import 'package:nc_photos/entity/exif.dart';

extension ExifExtension on Exif {
  double? get gpsLatitudeDeg {
    if (gpsLatitude == null || gpsLatitudeRef == null) {
      return null;
    } else if (gpsLatitudeRef != "N" && gpsLatitudeRef != "S") {
      // invalid value
      return null;
    } else if (gpsLatitude!.any((e) => e.denominator == 0)) {
      // invalid value
      return null;
    } else {
      return _gpsDmsToDouble(gpsLatitude!) * (gpsLatitudeRef == "S" ? -1 : 1);
    }
  }

  double? get gpsLongitudeDeg {
    if (gpsLongitude == null || gpsLongitudeRef == null) {
      return null;
    } else if (gpsLongitudeRef != "E" && gpsLongitudeRef != "W") {
      // invalid value
      return null;
    } else if (gpsLongitude!.any((e) => e.denominator == 0)) {
      // invalid value
      return null;
    } else {
      return _gpsDmsToDouble(gpsLongitude!) * (gpsLongitudeRef == "W" ? -1 : 1);
    }
  }
}

double _gpsDmsToDouble(List<Rational> dms) {
  double product = dms[0].toDouble();
  if (dms.length > 1) {
    product += dms[1].toDouble() / 60;
  }
  if (dms.length > 2) {
    product += dms[2].toDouble() / 3600;
  }
  return product;
}
