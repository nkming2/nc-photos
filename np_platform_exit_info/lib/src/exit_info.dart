import 'package:np_platform_exit_info/src/messages.g.dart' as api;
import 'package:to_string/to_string.dart';

part 'exit_info.g.dart';

interface class ExitInfo {
  static Future<ExitInfoResult?> getExifInfo() async {
    final result = await api.MyHostApi().getExifInfo();
    return result?.toDartType();
  }
}

@toString
class ExitInfoResult {
  const ExitInfoResult({
    required this.description,
    required this.pss,
    required this.reason,
    required this.rss,
    required this.status,
    required this.time,
  });

  @override
  String toString() => _$toString();

  /// The human readable description of the process's death, given by the system;
  /// could be null.
  final String? description;

  /// Last proportional set size of the memory that the process had used in B.
  final int pss;

  /// The reason code of the process's death.
  final ExitInfoReason reason;

  /// Last resident set size of the memory that the process had used in B.
  final int rss;

  /// The exit status argument of exit() if the application calls it, or the
  /// signal number if the application is signaled.
  final int status;

  /// The time of the process's death.
  final DateTime time;
}

// see https://developer.android.com/reference/android/app/ApplicationExitInfo
enum ExitInfoReason {
  unknown(0),
  exitSelf(1),
  signaled(2),
  lowMemory(3),
  crash(4),
  crashNative(5),
  anr(6),
  initializationFailure(7),
  permissionChange(8),
  excessiveResourceUsage(9),
  userRequested(10),
  userStopped(11),
  dependencyDied(12),
  other(13),
  freezer(14),
  packageStateChange(15),
  packageUpdated(16),
  memoryLimiter(17),
  anomaly(18);

  const ExitInfoReason(this.value);

  static ExitInfoReason fromValue(int value) => ExitInfoReason.values[value];

  final int value;
}

extension on api.ExitInfo {
  ExitInfoResult toDartType() => ExitInfoResult(
    description: description,
    // kB to B
    pss: pss * 1000,
    reason: ExitInfoReason.fromValue(reason),
    // kB to B
    rss: rss * 1000,
    status: status,
    time: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
  );
}
