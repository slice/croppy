import Cocoa

internal extension NSView {
  /// Find the scroll view that we're contained in.
  ///
  /// This method assumes a particular hierarchy that involves a scroll view exactly three
  /// superviews up: the document view, clip view, and then finally the scroll
  /// view.
  func containedScrollView() -> NSScrollView? {
    self.superview?.superview?.superview as? NSScrollView
  }

  /// Determine the magnification level of a scroll view that we're inside of.
  ///
  /// This is so that we can adjust drawing to appear consistent regardless of
  /// zoom level by counteracting the magnification.
  func magnification() -> CGFloat {
    self.containedScrollView()?.magnification ?? CGFloat(1.0)
  }

  /// Scale a metric according to magnification in order to counteract the
  /// effects of zoom.
  func scaleMetricAccordingToMagnification(_ metric: CGFloat) -> CGFloat {
    CGFloat.maximum(metric, metric / self.magnification())
  }
}
