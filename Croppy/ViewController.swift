import Cocoa

final class CenteringClipView: NSClipView {
  override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
    var constrainedClipViewBounds = super.constrainBoundsRect(proposedBounds)

    guard let documentView = self.documentView else {
      return constrainedClipViewBounds
    }

    let documentViewFrame = documentView.frame

    if documentViewFrame.width < proposedBounds.width {
      constrainedClipViewBounds.origin.x = floor((proposedBounds.width - documentViewFrame.width) / -2.0)
    }

    if documentViewFrame.height < proposedBounds.height {
      constrainedClipViewBounds.origin.y = floor((proposedBounds.height - documentViewFrame.height) / -2.0)
    }

    return constrainedClipViewBounds
  }
}

final class SizableImageView: NSImageView {
  var overriddenContentSize: NSSize?

  override var intrinsicContentSize: NSSize {
    if let overriddenContentSize = self.overriddenContentSize {
      return overriddenContentSize
    } else {
      return super.intrinsicContentSize
    }
  }
}

final class ViewController: NSViewController {
  private var cropPreviewsController = CropPreviewsController()

  lazy var imageView: SizableImageView = {
    let image = NSImage(named: "proudscrooge")!
    let imageView = SizableImageView(image: image)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return imageView
  }()

  private var image: NSImage?
  private var liveResizeImage: NSImage?

  lazy var cropTargetView: CropTargetView = {
    let view = CropTargetView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var documentView: NSView = {
    let view = NSView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.subviews = [self.imageView, self.cropTargetView]
    return view
  }()

  lazy var clipView: NSClipView = {
    let clipView = CenteringClipView()
    clipView.translatesAutoresizingMaskIntoConstraints = false
    clipView.documentView = self.documentView
    return clipView
  }()

  private var willStartLiveMagnifyObserver: NSObjectProtocol?
  private var didEndLiveMagnifyObserver: NSObjectProtocol?

  lazy var scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.allowsMagnification = true
    scrollView.minMagnification = 0.1
    scrollView.maxMagnification = 10
    scrollView.contentView = self.clipView
    scrollView.postsFrameChangedNotifications = true
    self.willStartLiveMagnifyObserver = NotificationCenter.default.addObserver(forName: NSScrollView.willStartLiveMagnifyNotification, object: scrollView, queue: nil) { _ in
      self.imageView.image = self.liveResizeImage
    }
    self.didEndLiveMagnifyObserver = NotificationCenter.default.addObserver(forName: NSScrollView.didEndLiveMagnifyNotification, object: scrollView, queue: nil) { _ in
      self.imageView.image = self.image
    }
    return scrollView
  }()

  lazy var splitView: DropSplitView = {
    let splitView = DropSplitView()
    splitView.isVertical = true
    splitView.dividerStyle = .thin
    splitView.addArrangedSubview(self.scrollView)
    splitView.addArrangedSubview(self.cropPreviewsController.view)
    splitView.frame = NSRect(x: 0, y: 0, width: 500, height: 200)
    splitView.registerForDraggedTypes(self.imageView.registeredDraggedTypes)
    return splitView
  }()

  private func updateImages(image: NSImage) {
    NSLog("*** image size: \(image.size)")
    self.image = image
    self.liveResizeImage = self.makeLiveResizeImage(from: image)
    NSLog("    live resize image size: \(self.liveResizeImage!.size)")
    self.imageView.overriddenContentSize = image.size
    self.imageView.image = image
    self.cropPreviewsController.image = image
    self.cropPreviewsController.cropTarget = self.cropTargetView.target
  }

  private func makeLiveResizeImage(from original: NSImage) -> NSImage {
    let actualSize = original.size
    let largestDimension = max(actualSize.width, actualSize.height)
    let downscaleFactor = max(1.0, floor(largestDimension / 500.0))
    let lowQualitySize = NSSize(width: actualSize.width / downscaleFactor, height: actualSize.height / downscaleFactor)
    NSLog("    downscale factor: \(downscaleFactor)")

    let lowQualityImage = NSImage(size: lowQualitySize)
    lowQualityImage.lockFocus()
    NSGraphicsContext.current!.imageInterpolation = .medium
    original.draw(
      in: NSRect(origin: .zero, size: lowQualitySize),
      from: NSRect(origin: .zero, size: actualSize),
      operation: .copy,
      fraction: 1.0
    )
    lowQualityImage.unlockFocus()

    return lowQualityImage
  }

  override func loadView() {
    self.view = self.splitView

    self.updateImages(image: self.imageView.image!)
    self.splitView.onDrop = { [weak self] url in
      let image = NSImage(byReferencing: url)
      self?.cropTargetView.target = CGRect(x: 10, y: 10, width: 100, height: 100)
      self?.updateImages(image: image)
    }

    // Let the split view handle dropped images.
    self.imageView.unregisterDraggedTypes()

    NSLayoutConstraint.activate([
      // This messes up the documentView's frame, why?
//      self.documentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
//      self.documentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
//      self.documentView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
//      self.documentView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
      self.imageView.topAnchor.constraint(equalTo: self.documentView.topAnchor),
      self.imageView.bottomAnchor.constraint(equalTo: self.documentView.bottomAnchor),
      self.imageView.leadingAnchor.constraint(equalTo: self.documentView.leadingAnchor),
      self.imageView.trailingAnchor.constraint(equalTo: self.documentView.trailingAnchor),
      self.cropTargetView.topAnchor.constraint(equalTo: self.imageView.topAnchor),
      self.cropTargetView.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor),
      self.cropTargetView.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor),
      self.cropTargetView.trailingAnchor.constraint(equalTo: self.imageView.trailingAnchor),
    ])
  }

  override func viewDidLoad() {
    self.cropPreviewsController.image = self.imageView.image
    self.cropTargetView.onChangeTarget = { [weak self] target in
      self?.cropPreviewsController.cropTarget = target
    }
  }

  deinit {
    if let willStartLiveMagnifyObserver = self.willStartLiveMagnifyObserver {
      NotificationCenter.default.removeObserver(willStartLiveMagnifyObserver)
    }
    if let didEndLiveMagnifyObserver = self.didEndLiveMagnifyObserver {
      NotificationCenter.default.removeObserver(didEndLiveMagnifyObserver)
    }
  }
}
