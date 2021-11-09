import Cocoa

extension NSImage {
  /// Crops an image, preserving its true colors.
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

final class CropPreviewsController: NSViewController {
  private lazy var previews: [CroppedImageView] = {
    [self.circlePreviewView, self.smallCirclePreviewView, self.squarePreviewView, self.smallSquarePreviewView]
  }()

  var image: NSImage? {
    didSet {
      self.updatePreviews()
    }
  }

  var cropTarget: NSRect? {
    didSet {
      self.updatePreviews()
    }
  }

  private func updatePreviews() {
    guard let image = self.image, let crop = self.cropTarget else { return }

    let croppedImage = image.cropping(to: crop)

    let thumbnailRect = NSRect(origin: .zero, size: CGSize(width: 100.0, height: 100.0))
    let thumbnailImage = NSImage(size: thumbnailRect.size)
    thumbnailImage.lockFocus()
    NSColor.red.setFill()
    thumbnailRect.fill()
    image.draw(in: thumbnailRect, from: crop, operation: .copy, fraction: 1.0)
    thumbnailImage.unlockFocus()

    for preview in self.previews {
      preview.thumbnailImage = thumbnailImage
      preview.image = croppedImage
    }
  }

  private static func makePreview(rounded: Bool) -> CroppedImageView {
    let view = CroppedImageView()
    view.rounded = rounded
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }

  lazy var circlePreviewView = Self.makePreview(rounded: true)
  lazy var smallCirclePreviewView = Self.makePreview(rounded: true)
  lazy var squarePreviewView = Self.makePreview(rounded: false)
  lazy var smallSquarePreviewView = Self.makePreview(rounded: false)

  lazy var stackView: NSStackView = {
    let view = NSStackView(views: self.previews)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.orientation = .vertical
    view.alignment = .left
    view.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    view.setHuggingPriority(.defaultLow, for: .horizontal)
    return view
  }()

  override func loadView() {
    self.view = self.stackView
  }

  override func updateViewConstraints() {
    super.updateViewConstraints()

    NSLayoutConstraint.activate([
      self.circlePreviewView.widthAnchor.constraint(equalToConstant: 100),
      self.circlePreviewView.heightAnchor.constraint(equalToConstant: 100),
      self.smallCirclePreviewView.widthAnchor.constraint(equalToConstant: 50),
      self.smallCirclePreviewView.heightAnchor.constraint(equalToConstant: 50),
      self.squarePreviewView.widthAnchor.constraint(equalToConstant: 100),
      self.squarePreviewView.heightAnchor.constraint(equalToConstant: 100),
      self.smallSquarePreviewView.widthAnchor.constraint(equalToConstant: 50),
      self.smallSquarePreviewView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }
}
