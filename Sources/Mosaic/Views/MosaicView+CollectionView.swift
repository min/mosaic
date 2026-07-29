#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)

extension MosaicView: UICollectionViewDelegate {
    private func section(at indexPath: IndexPath) -> SectionResolution? {
        resolvedSection(at: indexPath.section)
    }

    public func collectionView(_: MosaicCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        resolvedItem(at: indexPath) != nil
    }

    public func collectionView(_: MosaicCollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.didHighlightItemAt?()
    }

    public func collectionView(_: MosaicCollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.didUnhighlightItemAt?()
    }

    public func collectionView(_: MosaicCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = resolvedItem(at: indexPath) else { return false }
        return item.shouldSelectItemAt?() ?? true
    }

    public func collectionView(
        _: MosaicCollectionView,
        willDisplay cell: MosaicCell,
        forItemAt indexPath: IndexPath
    ) {
        willDisplay(cell, at: indexPath)
    }

    public func collectionView(
        _: MosaicCollectionView,
        didEndDisplaying cell: MosaicCell,
        forItemAt indexPath: IndexPath
    ) {
        didEndDisplaying(cell, at: indexPath)
    }

    public func collectionView(_: MosaicCollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.didSelectItemAt?()
    }

    public func collectionView(_: MosaicCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let item = resolvedItem(at: indexPath) else { return false }
        return item.shouldDeselectItemAt?() ?? true
    }

    public func collectionView(_: MosaicCollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.didDeselectItemAt?()
    }

    public func collectionView(
        _: MosaicCollectionView,
        leadingSwipeActionsConfigurationForItemAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if section(at: indexPath)?.layout.suppliesSwipeActionsViaListConfiguration == true {
            return nil
        }
        guard let item = resolvedItem(at: indexPath) else { return nil }
        return item.leadingSwipeActionsConfiguration?(item.value)?.uiKitConfiguration()
    }

    public func collectionView(
        _: MosaicCollectionView,
        trailingSwipeActionsConfigurationForItemAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if section(at: indexPath)?.layout.suppliesSwipeActionsViaListConfiguration == true {
            return nil
        }
        guard let item = resolvedItem(at: indexPath) else { return nil }
        return item.trailingSwipeActionsConfiguration?(item.value)?.uiKitConfiguration()
    }
}

extension MosaicView: UICollectionViewDataSourcePrefetching {
    public func collectionView(_: MosaicCollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        prefetchItems(at: indexPaths)
    }

    public func collectionView(_: MosaicCollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        cancelPrefetchingItems(at: indexPaths)
    }
}

#else

extension MosaicView: NSCollectionViewDelegate {
    public func collectionView(
        _: MosaicCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let cell = item as? MosaicCell else { return }
        willDisplay(cell, at: indexPath)
    }

    public func collectionView(
        _: MosaicCollectionView,
        didEndDisplaying item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let cell = item as? MosaicCell else { return }
        didEndDisplaying(cell, at: indexPath)
    }

    /// AppKit asks about a whole set of index paths at once and expects the
    /// permitted subset back, where UIKit asks one at a time for a Bool.
    public func collectionView(
        _: MosaicCollectionView,
        shouldSelectItemsAt indexPaths: Set<IndexPath>
    ) -> Set<IndexPath> {
        indexPaths.filter { indexPath in
            guard let item = resolvedItem(at: indexPath) else { return false }
            return item.shouldSelectItemAt?() ?? true
        }
    }

    public func collectionView(_: MosaicCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            resolvedItem(at: indexPath)?.didSelectItemAt?()
        }
    }

    public func collectionView(
        _: MosaicCollectionView,
        shouldDeselectItemsAt indexPaths: Set<IndexPath>
    ) -> Set<IndexPath> {
        indexPaths.filter { indexPath in
            guard let item = resolvedItem(at: indexPath) else { return false }
            return item.shouldDeselectItemAt?() ?? true
        }
    }

    public func collectionView(_: MosaicCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            resolvedItem(at: indexPath)?.didDeselectItemAt?()
        }
    }

    public func collectionView(
        _: MosaicCollectionView,
        shouldChangeItemsAt indexPaths: Set<IndexPath>,
        to _: NSCollectionViewItem.HighlightState
    ) -> Set<IndexPath> {
        indexPaths.filter { resolvedItem(at: $0) != nil }
    }

    /// AppKit models highlight as one state transition rather than the paired
    /// didHighlight/didUnhighlight callbacks UIKit delivers.
    public func collectionView(
        _: MosaicCollectionView,
        didChangeItemsAt indexPaths: Set<IndexPath>,
        to highlightState: NSCollectionViewItem.HighlightState
    ) {
        for indexPath in indexPaths {
            guard let item = resolvedItem(at: indexPath) else { continue }
            if highlightState == .none {
                item.didUnhighlightItemAt?()
            } else {
                item.didHighlightItemAt?()
            }
        }
    }
}

extension MosaicView: NSCollectionViewPrefetching {
    public func collectionView(_: MosaicCollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        prefetchItems(at: indexPaths)
    }

    public func collectionView(_: MosaicCollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        cancelPrefetchingItems(at: indexPaths)
    }
}

#endif
