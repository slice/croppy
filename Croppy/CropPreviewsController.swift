import Cocoa

final class CropPreviewsController: NSViewController {
  private lazy var previews: [CroppedImageView] = {
    [self.circlePreviewView, self.smallCirclePreviewView, self.squarePreviewView, self.smallSquarePreviewView]
  }()

  var image: NSImage? {
    didSet {
      for preview in previews {
        preview.image = self.image
      }
    }
  }

  var cropTarget: NSRect? {
    didSet {
      for preview in previews {
        preview.crop = self.cropTarget
      }
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
