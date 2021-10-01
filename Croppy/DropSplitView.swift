import Cocoa

class DropSplitView: NSSplitView {
  var onDrop: ((URL) -> Void)?

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    return .copy
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    guard let url = NSURL(from: sender.draggingPasteboard) else { return false }
    self.onDrop?(url as URL)
    return true
  }
}
