class Lazy<T> {
  Lazy(this.build);

  T call() {
    if (build != null) {
      _value = build!();
      build = null;
    }
    return _value;
  }

  T get get => call();

  T Function()? build;
  late final T _value;
}
