extension FutureNotNullExtension<T> on Future<T?> {
  Future<T> notNull() async => (await this)!;
}
