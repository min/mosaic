#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

typealias MosaicSectionEnvironmentProvider =
    @MainActor (
        _ items: [MosaicItem],
        _ itemProvider: @escaping (IndexPath) -> MosaicItem?,
        _ deleteHandler: @escaping (IndexPath, @escaping () -> Void) -> Void,
        _ environment: any NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection

/// The appearance of a list section.
///
/// Styles map onto `UICollectionLayoutListConfiguration.Appearance` on iOS.
/// AppKit has no list-configuration equivalent, so on macOS every style renders
/// as a plain compositional list.
public enum MosaicListStyle: String, CaseIterable, Hashable, Sendable {
    case plain
    case grouped
    case insetGrouped
    case sidebar
    case sidebarPlain

    #if canImport(UIKit)
    var appearance: UICollectionLayoutListConfiguration.Appearance {
        switch self {
        case .plain:
            .plain
        case .grouped:
            .grouped
        case .insetGrouped:
            .insetGrouped
        case .sidebar:
            .sidebar
        case .sidebarPlain:
            .sidebarPlain
        }
    }
    #endif
}

/// Describes how a section arranges its items.
///
/// Use one of the built-in factories (`list`, `grid`, `adaptiveGrid`,
/// `waterfall`, `carousel`, `custom`, `section`), wrap an
/// `NSCollectionLayoutSection` you built yourself, or provide a closure that
/// receives the effective content size. Layouts are refined with modifiers
/// such as `contentInsets(_:)`, `interGroupSpacing(_:)`, `sectionHeader(...)`,
/// and `decorated(by:)`, each returning a new layout.
public struct MosaicLayout {
    let sizeProvider: MosaicSectionLayoutProvider
    let environmentProvider: MosaicSectionEnvironmentProvider
    let decorationRegistrations: [MosaicDecorationRegistration]
    let suppliesSwipeActionsViaListConfiguration: Bool

    init(
        sizeProvider: @escaping MosaicSectionLayoutProvider,
        environmentProvider: @escaping MosaicSectionEnvironmentProvider,
        decorationRegistrations: [MosaicDecorationRegistration] = [],
        suppliesSwipeActionsViaListConfiguration: Bool = false
    ) {
        self.sizeProvider = sizeProvider
        self.environmentProvider = environmentProvider
        self.decorationRegistrations = decorationRegistrations
        self.suppliesSwipeActionsViaListConfiguration = suppliesSwipeActionsViaListConfiguration
    }

    /// Wraps a ready-made compositional layout section.
    public init(_ section: NSCollectionLayoutSection) {
        self.init(
            sizeProvider: { _ in section },
            environmentProvider: { _, _, _, _ in section }
        )
    }

    /// Wraps a closure that builds the section from the effective content size.
    public init(_ provider: @escaping MosaicSectionLayoutProvider) {
        self.init(sizeProvider: provider) { _, _, _, environment in
            provider(environment.container.effectiveContentSize)
        }
    }

    /// Resolves the layout into a concrete section for the given content size.
    /// Primarily useful in tests and previews; at runtime the compositional
    /// layout resolves sections through its environment.
    @MainActor
    public func resolve(_ effectiveContentSize: CGSize) -> NSCollectionLayoutSection {
        sizeProvider(effectiveContentSize)
    }

    func applyingDecorations(_ decorations: [MosaicDecorationRegistration]) -> Self {
        let baseSizeProvider = sizeProvider
        let baseEnvironmentProvider = environmentProvider
        let mergedDecorations = (decorationRegistrations + decorations).uniquedByElementKind()
        let decorationElementKinds = mergedDecorations.map(\.elementKind)
        return Self(
            sizeProvider: { effectiveContentSize in
                let section = baseSizeProvider(effectiveContentSize)
                return Self.applyDecorations(
                    decorationElementKinds,
                    to: section
                )
            },
            environmentProvider: { items, itemProvider, deleteHandler, environment in
                let section = baseEnvironmentProvider(items, itemProvider, deleteHandler, environment)
                return Self.applyDecorations(
                    decorationElementKinds,
                    to: section
                )
            },
            decorationRegistrations: mergedDecorations,
            suppliesSwipeActionsViaListConfiguration: suppliesSwipeActionsViaListConfiguration
        )
    }

    @MainActor
    private static func applyDecorations(
        _ decorationElementKinds: [String],
        to section: NSCollectionLayoutSection
    ) -> NSCollectionLayoutSection {
        guard !decorationElementKinds.isEmpty else { return section }
        let requestedElementKinds = Set(decorationElementKinds)
        var seenManagedElementKinds = Set<String>()
        var resolvedDecorationItems: [NSCollectionLayoutDecorationItem] = []

        for decorationItem in section.decorationItems {
            if requestedElementKinds.contains(decorationItem.elementKind) {
                guard seenManagedElementKinds.insert(decorationItem.elementKind).inserted else { continue }
            }
            resolvedDecorationItems.append(decorationItem)
        }

        for elementKind in decorationElementKinds where !seenManagedElementKinds.contains(elementKind) {
            resolvedDecorationItems.append(.background(elementKind: elementKind))
        }

        section.decorationItems = resolvedDecorationItems
        return section
    }
}

public extension MosaicLayout {
    static func list(style: MosaicListStyle = .plain) -> Self {
        Self(
            sizeProvider: { _ in MosaicDefaultLayout.list() },
            environmentProvider: { _, itemProvider, deleteHandler, environment in
                MosaicDefaultLayout.list(
                    style: style,
                    using: environment,
                    itemProvider: itemProvider,
                    deleteHandler: deleteHandler
                )
            },
            // Only UIKit's list configuration serves swipe actions itself; the
            // flag stops the delegate serving them a second time. AppKit has no
            // list configuration, so nothing is supplied there.
            suppliesSwipeActionsViaListConfiguration: MosaicPlatformCapabilities.hasListConfiguration
        )
    }

    @MainActor
    static func waterfall(
        columns: Int = 2,
        spacing: CGFloat = 8,
        interItemSpacing: CGFloat = 0,
        insets: NSDirectionalEdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8),
        estimatedHeight: CGFloat = 100
    ) -> Self {
        Self(
            MosaicDefaultLayout.waterfall(
                columns: columns,
                spacing: spacing,
                interItemSpacing: interItemSpacing,
                insets: insets,
                estimatedHeight: estimatedHeight
            )
        )
    }

    static func grid(
        columns: Int,
        spacing: CGFloat = 8,
        interItemSpacing: CGFloat = 0,
        insets: NSDirectionalEdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8),
        itemHeight: NSCollectionLayoutDimension? = nil
    ) -> Self {
        Self { (_: CGSize) in
            let resolvedItemHeight = itemHeight ?? .estimated(100)
            let safeColumns = max(columns, 1)
            let item = NSCollectionLayoutItem(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0 / CGFloat(safeColumns)),
                    heightDimension: resolvedItemHeight
                )
            )

            let group = NSCollectionLayoutGroup.mosaicHorizontal(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: resolvedItemHeight
                ),
                repeating: item,
                count: safeColumns
            )
            group.interItemSpacing = .fixed(interItemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = insets
            return section
        }
    }

    static func adaptiveGrid(
        minItemWidth: CGFloat,
        maximumColumns: Int? = nil,
        spacing: CGFloat = 8,
        interItemSpacing: CGFloat = 0,
        insets: NSDirectionalEdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8),
        itemHeight: NSCollectionLayoutDimension? = nil
    ) -> Self {
        Self { size in
            let availableWidth = size.width - insets.leading - insets.trailing
            let resolvedColumns = max(
                1,
                Int((availableWidth + interItemSpacing) / max(minItemWidth + interItemSpacing, 1))
            )
            let columns = min(resolvedColumns, maximumColumns ?? resolvedColumns)
            return grid(
                columns: columns,
                spacing: spacing,
                interItemSpacing: interItemSpacing,
                insets: insets,
                itemHeight: itemHeight
            ).resolve(size)
        }
    }

    static func carousel(
        itemWidth: NSCollectionLayoutDimension? = nil,
        itemHeight: NSCollectionLayoutDimension,
        spacing: CGFloat = 12,
        insets: NSDirectionalEdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16),
        behavior: MosaicSectionOrthogonalScrollingBehavior = .groupPagingCentered
    ) -> Self {
        Self { (_: CGSize) in
            let resolvedItemWidth = itemWidth ?? .fractionalWidth(0.85)
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: resolvedItemWidth, heightDimension: itemHeight),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = behavior
            section.interGroupSpacing = spacing
            section.contentInsets = insets
            return section
        }
    }

    static func custom(_ provider: @escaping MosaicSectionLayoutProvider) -> Self {
        Self(provider)
    }

    func decorated(by decorations: [MosaicDecorationRegistration]) -> Self {
        applyingDecorations(decorations)
    }

    func decorated(by decoration: MosaicDecorationRegistration) -> Self {
        applyingDecorations([decoration])
    }
}

private extension [MosaicDecorationRegistration] {
    func uniquedByElementKind() -> [Element] {
        var seen = Set<Element>()
        var unique: [Element] = []

        for decoration in self where seen.insert(decoration).inserted {
            unique.append(decoration)
        }

        return unique
    }
}
