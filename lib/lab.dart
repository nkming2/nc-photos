/// Experimental feature flags
class Lab {
  factory Lab() {
    if (_inst == null) {
      _inst = Lab._();
    }
    return _inst!;
  }

  bool get enableSharedAlbum => false;

  Lab._();

  static Lab? _inst;
}
