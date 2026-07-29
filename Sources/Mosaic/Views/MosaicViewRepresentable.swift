import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// How the scroll view adjusts its content inset for safe areas.
///
/// Mirrors `UIScrollView.ContentInsetAdjustmentBehavior`. `NSScrollView` has no
/// equivalent, so on macOS the value is accepted and ignored.
public enum MosaicContentInsetAdjustmentBehavior: Hashable, Sendable {
    case automatic
    case scrollableAxes
    case never
    case always

    #if canImport(UIKit)
    var uiKitBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        switch self {
        case .automatic:
            .automatic
        case .scrollableAxes:
            .scrollableAxes
        case .never:
            .never
        case .always:
            .always
        }
    }
    #endif
}

/// SwiftUI wrapper around `MosaicView` for declarative collection view layouts.
///
/// The `modelBuilder` closure receives the current view width so layouts can
/// adapt column counts or item sizes to the available space. The closure is
/// called both when the view is created and when it updates.
public struct MosaicViewRepresentable {
    /// Whether model changes animate inserts, deletes, and moves.
    public var animate: Bool = false

    /// Safe-area inset behavior for the underlying scroll view. Ignored on
    /// macOS, which has no equivalent.
    public var contentInsetAdjustmentBehavior: MosaicContentInsetAdjustmentBehavior = .automatic

    /// An opaque value with no direct effect: change it to make SwiftUI
    /// re-invoke the update pass (and thus `modelBuilder`) when nothing else
    /// in this view's inputs has changed.
    public var refreshToken: Int = 0

    /// Called with the content offset whenever the collection view scrolls.
    public var onScroll: ((CGPoint) -> Void)?

    /// Called after each applied model finishes its snapshot transition.
    public var onApply: (() -> Void)?

    /// Builds the model for the current view width, so layouts can adapt
    /// column counts or item sizes to the available space.
    public var modelBuilder: (CGFloat) -> MosaicModel

    public init(
        animate: Bool = false,
        contentInsetAdjustmentBehavior: MosaicContentInsetAdjustmentBehavior = .automatic,
        refreshToken: Int = 0,
        onScroll: ((CGPoint) -> Void)? = nil,
        onApply: (() -> Void)? = nil,
        modelBuilder: @escaping (CGFloat) -> MosaicModel
    ) {
        self.animate = animate
        self.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        self.refreshToken = refreshToken
        self.onScroll = onScroll
        self.onApply = onApply
        self.modelBuilder = modelBuilder
    }

    /// Builds and applies the model, returning whether the width changed and the
    /// layout therefore needs invalidating.
    @MainActor
    private func applyModel(to view: MosaicView, coordinator: Coordinator, animate: Bool) -> Bool {
        let width = view.bounds.width
        let model = modelBuilder(width)
        let widthChanged = width != coordinator.lastWidth
        coordinator.lastWidth = width
        view.apply(model, animate: animate) {
            coordinator.onApply?()
        }
        return widthChanged
    }
}

#if canImport(UIKit)

