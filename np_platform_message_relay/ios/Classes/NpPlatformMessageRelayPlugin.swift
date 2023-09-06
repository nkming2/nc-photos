import Flutter
import UIKit

public class NpPlatformMessageRelayPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let handler = MessageRelayChannelHandler()
    let eventChannel = FlutterEventChannel(
      name: MessageRelayChannelHandler.eventChannel,
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(handler)
    let methodChannel = FlutterMethodChannel(
      name: MessageRelayChannelHandler.methodChannel,
      binaryMessenger: registrar.messenger()
    )
    methodChannel.setMethodCallHandler(handler.onMethodCall)
  }
}
