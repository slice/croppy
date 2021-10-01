import Cocoa
import UniformTypeIdentifiers

private extension NSImage {
  func cropping(to rect: NSRect) -> NSImage? {
    var proposedRect = CGRect(origin: .zero, size: size)
    guard let imageRef = cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
      return nil
    }

    let flippedRect = CGRect(
      origin: CGPoint(
        x: rect.minX,
        y: size.height - (rect.height + rect.minY)
      ),
      size: rect.size
    )

    guard let crop = imageRef.cropping(to: flippedRect) else {
      return nil
    }
    return NSImage(cgImage: crop, size: rect.size)
  }
}

class CroppedImageView: NSView, NSDraggingSource {
  var rounded: Bool = false {
    didSet {
      needsDisplay = true
    }
  }

  var image: NSImage? {
    didSet {
      needsDisplay = true
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
      NSBezierPath(ovalIn: bounds).reversed.setClip()
    }
    NSColor.red.setFill()
    dirtyRect.fill()
    image.draw(in: dirtyRect, from: crop, operation: .copy, fraction: 1.0)
  }

  var mouseDownEvent: NSEvent?

  func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
    .copy
  }

  override func mouseDown(with event: NSEvent) {
    self.mouseDownEvent = event
  }

  override func mouseDragged(with event: NSEvent) {
    let mouseDownPosition = self.mouseDownEvent!.locationInWindow
    let dragPoint = event.locationInWindow
    let dragDistance = hypot(mouseDownPosition.x - dragPoint.x, mouseDownPosition.y - dragPoint.y)

    if dragDistance < 20 {
      return
    }

    guard let crop = self.crop, let croppedImage = self.image?.cropping(to: crop) else { return }

    let promise = NSFilePromiseProvider(fileType: UTType.png.identifier, delegate: self)

    let draggingItem = NSDraggingItem(pasteboardWriter: promise)
    draggingItem.draggingFrame = NSRect(origin: .zero, size: self.bounds.size)
    draggingItem.imageComponentsProvider = {
      let component = NSDraggingImageComponent(key: .icon)
      component.contents = croppedImage
      component.frame = NSRect(origin: .zero, size: self.bounds.size)
      return [component]
    }

    self.beginDraggingSession(with: [draggingItem], event: event, source: self)
  }
}

private enum CroppedImagePromiseError: Error {
  case failedToRepresent
}

extension CroppedImageView: NSFilePromiseProviderDelegate {
  func filePromiseProvider(_: NSFilePromiseProvider, fileNameForType _: String) -> String {
    "cropped.png"
  }

  func filePromiseProvider(_: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
    do {
      guard let image = self.image,
            let crop = self.crop,
            let croppedImage = image.cropping(to: crop),
            let tiffRepresentation = croppedImage.tiffRepresentation,
            let imageRepresentation = NSBitmapImageRep(data: tiffRepresentation)?.representation(using: .png, properties: [:])
      else {
        completionHandler(CroppedImagePromiseError.failedToRepresent)
        return
      }

      do {
        try imageRepresentation.write(to: url)
        completionHandler(nil)
      } catch {
        completionHandler(error)
      }
    }
  }
}
