import Cocoa

private enum Corner {
  case topRight
  case topLeft
  case bottomLeft
  case bottomRight
}

class CropTargetView: NSView {
  private var size: Double {
    get {
      self.target.width
    }

    set {
      self.target = NSRect(x: self.target.minX, y: self.target.minY, width: newValue, height: newValue)
      self.needsDisplay = true
    }
  }

  var target: NSRect {
    didSet {
      self.needsDisplay = true
    }
  }

  var onChangeTarget: ((NSRect) -> Void)?

  override init(frame: NSRect) {
    self.target = NSRect(x: 10, y: 10, width: 100, height: 100)
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    let shadow = NSBezierPath(rect: dirtyRect)
    shadow.append(NSBezierPath(ovalIn: self.target).reversed)
    NSColor.black.withAlphaComponent(0.5).setFill()
    shadow.fill()

    let path = NSBezierPath(rect: self.target)
    path.lineWidth = self.scaleMetricAccordingToMagnification(3.0)
    NSColor.systemRed.setStroke()
    path.stroke()

//    let innerCircle = NSBezierPath(ovalIn: self.target)
//    NSColor.controlAccentColor.withAlphaComponent(0.5).setFill()
//    innerCircle.fill()

    let verticalAlign = NSBezierPath()
    verticalAlign.move(to: NSPoint(x: self.target.midX, y: self.target.minY))
    verticalAlign.line(to: NSPoint(x: self.target.midX, y: self.target.maxY))
    verticalAlign.lineWidth = self.scaleMetricAccordingToMagnification(1.0)
    verticalAlign.stroke()

    let horizontalAlign = NSBezierPath()
    horizontalAlign.move(to: NSPoint(x: self.target.minX, y: self.target.midY))
    horizontalAlign.line(to: NSPoint(x: self.target.maxX, y: self.target.midY))
    horizontalAlign.lineWidth = self.scaleMetricAccordingToMagnification(1.0)
    horizontalAlign.stroke()
  }

  private var insideOfPanCircle = false
  private var insideOfCorner = false
  private var grabbedCorner: Corner!
  private var isPanning = false
  private var isResizing = false

  override func mouseDragged(with event: NSEvent) {
    // If we're in a scroll view, dampen (or strengthen) the position delta
    // according to the magnification.
    let magnification = self.magnification()
    let dx = event.deltaX / magnification
    let dy = -event.deltaY / magnification

    var pendingTarget: NSRect?

    if self.insideOfPanCircle {
      pendingTarget = self.target.offsetBy(dx: dx, dy: dy)
      if !self.isPanning {
        NSCursor.closedHand.push()
      }
      self.isPanning = true
    } else if self.insideOfCorner {
      var distance = hypot(dx, dy)
      let x = self.target.minX
      let y = self.target.minY
      let width = self.target.width
      let height = self.target.height

      if dx < 0 || dy < 0 { distance = -distance }
      if (self.grabbedCorner == .bottomRight && dy < 0)
        || (self.grabbedCorner == .topLeft && dx < 0)
        || self.grabbedCorner == .bottomLeft
      {
        distance = -distance
      }

      if distance < 0, self.size < 50 { return }

      if event.modifierFlags.contains(.option) {
        pendingTarget = self.target.insetBy(dx: -distance, dy: -distance)
      } else {
        var newX = x
        var newY = y

        // Offset the position so that the entire frame doesn't change position
        // as we resize from a corner.
        switch self.grabbedCorner! {
        case .topLeft:
          newX -= distance
        case .bottomLeft:
          newX -= distance
          newY -= distance
        case .bottomRight:
          newY -= distance
        default: break
        }

        pendingTarget = NSRect(x: newX, y: newY, width: width + distance, height: height + distance)
      }

      self.isResizing = true
    }

    guard let pendingTarget = pendingTarget else {
      return
    }

    self.target = pendingTarget
    self.onChangeTarget?(pendingTarget)
  }

  override func mouseUp(with _: NSEvent) {
    if self.isPanning {
      self.isPanning = false
      NSCursor.pop()
    }
  }

  override func mouseMoved(with event: NSEvent) {
    let convertedPoint = self.convert(event.locationInWindow, from: nil)
    let panCircle = NSBezierPath(ovalIn: self.target)
    let overPanCircle = panCircle.contains(convertedPoint)
    let corners = NSBezierPath(rect: self.target)
    corners.append(panCircle.reversed)
    let overCorners = corners.contains(convertedPoint)

    if self.insideOfCorner, !overCorners {
      NSCursor.pop()
      self.insideOfCorner = false
    }

    if overPanCircle, !self.insideOfPanCircle {
      NSCursor.openHand.push()
      self.insideOfPanCircle = true
    } else if self.insideOfPanCircle, !overPanCircle {
      NSCursor.pop()
      self.insideOfPanCircle = false
    }

    if overCorners, !self.insideOfCorner {
      if convertedPoint.x > self.target.midX {
        self.grabbedCorner = convertedPoint.y > self.target.midY
          ? .topRight
          : .bottomRight
      } else {
        self.grabbedCorner = convertedPoint.y > self.target.midY
          ? .topLeft
          : .bottomLeft
      }

      let nesw = self.grabbedCorner == .topRight || self.grabbedCorner == .bottomLeft
      NSCursor.forbidden(nesw ? .resizeNESW : .resizeNWSE).push()

      self.insideOfCorner = true
    } else if self.insideOfCorner, !overCorners {
      NSCursor.pop()
      self.insideOfCorner = false
    }
  }

  private var entireTrackingArea: NSTrackingArea?

  override func updateTrackingAreas() {
    if let trackingArea = self.entireTrackingArea {
      self.removeTrackingArea(trackingArea)
    }

    let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow]

    self.entireTrackingArea = NSTrackingArea(rect: self.frame, options: options, owner: self, userInfo: nil)
    self.addTrackingArea(self.entireTrackingArea!)
  }

  override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
    true
  }
}
