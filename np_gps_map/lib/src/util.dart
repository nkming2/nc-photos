import 'package:np_gps_map/src/native.dart';
import 'package:np_platform_util/np_platform_util.dart';

void initGpsMap() {
  if (getRawPlatform() == NpPlatform.android) {
    Native.isNewGMapsRenderer().then((value) => _isNewGMapsRenderer = value);
  }
}

bool isNewGMapsRenderer() => _isNewGMapsRenderer;

var _isNewGMapsRenderer = false;
