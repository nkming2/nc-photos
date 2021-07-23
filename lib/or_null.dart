/// To hold optional arguments that themselves could be null
class OrNull<T> {
  OrNull(this.obj);

  /// Return iff the value of [x] is set to null, which means if [x] itself is
  /// null, false will still be returned
  static bool isSetNull(OrNull? x) => x != null && x.obj == null;

  final T? obj;
}
