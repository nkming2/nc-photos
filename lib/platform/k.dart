import 'dart:io';

import 'package:flutter/foundation.dart';

const isWeb = kIsWeb;
// Platform n/a on web, need checking kIsWeb first
final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
final isAndroid = !kIsWeb && Platform.isAndroid;
