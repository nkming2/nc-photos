import Flutter
import Foundation
import NpIosCore

class LockChannelHandler {
  func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
    let args = call.arguments as? Dictionary<String, Any>
    do {
      switch call.method {
      case "tryLock":
        try tryLock(
          lockId: (args?["lockId"] as? Int).unwrap(),
          result: result
        )

      case "unlock":
        try unlock(
          lockId: (args?["lockId"] as? Int).unwrap(),
          result: result
        )

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as AppError {
      result(
        FlutterError(
          code: "systemException",
          message: error.message,
          details: "\(error.stackTrace)"
        )
      )
    } catch {
      result(
        FlutterError(
          code: "systemException",
          message: "\(error)",
          details: nil
        )
      )
    }
  }

  private func tryLock(lockId: Int, result: FlutterResult) {
    if LockChannelHandler.locks[lockId] != true {
      LockChannelHandler.locks[lockId] = true
      lockedIds += [lockId]
      result(true)
    } else {
      result(false)
    }
  }

  private func unlock(lockId: Int, result: FlutterResult) {
    if LockChannelHandler.locks[lockId] == true {
      LockChannelHandler.locks[lockId] = false
      lockedIds.removeAll(where: { $0 == lockId })
      result(nil)
    } else {
      result(
        FlutterError(
          code: "notLockedException",
          message: "Cannot unlock without first locking",
          details: nil
        )
      )
    }
  }

  private var lockedIds: [Int] = []

  static let methodChannel = "\(K.libId)/lock"
  private static var locks: [Int:Bool] = [:]
}
