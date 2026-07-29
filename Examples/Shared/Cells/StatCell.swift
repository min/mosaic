#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Mosaic

/// A hand-built cell with no SwiftUI involved, showing that the UIKit/AppKit
/// path is fully cross-platform.
///
/// The subview hierarchy is attached to `mosaicContentView`, which resolves to
/// `contentView` on iOS and the item's root `view` on macOS. Only the
/// initializer differs between platforms, because `NSCollectionViewItem` is a
/// view controller and loads its view separately.
final class StatCell: MosaicCell {
    struct Value: Hashable, Identifiable {
        let id: String
        let caption: String
        let detail: String
        let isSupported: Bool
    }

    private let captionLabel = PlatformLabel()
    private let detailLabel = PlatformLabel()

    #if canImport(UIKit)
    override init(frame: CGRect) {
        super.init(frame: frame)
        installSubviews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #else
    override func loadView() {
        view = NSView()
        installSubviews()
    }
    #endif

    func render(value: Value) {
        captionLabel.text = value.caption
        detailLabel.text = value.detail
        detailLabel.textColor = value.isSupported ? .systemGreen : .secondaryLabelColorCompat
    }

    private func installSubviews() {
        let container = mosaicContentView

        for label in [captionLabel, detailLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
        }

        captionLabel.font = .boldSystemFont(ofSize: 13)
        detailLabel.font = .systemFont(ofSize: 12)

        NSLayoutConstraint.activate([
            captionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            captionLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),

            detailLabel.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 2),
            detailLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])
    }
}
