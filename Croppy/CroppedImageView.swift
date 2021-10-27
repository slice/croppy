import Cocoa
import UniformTypeIdentifiers

class CroppedImageView: NSView, NSDraggingSource {
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

  var thumbnailImage: NSImage? {
    didSet {
      self.needsDisplay = true
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    guard let thumbnailImage = self.thumbnailImage else { return }
    if self.rounded {
      NSBezierPath(ovalIn: bounds).reversed.setClip()
    }
    thumbnailImage.draw(in: self.bounds, from: .zero, operation: .copy, fraction: 1.0)
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

    let promise = NSFilePromiseProvider(fileType: UTType.png.identifier, delegate: self)

    let draggingItem = NSDraggingItem(pasteboardWriter: promise)
    draggingItem.draggingFrame = NSRect(origin: .zero, size: self.bounds.size)
    draggingItem.imageComponentsProvider = {
      let component = NSDraggingImageComponent(key: .icon)
      component.contents = self.image
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
            let tiffRepresentation = image.tiffRepresentation,
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
