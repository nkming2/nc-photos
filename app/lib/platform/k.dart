import 'dart:io';

import 'package:flutter/foundation.dart';

const isWeb = kIsWeb;
// Platform n/a on web, need checking kIsWeb first
final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
final isAndroid = !kIsWeb && Platform.isAndroid;
final isDesktop =
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
final isUnitTest = !kIsWeb && Platform.environment.containsKey("FLUTTER_TEST");
