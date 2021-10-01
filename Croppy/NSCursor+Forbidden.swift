import Cocoa

enum ForbiddenCursor: String {
  case resizeNWSE = "_windowResizeNorthWestSouthEastCursor"
  case resizeNESW = "_windowResizeNorthEastSouthWestCursor"
}

extension NSCursor {
  // FREE THE CURSORS, APPLE.
  static func forbidden(_ selector: ForbiddenCursor) -> NSCursor {
    NSCursor.perform(Selector(selector.rawValue), with: nil).takeUnretainedValue() as! NSCursor
  }
}
