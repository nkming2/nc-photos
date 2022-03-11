import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:screen_brightness/screen_brightness.dart';

mixin ViewerControllersMixin<T extends StatefulWidget>
    on DisposableManagerMixin<T> {
  @override
  initDisposables() {
    return [
      ...super.initDisposables(),
      if (platform_k.isMobile) _ViewerBrightnessController(),
      _ViewerSystemUiResetter(),
      if (platform_k.isMobile && Pref().isViewerForceRotationOr(false))
        _ViewerOrientationController(
          onChanged: _onOrientationChanged,
        ),
    ];
  }

  void _onOrientationChanged(NativeDeviceOrientation orientation) {
    _log.info("[_onOrientationChanged] $orientation");
    if (!mounted) {
      return;
    }
    final List<DeviceOrientation> prefer;
    switch (orientation) {
      case NativeDeviceOrientation.portraitDown:
        prefer = [DeviceOrientation.portraitDown];
        break;
      case NativeDeviceOrientation.landscapeLeft:
        prefer = [DeviceOrientation.landscapeLeft];
        break;

      case NativeDeviceOrientation.landscapeRight:
        prefer = [DeviceOrientation.landscapeRight];
        break;

      case NativeDeviceOrientation.portraitUp:
      default:
        prefer = [DeviceOrientation.portraitUp];
        break;
    }
    SystemChrome.setPreferredOrientations(prefer);
  }

  static final _log = Logger("widget.viewer_mixin.ViewerControllersMixin");
}

/// Control the screen brightness according to the settings
class _ViewerBrightnessController implements Disposable {
  @override
  init(State state) {
    final brightness = Pref().getViewerScreenBrightness();
    if (brightness != null && brightness >= 0) {
      ScreenBrightness().setScreenBrightness(brightness / 100.0);
    }
  }

  @override
  dispose(State state) {
    ScreenBrightness().resetScreenBrightness();
  }
}

/// Make sure the system UI overlay is reset on dispose
class _ViewerSystemUiResetter implements Disposable {
  @override
  init(State state) {}

  @override
  dispose(State state) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }
}

class _ViewerOrientationController implements Disposable {
  _ViewerOrientationController({
    this.onChanged,
  });

  @override
  init(State state) {
    _subscription = NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((orientation) {
      _triggerThrottler.trigger(
        data: orientation,
        maxResponceTime: const Duration(seconds: 1),
      );
    });
  }

  @override
  dispose(State state) {
    _subscription.cancel();
    SystemChrome.setPreferredOrientations([]);
  }

  void _onTriggered(List<NativeDeviceOrientation> values) {
    onChanged?.call(values.last);
  }

  ValueChanged<NativeDeviceOrientation>? onChanged;
  late final StreamSubscription<NativeDeviceOrientation> _subscription;

  late final _triggerThrottler = Throttler<NativeDeviceOrientation>(
    onTriggered: _onTriggered,
    logTag: "_ViewerOrientationController.trigger",
  );
}
