import Cocoa

class CroppedImageView: NSView {
  var rounded: Bool = false {
    didSet {
      self.needsDisplay = true
    }
  }

  var image: NSImage? {
    didSet {
      self.needsDisplay = true
    }
  }

  var crop: NSRect? {
    didSet {
      self.needsDisplay = true
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let image = self.image, let crop = self.crop else { return }
    if self.rounded {
      NSBezierPath(ovalIn: self.bounds).reversed.setClip()
    }
    NSColor.red.setFill()
    dirtyRect.fill()
    image.draw(in: dirtyRect, from: crop, operation: .copy, fraction: 1.0)
  }
}
