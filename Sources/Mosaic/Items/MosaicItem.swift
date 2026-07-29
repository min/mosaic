#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// A type-erased representation of an item in a `MosaicSection`.
///
/// `MosaicItem` encapsulates everything needed by the diffable data source to
/// identify, configure and detect changes to a given item. The `id` is used
/// exclusively for identity within the diffable snapshot; the `contentHash`
/// represents the value and is used to determine when a cell should be
/// reconfigured. The `configure` closure is invoked to mutate a dequeued
/// `MosaicCell` into its final state.
public struct MosaicItem: Hashable {
    /// A stable identifier used by diffable data sources. Two items with the
    /// same identifier are considered the same logical item and will be moved
    /// rather than inserted/deleted when their positions change.
    public let id: AnyHashable

    /// The concrete `MosaicCell` subclass used to display this item.
    public let cellType: MosaicCell.Type

    /// Optional explicit reuse identifier. Defaults to the cell type name when `nil`.
    public let reuseIdentifier: String?

    /// An opaque value associated with the item. This is passed back into the
    /// `configure` closure when configuring cells.
    public let value: Any

    /// A hash representing the value of the item. When the hash differs
    /// between two snapshots for the same `id`, `MosaicView` will call
    /// `reconfigureItems(_:)` instead of reloading the cell.
    public let contentHash: Int

    /// A closure responsible for configuring a dequeued cell with the
    /// underlying value. The closure is given the concrete cell instance and
    /// the value in its original type-erased form.
    public let configure: @MainActor (MosaicCell, Any) -> Void

    /// An optional closure invoked when the cell is about to be displayed.
    public let willDisplay: (@MainActor (MosaicCell, Any) -> Void)?

    /// An optional closure invoked after the cell is no longer displayed.
    public let didEndDisplaying: (@MainActor (MosaicCell, Any) -> Void)?

    /// An optional closure invoked after a visible cell is reconfigured in place.
    public let didReconfigure: (@MainActor (MosaicCell, Any) -> Void)?

    /// An optional closure invoked when the collection view predicts the item
    /// will be needed soon.
    public let prefetchItemAt: (@MainActor (Any) -> Void)?

    /// An optional closure invoked when the collection view cancels a prior prefetch request.
    public let cancelPrefetchingForItemAt: (@MainActor (Any) -> Void)?

    /// An optional closure invoked before the item's cell is selected.
    public let shouldSelectItemAt: (@MainActor () -> Bool)?

    /// An optional closure invoked when the item's cell is selected.
    public let didSelectItemAt: (@MainActor () -> Void)?

    /// An optional closure invoked before the item's cell is deselected.
    public let shouldDeselectItemAt: (@MainActor () -> Bool)?

    /// An optional closure invoked when the item's cell is deselected.
    public let didDeselectItemAt: (@MainActor () -> Void)?

    /// An optional closure invoked when the item's cell becomes highlighted.
    public let didHighlightItemAt: (@MainActor () -> Void)?

    /// An optional closure invoked when the item's cell loses highlight.
    public let didUnhighlightItemAt: (@MainActor () -> Void)?

