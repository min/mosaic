#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Anything usable inside a layout group builder: `MosaicLayoutItem`,
/// `MosaicLayoutGroup`, or a raw `NSCollectionLayoutItem`.
@MainActor
public protocol MosaicLayoutComponent {
    var layoutItem: NSCollectionLayoutItem { get }
}

extension NSCollectionLayoutItem: MosaicLayoutComponent {
    public var layoutItem: NSCollectionLayoutItem {
        self
    }
}

/// A single compositional layout item with a declarative initializer, for use
/// inside `MosaicLayoutGroup` builders.
public struct MosaicLayoutItem: MosaicLayoutComponent {
    public let layoutItem: NSCollectionLayoutItem

    @MainActor
    public init(
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension = .estimated(44),
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: width, heightDimension: height)
        )
        item.contentInsets = contentInsets
        layoutItem = item
    }
}

/// A horizontal or vertical compositional layout group, composable with other
/// components and convertible into a section via `MosaicLayout.section(_:)`.
public struct MosaicLayoutGroup: MosaicLayoutComponent {
    public let layoutGroup: NSCollectionLayoutGroup

    public var layoutItem: NSCollectionLayoutItem {
        layoutGroup
    }

    private init(_ layoutGroup: NSCollectionLayoutGroup) {
        self.layoutGroup = layoutGroup
    }

    @MainActor
    public static func horizontal(
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension,
        interItemSpacing: CGFloat? = nil,
        contentInsets: NSDirectionalEdgeInsets = .zero,
        @MosaicLayoutItemsBuilder subitems: () -> [NSCollectionLayoutItem]
    ) -> Self {
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: width, heightDimension: height),
            subitems: subitems()
        )
        group.interItemSpacing = interItemSpacing.map(NSCollectionLayoutSpacing.fixed)
        group.contentInsets = contentInsets
        return Self(group)
    }

    @MainActor
    public static func horizontal(
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension,
        repeating subitem: some MosaicLayoutComponent,
        count: Int,
        interItemSpacing: CGFloat? = nil,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        let group = NSCollectionLayoutGroup.mosaicHorizontal(
            layoutSize: .init(widthDimension: width, heightDimension: height),
            repeating: subitem.layoutItem,
            count: max(count, 1)
        )
        group.interItemSpacing = interItemSpacing.map(NSCollectionLayoutSpacing.fixed)
        group.contentInsets = contentInsets
        return Self(group)
    }

    @MainActor
    public static func vertical(
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension,
        interItemSpacing: CGFloat? = nil,
        contentInsets: NSDirectionalEdgeInsets = .zero,
        @MosaicLayoutItemsBuilder subitems: () -> [NSCollectionLayoutItem]
    ) -> Self {
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: width, heightDimension: height),
            subitems: subitems()
        )
        group.interItemSpacing = interItemSpacing.map(NSCollectionLayoutSpacing.fixed)
        group.contentInsets = contentInsets
        return Self(group)
    }

    @MainActor
    public static func vertical(
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension,
        repeating subitem: some MosaicLayoutComponent,
        count: Int,
        interItemSpacing: CGFloat? = nil,
        contentInsets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        let group = NSCollectionLayoutGroup.mosaicVertical(
            layoutSize: .init(widthDimension: width, heightDimension: height),
            repeating: subitem.layoutItem,
            count: max(count, 1)
        )
        group.interItemSpacing = interItemSpacing.map(NSCollectionLayoutSpacing.fixed)
        group.contentInsets = contentInsets
        return Self(group)
    }
}

@MainActor
@resultBuilder
public enum MosaicLayoutItemsBuilder {
    public static func buildBlock(_ components: [NSCollectionLayoutItem]...) -> [NSCollectionLayoutItem] {
        components.flatMap(\.self)
    }

    public static func buildEither(first component: [NSCollectionLayoutItem]) -> [NSCollectionLayoutItem] {
        component
    }

    public static func buildEither(second component: [NSCollectionLayoutItem]) -> [NSCollectionLayoutItem] {
        component
    }

    public static func buildOptional(_ component: [NSCollectionLayoutItem]?) -> [NSCollectionLayoutItem] {
        component ?? []
    }

    public static func buildArray(_ components: [[NSCollectionLayoutItem]]) -> [NSCollectionLayoutItem] {
        components.flatMap(\.self)
    }

    public static func buildExpression(_ expression: some MosaicLayoutComponent) -> [NSCollectionLayoutItem] {
        [expression.layoutItem]
    }

    public static func buildExpression(
        _ expression: [some MosaicLayoutComponent]
    ) -> [NSCollectionLayoutItem] {
        expression.map(\.layoutItem)
    }

