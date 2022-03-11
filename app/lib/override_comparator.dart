/// Override operator== of T
class OverrideComparator<T> {
  OverrideComparator(this.obj, this.equalFn, this.hashCodeFn);

  @override
  operator ==(Object other) =>
      other is OverrideComparator<T> && equalFn(obj, other.obj);

  @override
  get hashCode => hashCodeFn(obj);

  final T obj;
  final bool Function(T, T) equalFn;
  final int Function(T) hashCodeFn;
}
