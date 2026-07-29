#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Builds a compositional layout section from the collection view's effective
/// content size, letting layouts adapt column counts or item sizes to the
/// available space.
public typealias MosaicSectionLayoutProvider = @MainActor (_ effectiveContentSize: CGSize) -> NSCollectionLayoutSection

/// Represents a single section in a `MosaicModel`.
public struct MosaicSection: Hashable {
    /// Stable identifier for diffing and section moves.
    public let id: AnyHashable

    /// Layout provider that resolves a compositional layout section from the effective content size.
    public let layout: MosaicSectionLayoutProvider

    let resolvedLayout: MosaicLayout

    /// Items contained in the section.
    public let items: [MosaicItem]

    /// Supplementary views attached to the section, keyed by element kind.
    public let supplementaryViews: [MosaicSupplementaryView]

    /// Creates a new section with the default list layout.
    public init(
        _ id: AnyHashable,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout.list(), supplementaryViews: [], items: items)
    }

    /// Creates a new section with default list layout and supplementary views.
    public init(
        _ id: AnyHashable,
        header: MosaicSupplementaryView?,
        footer: MosaicSupplementaryView? = nil,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(
            id,
            layout: MosaicLayout.list(),
            supplementaryViews: Self.supplementaryViews(header: header, footer: footer),
            items: items
        )
    }

    /// Creates a new section with default list layout and a footer.
    public init(
        _ id: AnyHashable,
        footer: MosaicSupplementaryView,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, header: nil, footer: footer, items: items)
    }

    /// Creates a new section with the provided identifier, layout and items.
    public init(
        _ id: AnyHashable,
        layout: MosaicLayout,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: layout, supplementaryViews: [], items: items)
    }

    /// Creates a new section with the provided identifier, layout, supplementary views and items.
    public init(
        _ id: AnyHashable,
        layout: MosaicLayout,
        header: MosaicSupplementaryView?,
        footer: MosaicSupplementaryView? = nil,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(
            id,
            layout: layout,
            supplementaryViews: Self.supplementaryViews(header: header, footer: footer),
            items: items
        )
    }

    /// Creates a new section with the provided identifier, layout, footer and items.
    public init(
        _ id: AnyHashable,
        layout: MosaicLayout,
        footer: MosaicSupplementaryView,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: layout, header: nil, footer: footer, items: items)
    }

    /// Creates a new section from a raw compositional layout section.
    public init(
        _ id: AnyHashable,
        layout: NSCollectionLayoutSection,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), items: items)
    }

    /// Creates a new section from a raw compositional layout section and supplementary views.
    public init(
        _ id: AnyHashable,
        layout: NSCollectionLayoutSection,
        header: MosaicSupplementaryView?,
        footer: MosaicSupplementaryView? = nil,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), header: header, footer: footer, items: items)
    }

    /// Creates a new section from a raw compositional layout section and footer.
    public init(
        _ id: AnyHashable,
        layout: NSCollectionLayoutSection,
        footer: MosaicSupplementaryView,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), footer: footer, items: items)
    }

    /// Creates a new section with a layout closure that receives the collection view's
    /// effective content size from the compositional layout environment.
    public init(
        _ id: AnyHashable,
        layout: @escaping MosaicSectionLayoutProvider,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), items: items)
    }

    /// Creates a new section with a layout closure, supplementary views and items.
    public init(
        _ id: AnyHashable,
        layout: @escaping MosaicSectionLayoutProvider,
        header: MosaicSupplementaryView?,
        footer: MosaicSupplementaryView? = nil,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), header: header, footer: footer, items: items)
    }

    /// Creates a new section with a layout closure, footer and items.
    public init(
        _ id: AnyHashable,
        layout: @escaping MosaicSectionLayoutProvider,
        footer: MosaicSupplementaryView,
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.init(id, layout: MosaicLayout(layout), footer: footer, items: items)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    private init(
        _ id: AnyHashable,
        layout: MosaicLayout,
        supplementaryViews: [MosaicSupplementaryView],
        @MosaicItemsBuilder items: () -> [MosaicItem]
    ) {
        self.id = id
        let builtItems = items()
        self.layout = layout.sizeProvider
        resolvedLayout = layout
        self.items = builtItems
        self.supplementaryViews = supplementaryViews
    }

    private static func supplementaryViews(
        header: MosaicSupplementaryView?,
        footer: MosaicSupplementaryView?
    ) -> [MosaicSupplementaryView] {
        [header, footer].compactMap(\.self).uniquedByElementKind()
    }
}

private extension [MosaicSupplementaryView] {
    func uniquedByElementKind() -> [Element] {
        var seen = Set<String>()
        var unique: [Element] = []

        for supplementaryView in self where seen.insert(supplementaryView.elementKind).inserted {
            unique.append(supplementaryView)
        }

        return unique
    }
}
