#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import SwiftUI

// MARK: - Platform vocabulary

//
// Mosaic presents one API surface on both platforms. UIKit and AppKit agree on
// the whole `NSCollectionLayout*` family and on diffable data sources, so the
// model, layout DSL and diffing logic are shared verbatim. The types that differ
// are aliased here so the rest of the package never spells a platform type
// directly.
//
// On iOS these aliases resolve to the UIKit types they always were, so existing
// call sites keep compiling unchanged: a cell declared as `UICollectionViewCell`
// still satisfies `MosaicCell`.

#if canImport(UIKit)

/// The platform's base view type: `UIView` on iOS, `NSView` on macOS.
public typealias MosaicPlatformView = UIView

/// The platform's colour type.
public typealias MosaicPlatformColor = UIColor

/// The platform's image type.
public typealias MosaicPlatformImage = UIImage

/// The platform's collection view: `UICollectionView` on iOS, `NSCollectionView` on macOS.
public typealias MosaicCollectionView = UICollectionView

/// The base class for cells displayed by Mosaic.
///
/// `UICollectionViewCell` on iOS. On macOS this is a Mosaic-owned
/// `NSCollectionViewItem` subclass, because `NSCollectionViewItem` is a view
/// *controller* and cannot be instantiated without a nib unless `loadView()`
/// is overridden.
public typealias MosaicCell = UICollectionViewCell

/// The base class for cells displayed in list sections.
///
/// AppKit has no `UICollectionViewListCell` equivalent, so on macOS this is the
/// same type as `MosaicCell`.
public typealias MosaicListCell = UICollectionViewListCell

/// The base class for supplementary and decoration views.
public typealias MosaicReusableView = UICollectionReusableView

/// The platform's compositional layout type.
public typealias MosaicCompositionalLayout = UICollectionViewCompositionalLayout

/// The platform's diffable data source type.
public typealias MosaicDiffableDataSource = UICollectionViewDiffableDataSource

/// The platform's orthogonal scrolling behaviour enum.
public typealias MosaicSectionOrthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior

#else

public typealias MosaicPlatformView = NSView
public typealias MosaicPlatformColor = NSColor
public typealias MosaicPlatformImage = NSImage
public typealias MosaicCollectionView = NSCollectionView
public typealias MosaicCompositionalLayout = NSCollectionViewCompositionalLayout
public typealias MosaicDiffableDataSource = NSCollectionViewDiffableDataSource
public typealias MosaicSectionOrthogonalScrollingBehavior = NSCollectionLayoutSectionOrthogonalScrollingBehavior

/// AppKit counterpart of `UICollectionViewCell`.
///
/// `NSCollectionViewItem` is an `NSViewController`, so a programmatically
/// registered subclass must supply its own root view; the default `loadView()`
/// looks for a nib named after the class and raises when there isn't one.
/// Overriding it here means every Mosaic cell — including the fallback cell —
/// is safe to instantiate without a nib.
open class MosaicCell: NSCollectionViewItem {
    override open func loadView() {
        view = NSView()
    }
}

public typealias MosaicListCell = MosaicCell

/// AppKit counterpart of `UICollectionReusableView`.
open class MosaicReusableView: NSView, NSCollectionViewElement {}

#endif

// MARK: - Capabilities

/// Which collection-view features the current platform provides.
///
/// Mosaic exposes the same API everywhere; a handful of behaviours have no
/// AppKit counterpart and are accepted but inert there. These flags name those
/// differences so callers and tests can reason about them without spelling
/// `#if canImport(UIKit)` at every site.
public enum MosaicPlatformCapabilities {
    /// Whether `UICollectionLayoutListConfiguration` is available — list
    /// appearances, row separators, and configuration-served swipe actions.
    public static var hasListConfiguration: Bool {
        #if canImport(UIKit)
        true
        #else
        false
        #endif
    }

    /// Whether cells can present swipe actions.
    ///
    /// `false` on macOS: swipe configurations and `onDelete(_:)` are stored but
    /// never invoked, since `NSCollectionView` has no swipe affordance.
    public static var hasSwipeActions: Bool {
        hasListConfiguration
    }

    /// Whether the diffable data source supports interactive reordering.
    ///
    /// `false` on macOS: `NSCollectionViewDiffableDataSource` has no
    /// `reorderingHandlers`, so `canReorderSectionItem` and
    /// `onSectionItemsReordered` are stored but never invoked.
    public static var hasInteractiveReordering: Bool {
        hasListConfiguration
    }

    /// Whether snapshots support in-place `reconfigureItems`.
    ///
    /// `false` on macOS, where `MosaicView` re-runs each item's `configure`
    /// closure against the visible cell instead. The observable contract —
    /// update in place, never tear the cell down — is the same either way.
    public static var hasSnapshotReconfiguration: Bool {
        hasListConfiguration
    }
}

// MARK: - Cell content

extension MosaicCell {
    /// The view that holds an item's content.
    ///
    /// `contentView` on iOS; the item's root `view` on macOS.
    var mosaicContentView: MosaicPlatformView {
        #if canImport(UIKit)
        contentView
        #else
        view
        #endif
    }
}

/// Installs SwiftUI content into a cell.
///
/// iOS uses `UIHostingConfiguration`, which works on any cell. macOS has no
/// equivalent, so the content is hosted in an `NSHostingView` pinned to the
/// cell's root view — reused across reconfigurations by looking for the hosting
/// view already installed, which keeps the SwiftUI state alive exactly as
/// `UIHostingConfiguration` does.
@MainActor
func mosaicSetHostedContent(_ content: some View, on cell: MosaicCell) {
    #if canImport(UIKit)
    cell.contentConfiguration = UIHostingConfiguration { content }
        .margins(.all, 0)
    #else
    let container = cell.mosaicContentView
    if let existing = container.subviews.lazy.compactMap({ $0 as? NSHostingView<AnyView> }).first {
        existing.rootView = AnyView(content)
        return
    }

    let hostingView = NSHostingView(rootView: AnyView(content))
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(hostingView)
    NSLayoutConstraint.activate([
        hostingView.topAnchor.constraint(equalTo: container.topAnchor),
        hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
    ])
    #endif
}

