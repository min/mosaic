#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
@_spi(MosaicTesting)
public struct SectionResolution {
    public let id: MosaicIdentifier
    public let layout: MosaicLayout
    public let items: [MosaicItem]
    public let supplementaryViews: [MosaicSupplementaryView]

    private let supplementaryViewsByElementKind: [String: MosaicSupplementaryView]

    init(
        id: MosaicIdentifier,
        layout: MosaicLayout,
        items: [MosaicItem],
        supplementaryViews: [MosaicSupplementaryView] = []
    ) {
        self.id = id
        self.layout = layout
        self.items = items
        self.supplementaryViews = supplementaryViews
        supplementaryViewsByElementKind = Dictionary(
            uniqueKeysWithValues: supplementaryViews.map { supplementaryView in
                (supplementaryView.elementKind, supplementaryView)
            }
        )
    }

    func supplementaryView(elementKind: String) -> MosaicSupplementaryView? {
        supplementaryViewsByElementKind[elementKind]
    }
}

@MainActor
struct DiffableState {
    static let empty = Self(sections: [], itemsById: [:])

    let sections: [SectionResolution]
    let itemsById: [MosaicIdentifier: MosaicItem]

    private let sectionIndicesById: [MosaicIdentifier: Int]

    init(
        sections: [SectionResolution],
        itemsById: [MosaicIdentifier: MosaicItem]
    ) {
        self.sections = sections
        self.itemsById = itemsById
        sectionIndicesById = Dictionary(
            uniqueKeysWithValues: sections.enumerated().map { offset, section in
                (section.id, offset)
            }
        )
    }

    func section(at index: Int) -> SectionResolution? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    func section(id: MosaicIdentifier) -> SectionResolution? {
        guard let index = sectionIndicesById[id] else { return nil }
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    func item(id: MosaicIdentifier) -> MosaicItem? {
        itemsById[id]
    }

    func deletingItem(id: MosaicIdentifier) -> Self {
        guard let sectionItemId = id.sectionItemIdentifier else { return self }

        var updatedItemsById = itemsById
        updatedItemsById.removeValue(forKey: id)

        guard let section = section(id: MosaicIdentifier(sectionItemId.sectionId)),
              let sectionIndex = sectionIndicesById[section.id] else
        {
            return Self(sections: sections, itemsById: updatedItemsById)
        }

        var updatedSections = sections
        updatedSections[sectionIndex] = SectionResolution(
            id: section.id,
            layout: section.layout,
            items: section.items.filter { $0.id != sectionItemId.itemId },
            supplementaryViews: section.supplementaryViews
        )
        return Self(sections: updatedSections, itemsById: updatedItemsById)
    }
}

@MainActor
struct SnapshotBuildResult {
    var snapshot = NSDiffableDataSourceSnapshot<MosaicIdentifier, MosaicIdentifier>()
    var state = DiffableState.empty
    var reconfigureIds: [MosaicIdentifier] = []
}

extension MosaicView {
    func resolvedLayoutItem(at indexPath: IndexPath) -> MosaicItem? {
        if let itemId = itemIdentifier(at: indexPath),
           let item = resolvedItem(id: itemId)
        {
            return item
        }
        if let resolvedSection = resolvedSection(at: indexPath.section),
           resolvedSection.items.indices.contains(indexPath.item)
        {
            return resolvedSection.items[indexPath.item]
        }
        return nil
    }

    func itemIdentifier(at indexPath: IndexPath) -> MosaicIdentifier? {
        dataSource.itemIdentifier(for: indexPath)
    }

    func applyReloadSnapshot(_ result: SnapshotBuildResult, completion: (() -> Void)?) {
        currentState = result.state
        pendingState = nil
        previousState = nil
        pendingGenerationCount = nil
        displayedSectionIdentifiers = result.snapshot.sectionIdentifiers
        dataSource.mosaicApplyUsingReloadData(result.snapshot) { [weak self] in
            self?.notifyDidReconfigure(itemIds: result.reconfigureIds)
            self?.reconfigureVisibleSupplementaryViews()
            completion?()
        }
    }

    func applyAnimatedSnapshot(
        _ result: SnapshotBuildResult,
        animate: Bool,
        generation: Int,
        completion: (() -> Void)?
    ) {
        pendingState = result.state
        pendingGenerationCount = generation
        displayedSectionIdentifiers = result.snapshot.sectionIdentifiers

        dataSource.apply(result.snapshot, animatingDifferences: animate) { [weak self] in
            guard let self else { return }
            let isLatestGeneration = pendingGenerationCount == generation
            completeTransition(
                to: result.state,
                generation: generation,
                reconfigureIds: result.reconfigureIds
            )
            if isLatestGeneration {
                completion?()
            }
        }
    }

    func completeTransition(
        to state: DiffableState,
        generation: Int,
        reconfigureIds: [MosaicIdentifier]
    ) {
        previousState = currentState
        currentState = state

        if pendingGenerationCount == generation {
            pendingState = nil
            pendingGenerationCount = nil
        }

        notifyDidReconfigure(itemIds: reconfigureIds)
        reconfigureVisibleSupplementaryViews()
        clearPreviousState(after: generation)
    }

    func clearPreviousState(after generation: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self, transitionGenerationCount == generation else { return }
            previousState = nil
        }
    }

    /// Re-renders items whose content changed while their identity stayed stable,
    /// then notifies them.
    ///
    /// UIKit has already re-run `configure` via the snapshot's
    /// `reconfigureItems`, so this only fires the `didReconfigure` callback.
    /// AppKit has no snapshot reconfiguration, so the visible cell is
    /// reconfigured here instead — same in-place update, same callback order,
    /// and the cell is never torn down.
    func notifyDidReconfigure(itemIds: [MosaicIdentifier]) {
        guard !itemIds.isEmpty else { return }

        for itemId in itemIds {
            guard let indexPath = dataSource.indexPath(for: itemId),
                  let cell = collectionView.mosaicCell(at: indexPath),
                  let item = resolvedItem(id: itemId) else { continue }

            if !MosaicPlatformCapabilities.hasSnapshotReconfiguration {
                item.configure(cell, item.value)
            }
            item.didReconfigure?(cell, item.value)
        }
    }

    func reconfigureVisibleSupplementaryViews() {
        for (sectionIndex, sectionId) in displayedSectionIdentifiers.enumerated() {
            guard let section = resolvedSection(id: sectionId) else { continue }

            for supplementaryView in section.supplementaryViews {
                let visibleViews = collectionView.mosaicVisibleSupplementaryViews(
                    ofKind: supplementaryView.elementKind
                )
                for (indexPath, view) in visibleViews where indexPath.section == sectionIndex {
                    supplementaryView.configure(view, supplementaryView.value)
                }
            }
        }
    }
}
