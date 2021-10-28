import Cocoa

internal extension NSView {
  /// Determine the magnification level of a scroll view that we're inside of.
  ///
  /// This is so that we can adjust drawing to appear consistent regardless of
  /// zoom level by counteracting the magnification.
  func magnification() -> CGFloat {
    // Assume a particular hierarchy that involves a scroll view exactly three
    // superviews up: the document view, clip view, and then finally the scroll
    // view.
    let scrollView = self.superview?.superview?.superview as? NSScrollView
    return scrollView?.magnification ?? CGFloat(1.0)
  }
}
