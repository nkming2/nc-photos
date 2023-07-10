extension MapEntryListExtension<T, U> on Iterable<MapEntry<T, U>> {
  Map<T, U> toMap() => Map.fromEntries(this);
}
