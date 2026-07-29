#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Anything that can appear in a `MosaicSection`'s item builder.
///
/// Both the type-erased `MosaicItem` and the typed `TypedMosaicItem` conform,
/// so factory results can be used in the DSL directly or unwrapped explicitly
/// via `mosaicItem`.
public protocol MosaicItemType {
    var mosaicItem: MosaicItem { get }
}

extension MosaicItem: MosaicItemType {
    public var mosaicItem: MosaicItem {
        self
    }
}

/// A `MosaicItem` that remembers its cell and value types.
///
/// Returned by the `MosaicItem.cell`/`.list` factories so that chained
/// callbacks — `willDisplay`, `didSelectItemAt`, `onDelete`, swipe actions —
/// receive typed arguments instead of the type-erased `(MosaicCell, Any)`
/// pairs on `MosaicItem`.
public struct TypedMosaicItem<Cell: MosaicCell, Value>: MosaicItemType {
    public let mosaicItem: MosaicItem

    init(_ mosaicItem: MosaicItem) {
        self.mosaicItem = mosaicItem
    }
}

public extension TypedMosaicItem {
    func willDisplay(_ callback: @escaping @MainActor (Value) -> Void) -> Self {
        .init(
            mosaicItem.willDisplay { _, value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }

    func willDisplay(_ callback: @escaping @MainActor (Cell, Value) -> Void) -> Self {
        .init(
            mosaicItem.willDisplay { cell, value in
                guard let typedCell = cell as? Cell, let typedValue = value as? Value else { return }
                callback(typedCell, typedValue)
            }
        )
    }

    func didEndDisplaying(_ callback: @escaping @MainActor (Value) -> Void) -> Self {
        .init(
            mosaicItem.didEndDisplaying { _, value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }

    func didEndDisplaying(_ callback: @escaping @MainActor (Cell, Value) -> Void) -> Self {
        .init(
            mosaicItem.didEndDisplaying { cell, value in
                guard let typedCell = cell as? Cell, let typedValue = value as? Value else { return }
                callback(typedCell, typedValue)
            }
        )
    }

    func didReconfigure(_ callback: @escaping @MainActor (Value) -> Void) -> Self {
        .init(
            mosaicItem.didReconfigure { _, value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }

    func didReconfigure(_ callback: @escaping @MainActor (Cell, Value) -> Void) -> Self {
        .init(
            mosaicItem.didReconfigure { cell, value in
                guard let typedCell = cell as? Cell, let typedValue = value as? Value else { return }
                callback(typedCell, typedValue)
            }
        )
    }

    func prefetchItemAt(_ callback: @escaping @MainActor (Value) -> Void) -> Self {
        .init(
            mosaicItem.prefetchItemAt { value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }

    func cancelPrefetchingForItemAt(_ callback: @escaping @MainActor (Value) -> Void) -> Self {
        .init(
            mosaicItem.cancelPrefetchingForItemAt { value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }

    func shouldSelectItemAt(_ callback: @escaping @MainActor () -> Bool) -> Self {
        .init(mosaicItem.shouldSelectItemAt(callback))
    }

    func didSelectItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        .init(mosaicItem.didSelectItemAt(callback))
    }

    func shouldDeselectItemAt(_ callback: @escaping @MainActor () -> Bool) -> Self {
        .init(mosaicItem.shouldDeselectItemAt(callback))
    }

    func didDeselectItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        .init(mosaicItem.didDeselectItemAt(callback))
    }

    func didHighlightItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        .init(mosaicItem.didHighlightItemAt(callback))
    }

    func didUnhighlightItemAt(_ callback: @escaping @MainActor () -> Void) -> Self {
        .init(mosaicItem.didUnhighlightItemAt(callback))
    }

    func leadingSwipeActionsConfiguration(
        _ callback: @escaping @MainActor (Value) -> MosaicSwipeActionsConfiguration?
    ) -> Self {
        .init(
            mosaicItem.leadingSwipeActionsConfiguration { value in
                guard let typedValue = value as? Value else { return nil }
                return callback(typedValue)
            }
        )
    }

    func trailingSwipeActionsConfiguration(
        _ callback: @escaping @MainActor (Value) -> MosaicSwipeActionsConfiguration?
    ) -> Self {
        .init(
            mosaicItem.trailingSwipeActionsConfiguration { value in
                guard let typedValue = value as? Value else { return nil }
                return callback(typedValue)
            }
        )
    }

    func onDelete(
        title: String? = nil,
        image: MosaicPlatformImage? = nil,
        backgroundColor: MosaicPlatformColor? = nil,
        performsFirstActionWithFullSwipe: Bool = true,
        _ callback: @escaping @MainActor (Value) -> Void
    ) -> Self {
        .init(
            mosaicItem.onDelete(
                title: title,
                image: image,
                backgroundColor: backgroundColor,
                performsFirstActionWithFullSwipe: performsFirstActionWithFullSwipe
            ) { value in
                guard let typedValue = value as? Value else { return }
                callback(typedValue)
            }
        )
    }
}
