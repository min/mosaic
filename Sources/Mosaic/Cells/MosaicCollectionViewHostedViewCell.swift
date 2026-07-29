#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// A cell that hosts a platform view of type `Content`, pinned to its edges.
public final class MosaicCollectionViewHostedViewCell<Content: MosaicPlatformView>: MosaicCell {
    /// The wrapped view instance, created once per cell and reused across
    /// reconfigurations.
    public let hostedView: Content

    #if canImport(UIKit)
    override public init(frame: CGRect) {
        hostedView = Content(frame: .zero)
        super.init(frame: frame)
        pinHostedView(into: contentView)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #else
    /// `NSCollectionViewItem` is a view controller, so the hosted view is
    /// attached when the root view is loaded rather than in the initializer.
    override public init(nibName: NSNib.Name?, bundle: Bundle?) {
        hostedView = Content(frame: .zero)
        super.init(nibName: nibName, bundle: bundle)
        // UIKit cells own a `contentView` from initialisation. AppKit loads an
        // item's view lazily, so force it here to keep `hostedView` attached at
        // the same point in the lifecycle on both platforms.
        loadViewIfNeeded()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let container = NSView()
        view = container
        pinHostedView(into: container)
    }
    #endif

    /// The view `hostedView` is pinned inside: the cell's `contentView` on iOS,
    /// the item's root view on macOS.
    public var hostedViewContainer: MosaicPlatformView {
        mosaicContentView
    }

    private func pinHostedView(into container: MosaicPlatformView) {
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: container.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }
}
