/// To hold optional arguments that themselves could be null
class OrNull<T> {
  OrNull(this.obj);

  static bool isNull(OrNull x) => x != null && x.obj == null;

  final T obj;
}