extension MosaicViewRepresentable: UIViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onApply: onApply)
    }

    public func makeUIView(context: Context) -> MosaicView {
        let view = MosaicView()
        view.collectionView.backgroundColor = .clear
        view.collectionView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior.uiKitBehavior
        view.collectionView.delegate = context.coordinator
        context.coordinator.mosaicView = view
        _ = applyModel(to: view, coordinator: context.coordinator, animate: false)
        return view
    }

    public func updateUIView(_ view: MosaicView, context: Context) {
        context.coordinator.onScroll = onScroll
        context.coordinator.onApply = onApply
        view.collectionView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior.uiKitBehavior

        if applyModel(to: view, coordinator: context.coordinator, animate: animate) {
            view.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    /// Forwards collection view callbacks to `MosaicView` while also observing
    /// scrolling, which UIKit delivers through this same delegate.
    public final class Coordinator: NSObject, UICollectionViewDelegate {
        var onScroll: ((CGPoint) -> Void)?
        var onApply: (() -> Void)?
        weak var mosaicView: MosaicView?
        var lastWidth: CGFloat = 0

        init(onScroll: ((CGPoint) -> Void)?, onApply: (() -> Void)?) {
            self.onScroll = onScroll
            self.onApply = onApply
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView.contentOffset)
        }

        public func collectionView(
            _: MosaicCollectionView,
            willDisplay cell: MosaicCell,
            forItemAt indexPath: IndexPath
        ) {
            mosaicView?.willDisplay(cell, at: indexPath)
        }

        public func collectionView(
            _: MosaicCollectionView,
            didEndDisplaying cell: MosaicCell,
            forItemAt indexPath: IndexPath
        ) {
            mosaicView?.didEndDisplaying(cell, at: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            shouldHighlightItemAt indexPath: IndexPath
        ) -> Bool {
            mosaicView?.collectionView(collectionView, shouldHighlightItemAt: indexPath) ?? false
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            didHighlightItemAt indexPath: IndexPath
        ) {
            mosaicView?.collectionView(collectionView, didHighlightItemAt: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            didUnhighlightItemAt indexPath: IndexPath
        ) {
            mosaicView?.collectionView(collectionView, didUnhighlightItemAt: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            shouldSelectItemAt indexPath: IndexPath
        ) -> Bool {
            mosaicView?.collectionView(collectionView, shouldSelectItemAt: indexPath) ?? true
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            didSelectItemAt indexPath: IndexPath
        ) {
            mosaicView?.collectionView(collectionView, didSelectItemAt: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            shouldDeselectItemAt indexPath: IndexPath
        ) -> Bool {
            mosaicView?.collectionView(collectionView, shouldDeselectItemAt: indexPath) ?? true
        }

        public func collectionView(_ collectionView: MosaicCollectionView, didDeselectItemAt indexPath: IndexPath) {
            mosaicView?.collectionView(collectionView, didDeselectItemAt: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            leadingSwipeActionsConfigurationForItemAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {
            mosaicView?.collectionView(collectionView, leadingSwipeActionsConfigurationForItemAt: indexPath)
        }

        public func collectionView(
            _ collectionView: MosaicCollectionView,
            trailingSwipeActionsConfigurationForItemAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {
            mosaicView?.collectionView(collectionView, trailingSwipeActionsConfigurationForItemAt: indexPath)
        }
    }
}

#else

extension MosaicViewRepresentable: NSViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onApply: onApply)
    }

    public func makeNSView(context: Context) -> MosaicView {
        let view = MosaicView()
        context.coordinator.mosaicView = view
        context.coordinator.observeScrolling(of: view.scrollView)
        _ = applyModel(to: view, coordinator: context.coordinator, animate: false)
        return view
    }

    public func updateNSView(_ view: MosaicView, context: Context) {
        context.coordinator.onScroll = onScroll
        context.coordinator.onApply = onApply

        if applyModel(to: view, coordinator: context.coordinator, animate: animate) {
            view.collectionView.collectionViewLayout?.invalidateLayout()
        }
    }

    /// Observes scrolling and carries per-update state.
    ///
    /// AppKit delivers scrolling through `NSScrollView` bounds notifications
    /// rather than the collection view delegate, so `MosaicView` remains its
    /// own delegate and the coordinator only watches scrolling.
    @MainActor
    public final class Coordinator: NSObject {
        var onScroll: ((CGPoint) -> Void)?
        var onApply: (() -> Void)?
        weak var mosaicView: MosaicView?
        var lastWidth: CGFloat = 0

        init(onScroll: ((CGPoint) -> Void)?, onApply: (() -> Void)?) {
            self.onScroll = onScroll
            self.onApply = onApply
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func observeScrolling(of scrollView: NSScrollView) {
            let clipView = scrollView.contentView
            clipView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(clipViewBoundsDidChange),
                name: NSView.boundsDidChangeNotification,
                object: clipView
            )
        }

        @objc
        private func clipViewBoundsDidChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView else { return }
            onScroll?(clipView.bounds.origin)
        }
    }
}

#endif
