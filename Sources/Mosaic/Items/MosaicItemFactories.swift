import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Factory methods for building items. `cell` variants dequeue plain collection
/// cells; `list` variants dequeue list cells (`MosaicListCell`). Each family
/// offers explicit-id, `Identifiable`-derived, and `MosaicRefreshable`-derived
/// overloads, with or without hosted SwiftUI content.
public extension MosaicItem {
    /// Creates an item whose stable identity and rendered-state hash come from the value.
    static func cell<Cell: MosaicCell, Value: MosaicRefreshable>(
        _ cellType: Cell.Type = Cell.self,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        cell(cellType, value, refreshOn: value.mosaicRefreshValue, configure: configure)
    }

    /// Creates an item with a stable model identity and an explicit rendered-state projection.
    static func cell<Cell: MosaicCell, Value: Identifiable>(
        _ cellType: Cell.Type = Cell.self,
        _ value: Value,
        refreshOn refreshValue: some Hashable,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        TypedMosaicItem(
            MosaicItem(
                id: AnyHashable(value.id),
                cellType: cellType,
                value: value,
                contentHash: refreshValue.hashValue
            ) { cell, val in
                guard let typedCell = cell as? Cell, let typedValue = val as? Value else { return }
                configure(typedCell, typedValue)
            }
        )
    }