    public static func buildLimitedAvailability(
        _ component: [NSCollectionLayoutItem]
    ) -> [NSCollectionLayoutItem] {
        component
    }
}

@MainActor
@resultBuilder
public enum MosaicLayoutGroupBuilder {
    public static func buildBlock(_ component: MosaicLayoutGroup) -> MosaicLayoutGroup {
        component
    }

    public static func buildExpression(_ expression: MosaicLayoutGroup) -> MosaicLayoutGroup {
        expression
    }
}

public extension MosaicLayout {
    @MainActor
    static func section(_ group: MosaicLayoutGroup) -> Self {
        Self(NSCollectionLayoutSection(group: group.layoutGroup))
    }

    @MainActor
    static func section(@MosaicLayoutGroupBuilder group: () -> MosaicLayoutGroup) -> Self {
        section(group())
    }

    func configured(_ configure: @escaping @MainActor (NSCollectionLayoutSection) -> Void) -> Self {
        let baseSizeProvider = sizeProvider
        let baseEnvironmentProvider = environmentProvider

        return Self(
            sizeProvider: { effectiveContentSize in
                let section = baseSizeProvider(effectiveContentSize)
                configure(section)
                return section
            },
            environmentProvider: { items, itemProvider, deleteHandler, environment in
                let section = baseEnvironmentProvider(items, itemProvider, deleteHandler, environment)
                configure(section)
                return section
            },
            decorationRegistrations: decorationRegistrations,
            suppliesSwipeActionsViaListConfiguration: suppliesSwipeActionsViaListConfiguration
        )
    }

    func contentInsets(_ insets: NSDirectionalEdgeInsets) -> Self {
        configured { section in
            section.contentInsets = insets
        }
    }

    func interGroupSpacing(_ spacing: CGFloat) -> Self {
        configured { section in
            section.interGroupSpacing = spacing
        }
    }

    func orthogonalScrollingBehavior(_ behavior: MosaicSectionOrthogonalScrollingBehavior) -> Self {
        configured { section in
            section.orthogonalScrollingBehavior = behavior
        }
    }

    func boundarySupplementaryItems(_ items: [NSCollectionLayoutBoundarySupplementaryItem]) -> Self {
        configured { section in
            let replacedElementKinds = Set(items.map(\.elementKind))
            section.boundarySupplementaryItems = section.boundarySupplementaryItems.filter {
                !replacedElementKinds.contains($0.elementKind)
            } + items
        }
    }

    @MainActor
    func sectionHeader(
        height: NSCollectionLayoutDimension = .estimated(44),
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        alignment: NSRectAlignment = .top,
        absoluteOffset: CGPoint = .zero,
        pinToVisibleBounds: Bool = false,
        extendsBoundary: Bool = false
    ) -> Self {
        boundarySupplementaryItems([
            .mosaicBoundarySupplementaryItem(
                elementKind: MosaicCollectionView.elementKindSectionHeader,
                width: width,
                height: height,
                alignment: alignment,
                absoluteOffset: absoluteOffset,
                pinToVisibleBounds: pinToVisibleBounds,
                extendsBoundary: extendsBoundary
            ),
        ])
    }

    @MainActor
    func sectionFooter(
        height: NSCollectionLayoutDimension = .estimated(44),
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        alignment: NSRectAlignment = .bottom,
        absoluteOffset: CGPoint = .zero,
        pinToVisibleBounds: Bool = false,
        extendsBoundary: Bool = false
    ) -> Self {
        boundarySupplementaryItems([
            .mosaicBoundarySupplementaryItem(
                elementKind: MosaicCollectionView.elementKindSectionFooter,
                width: width,
                height: height,
                alignment: alignment,
                absoluteOffset: absoluteOffset,
                pinToVisibleBounds: pinToVisibleBounds,
                extendsBoundary: extendsBoundary
            ),
        ])
    }
}

public extension NSCollectionLayoutBoundarySupplementaryItem {
    @MainActor
    static func mosaicBoundarySupplementaryItem(
        elementKind: String,
        width: NSCollectionLayoutDimension = .fractionalWidth(1.0),
        height: NSCollectionLayoutDimension = .estimated(44),
        alignment: NSRectAlignment,
        absoluteOffset: CGPoint = .zero,
        pinToVisibleBounds: Bool = false,
        extendsBoundary: Bool = false
    ) -> NSCollectionLayoutBoundarySupplementaryItem {
        let item = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: width, heightDimension: height),
            elementKind: elementKind,
            alignment: alignment,
            absoluteOffset: absoluteOffset
        )
        item.pinToVisibleBounds = pinToVisibleBounds
        item.extendsBoundary = extendsBoundary
        return item
    }
}
