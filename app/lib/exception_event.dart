class ExceptionEvent {
  const ExceptionEvent(
    this.error, [
    this.stackTrace,
  ]);

  final Object error;
  final StackTrace? stackTrace;
}