    /// An optional closure that builds leading swipe actions for the item.
    public let leadingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)?

    /// An optional closure that builds trailing swipe actions for the item.
    public let trailingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)?

    /// Creates a new `MosaicItem`.
    public init(
        id: AnyHashable,
        cellType: MosaicCell.Type,
        value: Any,
        contentHash: Int,
        reuseIdentifier: String? = nil,
        willDisplay: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        didEndDisplaying: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        didReconfigure: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        prefetchItemAt: (@MainActor (Any) -> Void)? = nil,
        cancelPrefetchingForItemAt: (@MainActor (Any) -> Void)? = nil,
        shouldSelectItemAt: (@MainActor () -> Bool)? = nil,
        didSelectItemAt: (@MainActor () -> Void)? = nil,
        shouldDeselectItemAt: (@MainActor () -> Bool)? = nil,
        didDeselectItemAt: (@MainActor () -> Void)? = nil,
        didHighlightItemAt: (@MainActor () -> Void)? = nil,
        didUnhighlightItemAt: (@MainActor () -> Void)? = nil,
        leadingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)? = nil,
        trailingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)? = nil,
        configure: @escaping @MainActor (MosaicCell, Any) -> Void
    ) {
        self.id = id
        self.cellType = cellType
        self.value = value
        self.contentHash = contentHash
        self.reuseIdentifier = reuseIdentifier
        self.willDisplay = willDisplay
        self.didEndDisplaying = didEndDisplaying
        self.didReconfigure = didReconfigure
        self.prefetchItemAt = prefetchItemAt
        self.cancelPrefetchingForItemAt = cancelPrefetchingForItemAt
        self.shouldSelectItemAt = shouldSelectItemAt
        self.didSelectItemAt = didSelectItemAt
        self.shouldDeselectItemAt = shouldDeselectItemAt
        self.didDeselectItemAt = didDeselectItemAt
        self.didHighlightItemAt = didHighlightItemAt
        self.didUnhighlightItemAt = didUnhighlightItemAt
        self.leadingSwipeActionsConfiguration = leadingSwipeActionsConfiguration
        self.trailingSwipeActionsConfiguration = trailingSwipeActionsConfiguration
        self.configure = configure
    }

    /// Returns a copy that invokes `callback` before display.
    public func willDisplay(_ callback: @escaping @MainActor (MosaicCell, Any) -> Void) -> Self {
        copy(willDisplay: callback)
    }

    /// Returns a copy that invokes `callback` after display ends.
    public func didEndDisplaying(_ callback: @escaping @MainActor (MosaicCell, Any) -> Void) -> Self {
        copy(didEndDisplaying: callback)
    }

    /// Returns a copy that invokes `callback` after a visible cell is reconfigured.
    public func didReconfigure(_ callback: @escaping @MainActor (MosaicCell, Any) -> Void) -> Self {
        copy(didReconfigure: callback)
    }

    /// Returns a copy that invokes `callback` during prefetch.
    public func prefetchItemAt(_ callback: @escaping @MainActor (Any) -> Void) -> Self {
        copy(prefetchItemAt: callback)
    }

    /// Returns a copy that invokes `callback` when a prefetch request is canceled.
    public func cancelPrefetchingForItemAt(_ callback: @escaping @MainActor (Any) -> Void) -> Self {
        copy(cancelPrefetchingForItemAt: callback)
    }

    /// Returns a copy that invokes `callback` before selection.
    public func shouldSelectItemAt(_ callback: @escaping @MainActor () -> Bool) -> Self {
        copy(shouldSelectItemAt: callback)
    }

    /// Returns a copy that invokes `callback` when selected.
    public func didSelectItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        copy(didSelectItemAt: callback)
    }

    /// Returns a copy that invokes `callback` before deselection.
    public func shouldDeselectItemAt(_ callback: @escaping @MainActor () -> Bool) -> Self {
        copy(shouldDeselectItemAt: callback)
    }

    /// Returns a copy that invokes `callback` when deselected.
    public func didDeselectItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        copy(didDeselectItemAt: callback)
    }

    /// Returns a copy that invokes `callback` when highlighted.
    public func didHighlightItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        copy(didHighlightItemAt: callback)
    }

    /// Returns a copy that invokes `callback` when highlight ends.
    public func didUnhighlightItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        copy(didUnhighlightItemAt: callback)
    }

    /// Returns a copy that supplies leading swipe actions for this item.
    public func leadingSwipeActionsConfiguration(
        _ callback: @escaping @MainActor (Any) -> MosaicSwipeActionsConfiguration?
    ) -> Self {
        copy(leadingSwipeActionsConfiguration: callback)
    }

    /// Returns a copy that supplies trailing swipe actions for this item.
    public func trailingSwipeActionsConfiguration(
        _ callback: @escaping @MainActor (Any) -> MosaicSwipeActionsConfiguration?
    ) -> Self {
        copy(trailingSwipeActionsConfiguration: callback)
    }

    /// Returns a copy with a trailing delete action.
    ///
    /// Main-actor-isolated because the swipe configuration closure captures the
    /// non-Sendable image and color; forming it off the main actor would send
    /// them across isolation domains.
    @MainActor
    public func onDelete(
        title: String? = nil,
        image: MosaicPlatformImage? = nil,
        backgroundColor: MosaicPlatformColor? = nil,
        performsFirstActionWithFullSwipe: Bool = true,
        _ callback: @escaping @MainActor (Any) -> Void
    ) -> Self {
        trailingSwipeActionsConfiguration { value in
            let action = MosaicSwipeAction(
                style: .destructive,
                title: title,
                image: image,
                backgroundColor: backgroundColor ?? .systemRed
            ) { completion in
                callback(value)
                completion(true)
            }
            return MosaicSwipeActionsConfiguration(
                actions: [action],
                performsFirstActionWithFullSwipe: performsFirstActionWithFullSwipe
            )
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    private func copy(
        willDisplay: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        didEndDisplaying: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        didReconfigure: (@MainActor (MosaicCell, Any) -> Void)? = nil,
        prefetchItemAt: (@MainActor (Any) -> Void)? = nil,
        cancelPrefetchingForItemAt: (@MainActor (Any) -> Void)? = nil,
        shouldSelectItemAt: (@MainActor () -> Bool)? = nil,
        didSelectItemAt: (@MainActor () -> Void)? = nil,
        shouldDeselectItemAt: (@MainActor () -> Bool)? = nil,
        didDeselectItemAt: (@MainActor () -> Void)? = nil,
        didHighlightItemAt: (@MainActor () -> Void)? = nil,
        didUnhighlightItemAt: (@MainActor () -> Void)? = nil,
        leadingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)? = nil,
        trailingSwipeActionsConfiguration: (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)? = nil
    ) -> Self {
        Self(
            id: id,
            cellType: cellType,
            value: value,
            contentHash: contentHash,
            reuseIdentifier: reuseIdentifier,
            willDisplay: willDisplay ?? self.willDisplay,
            didEndDisplaying: didEndDisplaying ?? self.didEndDisplaying,
            didReconfigure: didReconfigure ?? self.didReconfigure,
            prefetchItemAt: prefetchItemAt ?? self.prefetchItemAt,
            cancelPrefetchingForItemAt: cancelPrefetchingForItemAt ?? self.cancelPrefetchingForItemAt,
            shouldSelectItemAt: shouldSelectItemAt ?? self.shouldSelectItemAt,
            didSelectItemAt: didSelectItemAt ?? self.didSelectItemAt,
            shouldDeselectItemAt: shouldDeselectItemAt ?? self.shouldDeselectItemAt,
            didDeselectItemAt: didDeselectItemAt ?? self.didDeselectItemAt,
            didHighlightItemAt: didHighlightItemAt ?? self.didHighlightItemAt,
            didUnhighlightItemAt: didUnhighlightItemAt ?? self.didUnhighlightItemAt,
            leadingSwipeActionsConfiguration: leadingSwipeActionsConfiguration ?? self.leadingSwipeActionsConfiguration,
            trailingSwipeActionsConfiguration:
            trailingSwipeActionsConfiguration ?? self.trailingSwipeActionsConfiguration,
            configure: configure
        )
    }
}
