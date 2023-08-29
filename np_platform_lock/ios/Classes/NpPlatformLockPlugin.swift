import Flutter
import UIKit

public class NpPlatformLockPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let lockHandler = LockChannelHandler()
    let lockChannel = FlutterMethodChannel(
      name: LockChannelHandler.methodChannel,
      binaryMessenger: registrar.messenger()
    )
    lockChannel.setMethodCallHandler(lockHandler.onMethodCall)
  }
}