// MARK: - Collection view

extension MosaicCollectionView {
    func mosaicRegister(cellType: MosaicCell.Type, reuseIdentifier: String) {
        #if canImport(UIKit)
        register(cellType, forCellWithReuseIdentifier: reuseIdentifier)
        #else
        register(cellType, forItemWithIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier))
        #endif
    }

    func mosaicDequeueCell(reuseIdentifier: String, for indexPath: IndexPath) -> MosaicCell {
        #if canImport(UIKit)
        // UIKit guarantees a registered reuse identifier dequeues a cell.
        dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        #else
        // A registered class always makes an item; the cast holds because
        // registration only ever accepts `MosaicCell` subclasses.
        makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier),
            for: indexPath
        ) as? MosaicCell ?? MosaicCell()
        #endif
    }

    func mosaicRegister(
        supplementaryViewType: MosaicReusableView.Type,
        ofKind elementKind: String,
        reuseIdentifier: String
    ) {
        #if canImport(UIKit)
        register(
            supplementaryViewType,
            forSupplementaryViewOfKind: elementKind,
            withReuseIdentifier: reuseIdentifier
        )
        #else
        register(
            supplementaryViewType,
            forSupplementaryViewOfKind: elementKind,
            withIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier)
        )
        #endif
    }

    func mosaicDequeueSupplementaryView(
        ofKind elementKind: String,
        reuseIdentifier: String,
        for indexPath: IndexPath
    ) -> MosaicReusableView? {
        #if canImport(UIKit)
        dequeueReusableSupplementaryView(
            ofKind: elementKind,
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as? MosaicReusableView
        #else
        makeSupplementaryView(
            ofKind: elementKind,
            withIdentifier: NSUserInterfaceItemIdentifier(reuseIdentifier),
            for: indexPath
        ) as? MosaicReusableView
        #endif
    }

    /// The cell currently displayed at `indexPath`, without dequeuing one.
    func mosaicCell(at indexPath: IndexPath) -> MosaicCell? {
        #if canImport(UIKit)
        cellForItem(at: indexPath)
        #else
        item(at: indexPath) as? MosaicCell
        #endif
    }

    /// Visible supplementary views of `elementKind`, paired with their index paths.
    func mosaicVisibleSupplementaryViews(
        ofKind elementKind: String
    ) -> [(indexPath: IndexPath, view: MosaicReusableView)] {
        #if canImport(UIKit)
        visibleSupplementaryViews(ofKind: elementKind).compactMap { view in
            guard let indexPath = indexPath(forSupplementaryView: view) else { return nil }
            return (indexPath, view)
        }
        #else
        indexPathsForVisibleSupplementaryElements(ofKind: elementKind).compactMap { indexPath in
            guard let view = supplementaryView(forElementKind: elementKind, at: indexPath) as? MosaicReusableView else { return nil }
            return (indexPath, view)
        }
        #endif
    }
}

// MARK: - Diffable data source

extension MosaicDiffableDataSource {
    /// Applies a snapshot without diffing or animation.
    ///
    /// AppKit has no `applySnapshotUsingReloadData`; a non-animated `apply` is
    /// the closest equivalent.
    func mosaicApplyUsingReloadData(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        completion: (() -> Void)?
    ) {
        #if canImport(UIKit)
        applySnapshotUsingReloadData(snapshot, completion: completion)
        #else
        apply(snapshot, animatingDifferences: false, completion: completion)
        #endif
    }
}

extension NSDiffableDataSourceSnapshot {
    /// Marks items for in-place reconfiguration where the platform supports it.
    ///
    /// `reconfigureItems` is UIKit-only. On macOS this is a no-op and
    /// `MosaicView` instead re-runs each item's `configure` closure against
    /// the already-visible cell, which preserves the same "update in place,
    /// never tear the cell down" contract.
    mutating func mosaicReconfigureItems(_ identifiers: [ItemIdentifierType]) {
        #if canImport(UIKit)
        reconfigureItems(identifiers)
        #endif
    }
}

// MARK: - Layout shims

#if !canImport(UIKit)
public extension NSDirectionalEdgeInsets {
    /// UIKit ships this convenience; AppKit does not.
    static let zero = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}
#endif

extension NSCollectionLayoutGroup {
    /// A horizontal group repeating `subitem` `count` times.
    ///
    /// AppKit only exposes the deprecated-on-iOS `subitem:count:` spelling.
    @MainActor
    static func mosaicHorizontal(
        layoutSize: NSCollectionLayoutSize,
        repeating subitem: NSCollectionLayoutItem,
        count: Int
    ) -> NSCollectionLayoutGroup {
        #if canImport(UIKit)
        horizontal(layoutSize: layoutSize, repeatingSubitem: subitem, count: count)
        #else
        horizontal(layoutSize: layoutSize, subitem: subitem, count: count)
        #endif
    }

    /// A vertical group repeating `subitem` `count` times.
    @MainActor
    static func mosaicVertical(
        layoutSize: NSCollectionLayoutSize,
        repeating subitem: NSCollectionLayoutItem,
        count: Int
    ) -> NSCollectionLayoutGroup {
        #if canImport(UIKit)
        vertical(layoutSize: layoutSize, repeatingSubitem: subitem, count: count)
        #else
        vertical(layoutSize: layoutSize, subitem: subitem, count: count)
        #endif
    }
}
