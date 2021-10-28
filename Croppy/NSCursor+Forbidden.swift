import Cocoa

enum ForbiddenCursor: String {
  /// The "resize north-west, south-east" cursor.
  case resizeNWSE = "_windowResizeNorthWestSouthEastCursor"

  /// The "resize north-east, south-west" cursor.
  case resizeNESW = "_windowResizeNorthEastSouthWestCursor"
}

extension NSCursor {
  /// Returns a forbidden cursor.
  static func forbidden(_ selector: ForbiddenCursor) -> NSCursor {
    // FREE THE CURSORS, APPLE.
    NSCursor.perform(Selector(selector.rawValue), with: nil).takeUnretainedValue() as! NSCursor
  }
}
