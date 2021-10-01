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

final class ViewController: NSViewController {
  private var cropPreviewsController = CropPreviewsController()

  lazy var imageView: NSImageView = {
    let image = NSImage(named: "proudscrooge")!
    let imageView = NSImageView(image: image)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return imageView
  }()

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

  lazy var scrollView: NSScrollView = {
    let scrollView = NSScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.allowsMagnification = true
    scrollView.minMagnification = 0.1
    scrollView.maxMagnification = 10
    scrollView.contentView = self.clipView
    scrollView.setFrameSize(NSSize(width: 250, height: 200))
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

  private func updatePreviews() {
    self.cropPreviewsController.image = self.imageView.image
    self.cropPreviewsController.cropTarget = self.cropTargetView.target
  }

  override func loadView() {
    self.view = self.splitView

    self.updatePreviews()
    self.splitView.onDrop = { [weak self] url in
      let image = NSImage(byReferencing: url)
      self?.imageView.image = image
      self?.cropTargetView.target = CGRect(x: 10, y: 10, width: 100, height: 100)
      self?.updatePreviews()
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
}