    /// Creates a `MosaicItem` for a platform cell subclass and hashable value.
    static func cell<Cell: MosaicCell, Value: Hashable>(
        _ cellType: Cell.Type = Cell.self,
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        TypedMosaicItem(
            MosaicItem(
                id: id,
                cellType: cellType,
                value: value,
                contentHash: value.hashValue
            ) { cell, val in
                guard let typedCell = cell as? Cell, let typedValue = val as? Value else { return }
                configure(typedCell, typedValue)
            }
        )
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func cell<Cell: MosaicCell, Value: Hashable & Identifiable>(
        _ cellType: Cell.Type = Cell.self,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        cell(cellType, id: AnyHashable(value.id), value, configure: configure)
    }

    /// Creates a `MosaicItem` backed by SwiftUI content hosted in a collection cell.
    static func cell<Content: View, Value: Hashable>(
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (MosaicCollectionViewCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Content>, Value> {
        cell(MosaicCollectionViewCell<Content>.self, id: id, value, configure: configure, content: content)
    }

    /// Creates a hosted SwiftUI item whose identity and rendered-state hash come from the value.
    static func cell<Content: View, Value: MosaicRefreshable>(
        _ value: Value,
        configure: @escaping @MainActor (MosaicCollectionViewCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Content>, Value> {
        cell(value, refreshOn: value.mosaicRefreshValue, configure: configure, content: content)
    }

    /// Creates a hosted SwiftUI item with an explicit rendered-state projection.
    static func cell<Content: View, Value: Identifiable>(
        _ value: Value,
        refreshOn refreshValue: some Hashable,
        configure: @escaping @MainActor (MosaicCollectionViewCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Content>, Value> {
        let item = MosaicItem(
            id: AnyHashable(value.id),
            cellType: MosaicCollectionViewCell<Content>.self,
            value: value,
            contentHash: refreshValue.hashValue
        ) { cell, storedValue in
            guard let cell = cell as? MosaicCollectionViewCell<Content>,
                  let storedValue = storedValue as? Value else { return }
            mosaicSetHostedContent(content(storedValue), on: cell)
            configure(cell, storedValue)
        }
        return TypedMosaicItem(item)
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func cell<Content: View, Value: Hashable & Identifiable>(
        _ value: Value,
        configure: @escaping @MainActor (MosaicCollectionViewCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewCell<Content>, Value> {
        cell(id: AnyHashable(value.id), value, configure: configure, content: content)
    }

    /// Creates a `MosaicItem` backed by SwiftUI content hosted in a custom collection cell.
    static func cell<Cell: MosaicCell, Value: Hashable>(
        _ cellType: Cell.Type,
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> TypedMosaicItem<Cell, Value> {
        cell(cellType, id: id, value) { cell, storedValue in
            mosaicSetHostedContent(content(storedValue), on: cell)
            configure(cell, storedValue)
        }
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func cell<Cell: MosaicCell, Value: Hashable & Identifiable>(
        _ cellType: Cell.Type,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> TypedMosaicItem<Cell, Value> {
        cell(cellType, id: AnyHashable(value.id), value, configure: configure, content: content)
    }

    /// Creates a `MosaicItem` backed by a list cell.
    static func list<Cell: MosaicListCell, Value: Hashable>(
        _ cellType: Cell.Type,
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        cell(cellType, id: id, value, configure: configure)
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func list<Cell: MosaicListCell, Value: Hashable & Identifiable>(
        _ cellType: Cell.Type,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<Cell, Value> {
        list(cellType, id: AnyHashable(value.id), value, configure: configure)
    }

    /// Creates a `MosaicItem` backed by SwiftUI content hosted in a list cell.
    static func list<Content: View, Value: Hashable>(
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (MosaicCollectionViewListCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<Content>, Value> {
        list(MosaicCollectionViewListCell<Content>.self, id: id, value, configure: configure, content: content)
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func list<Content: View, Value: Hashable & Identifiable>(
        _ value: Value,
        configure: @escaping @MainActor (MosaicCollectionViewListCell<Content>, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> Content
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<Content>, Value> {
        list(id: AnyHashable(value.id), value, configure: configure, content: content)
    }

    /// Creates a `MosaicItem` backed by SwiftUI content hosted in a custom list cell.
    static func list<Cell: MosaicListCell, Value: Hashable>(
        _ cellType: Cell.Type,
        id: AnyHashable,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> TypedMosaicItem<Cell, Value> {
        list(cellType, id: id, value) { cell, storedValue in
            mosaicSetHostedContent(content(storedValue), on: cell)
            configure(cell, storedValue)
        }
    }

    /// Overload that derives the identifier from `Identifiable.id`.
    static func list<Cell: MosaicListCell, Value: Hashable & Identifiable>(
        _ cellType: Cell.Type,
        _ value: Value,
        configure: @escaping @MainActor (Cell, Value) -> Void = { _, _ in },
        @ViewBuilder content: @escaping @MainActor (Value) -> some View
    ) -> TypedMosaicItem<Cell, Value> {
        list(cellType, id: AnyHashable(value.id), value, configure: configure, content: content)
    }

    // These overloads exist only to diagnose passing the list-cell base class
    // where a subclass is required. macOS has no distinct list-cell type
    // (`MosaicListCell` is `MosaicCell`), so there is no base class to catch and
    // declaring them would collide with the generic overloads above.
    #if canImport(UIKit)
    @available(
        *,
        unavailable,
        message: "Pass a MosaicListCell subclass to MosaicItem.list(_:id:_:configure:)."
    )
    static func list<Value: Hashable>(
        _: MosaicListCell.Type,
        id _: AnyHashable,
        _: Value,
        configure _: @escaping @MainActor (MosaicListCell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<MosaicListCell, Value> {
        fatalError("Unavailable")
    }

    @available(
        *,
        unavailable,
        message: "Pass a MosaicListCell subclass to MosaicItem.list(_:_:configure:)."
    )
    static func list<Value: Hashable & Identifiable>(
        _: MosaicListCell.Type,
        _: Value,
        configure _: @escaping @MainActor (MosaicListCell, Value) -> Void = { _, _ in }
    ) -> TypedMosaicItem<MosaicListCell, Value> {
        fatalError("Unavailable")
    }
    #endif

    /// Strongly typed variant of `willDisplay`.
    func willDisplay<Cell: MosaicCell, Value>(
        _: Cell.Type,
        _: Value.Type,
        _ callback: @escaping @MainActor (Cell, Value) -> Void
    ) -> MosaicItem {
        willDisplay { cell, val in
            guard let typedCell = cell as? Cell, let typedValue = val as? Value else { return }
            callback(typedCell, typedValue)
        }
    }

    /// Strongly typed variant of `didEndDisplaying`.
    func didEndDisplaying<Cell: MosaicCell, Value>(
        _: Cell.Type,
        _: Value.Type,
        _ callback: @escaping @MainActor (Cell, Value) -> Void
    ) -> MosaicItem {
        didEndDisplaying { cell, val in
            guard let typedCell = cell as? Cell, let typedValue = val as? Value else { return }
            callback(typedCell, typedValue)
        }
    }

    /// Strongly typed variant of `prefetchItemAt`.
    func prefetchItemAt<Value>(_: Value.Type, _ callback: @escaping @MainActor (Value) -> Void) -> MosaicItem {
        prefetchItemAt { val in
            guard let typedValue = val as? Value else { return }
            callback(typedValue)
        }
    }

    /// Strongly typed variant of `cancelPrefetchingForItemAt`.
    func cancelPrefetchingForItemAt<Value>(
        _: Value.Type,
        _ callback: @escaping @MainActor (Value) -> Void
    ) -> MosaicItem {
        cancelPrefetchingForItemAt { val in
            guard let typedValue = val as? Value else { return }
            callback(typedValue)
        }
    }
}
