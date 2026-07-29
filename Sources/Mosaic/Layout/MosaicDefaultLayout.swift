#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Built-in layout helpers for `MosaicView`.
public enum MosaicDefaultLayout {
    /// A list section built from the platform's list configuration.
    ///
    /// AppKit has no `UICollectionLayoutListConfiguration`, so on macOS this
    /// resolves to the plain compositional list below: `style` and the
    /// swipe-action providers have no AppKit counterpart and are ignored.
    @MainActor
    public static func list(
        style: MosaicListStyle = .plain,
        using environment: any NSCollectionLayoutEnvironment,
        itemProvider: @escaping (IndexPath) -> MosaicItem? = { _ in nil },
        deleteHandler: @escaping (IndexPath, @escaping () -> Void) -> Void = { _, done in done() }
    ) -> NSCollectionLayoutSection {
        #if canImport(UIKit)
        var configuration = UICollectionLayoutListConfiguration(appearance: style.appearance)
        configuration.leadingSwipeActionsConfigurationProvider = { indexPath in
            swipeActionsConfiguration(
                at: indexPath,
                itemProvider: itemProvider,
                deleteHandler: deleteHandler,
                keyPath: \.leadingSwipeActionsConfiguration
            )?.uiKitConfiguration()
        }
        configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
            swipeActionsConfiguration(
                at: indexPath,
                itemProvider: itemProvider,
                deleteHandler: deleteHandler,
                keyPath: \.trailingSwipeActionsConfiguration
            )?.uiKitConfiguration()
        }
        return .list(using: configuration, layoutEnvironment: environment)
        #else
        _ = (style, itemProvider, deleteHandler)
        return list()
        #endif
    }

    @MainActor
    @_spi(MosaicTesting)
    public static func swipeActionsConfiguration(
        at indexPath: IndexPath,
        itemProvider: (IndexPath) -> MosaicItem?,
        deleteHandler: @escaping (IndexPath, @escaping () -> Void) -> Void,
        keyPath: KeyPath<MosaicItem, (@MainActor (Any) -> MosaicSwipeActionsConfiguration?)?>
    ) -> MosaicSwipeActionsConfiguration? {
        guard let item = itemProvider(indexPath) else { return nil }
        guard let config = item[keyPath: keyPath]?(item.value) else { return nil }

        // Destructive actions delete the item from the snapshot first, then run
        // the original handler once the delete animation finishes. This lets
        // UIKit tear down the swipe-action decoration while the swipe
        // occurrence is still active.
        return config.deletingBeforeDestructiveActions { done in
            deleteHandler(indexPath, done)
        }
    }

    /// A simple vertically scrolling list layout with estimated row height.
    @MainActor
    public static func list() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            ),
            subitems: [item]
        )
        return NSCollectionLayoutSection(group: group)
    }

    /// A simple multi-column waterfall grid backed by compositional layout.
    @MainActor
    public static func waterfall(
        columns: Int = 2,
        spacing: CGFloat = 8,
        interItemSpacing: CGFloat = 0,
        insets: NSDirectionalEdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8),
        estimatedHeight: CGFloat = 100
    ) -> NSCollectionLayoutSection {
        let safeColumns = max(columns, 1)
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0 / CGFloat(safeColumns)),
                heightDimension: .estimated(estimatedHeight)
            )
        )

        let group = NSCollectionLayoutGroup.mosaicHorizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(estimatedHeight)
            ),
            repeating: item,
            count: safeColumns
        )
        group.interItemSpacing = .fixed(interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = insets
        section.interGroupSpacing = spacing
        return section
    }
}
