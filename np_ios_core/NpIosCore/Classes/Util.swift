import Foundation

public extension Optional {
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
