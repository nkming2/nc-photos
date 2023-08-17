import 'package:flutter/foundation.dart';
import 'package:np_log/np_log.dart' as np_log;

bool isHttpStatusGood(int status) => status ~/ 100 == 2;

void initLog() {
  np_log.initLog(
    isDebugMode: kDebugMode,
    print: (log) => debugPrint(log, wrapWidth: 1024),
  );
}
