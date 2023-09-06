import Flutter
import Foundation
import NpIosCore

class MessageRelayChannelHandler: NSObject, FlutterStreamHandler {
  override init() {
    do {
      Self.idLock.lock()
      defer { Self.idLock.unlock() }
      id = Self.nextId
      Self.nextId += 1
    }
    super.init()
  }

  func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
    let args = call.arguments as? Dictionary<String, Any>
    do {
      switch call.method {
      case "broadcast":
        try broadcast(
          event: (args?["event"] as? String).unwrap(),
          data: args?["data"] as? String,
          result: result
        )

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as AppError {
      result(FlutterError(code: "systemException", message: error.message, details: "\(error.stackTrace)"))
    } catch {
      result(FlutterError(code: "systemException", message: "\(error)", details: nil))
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    Self.evLock.lock()
    defer { Self.evLock.unlock() }
    Self.eventSinks[id] = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    Self.evLock.lock()
    defer { Self.evLock.unlock() }
    Self.eventSinks.removeValue(forKey: id)
    return nil
  }

  private func broadcast(event: String, data: String?, result: FlutterResult) {
    Self.evLock.lock()
    defer { Self.evLock.unlock() }
    for s in Self.eventSinks.values {
      var map = ["event": event]
      if data != nil {
        map["data"] = data
      }
      s(data)
    }
    result(nil)
  }

  static let eventChannel = "\(K.libId)/message_relay_event"
  static let methodChannel = "\(K.libId)/message_relay_method"

  private static var eventSinks: [Int:FlutterEventSink] = [:]
  private static var evLock = NSRecursiveLock()
  private static var nextId = 0
  private static var idLock = NSRecursiveLock()

  private let id: Int
}
