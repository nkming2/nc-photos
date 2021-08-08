import 'package:nc_photos/pref.dart';

/// Experimental feature flags
class Lab {
  factory Lab() {
    if (_inst == null) {
      _inst = Lab._();
    }
    return _inst!;
  }

  bool get enableSharedAlbum => Pref.inst().isLabEnableSharedAlbumOr(false);

  Lab._();

  static Lab? _inst;
}
