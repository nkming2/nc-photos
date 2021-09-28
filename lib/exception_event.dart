class ExceptionEvent {
  const ExceptionEvent(
    this.error, [
    this.stackTrace,
  ]);

  final dynamic error;
  final StackTrace? stackTrace;
}
