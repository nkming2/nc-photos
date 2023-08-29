import Foundation

class AppError: Error {
  init(_ message: String? = nil, stackTrace: [String] = Thread.callStackSymbols) {
    self.message_ = message
    self.stackTrace = stackTrace.joined(separator: "\n")
  }

  var description: String {
    return "\(message_ ?? "") (throw: \(String(describing: self))\nStack trace:\n\(stackTrace)"
  }

  var message: String {
    return message_ == nil ? String(describing: self) : message_!
  }

  let stackTrace: String
  private let message_: String?
}

class NilError: AppError {
}

extension Optional {
  func unwrap(
    _ errorBuilder: (() -> Error)? = nil,
    file: String = #fileID,
    line: Int = #line
  ) throws -> Wrapped {
    guard let value = self else {
      throw errorBuilder?() ?? NilError("\(type(of: self)) is nil in \(file):\(line)")
    }
    return value
  }
}
