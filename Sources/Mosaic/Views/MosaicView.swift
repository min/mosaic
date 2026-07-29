#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// A view encapsulating a `MosaicCollectionView` configured to work with `MosaicModel`.
///
/// `MosaicView` owns the collection view, its diffable data source, and
/// orchestrates the diffing and reconfiguration logic. It should be added as
/// a subview of your view controller's root view. Update the view by calling
/// `apply(_:animate:)` with a new `MosaicModel` whenever the underlying
/// data changes.
public final class MosaicView: MosaicPlatformView {
    // MARK: - Private properties

    var currentState = DiffableState.empty
    var pendingState: DiffableState?
    var previousState: DiffableState?
    private let cellProvider = MosaicCellProvider()
    private var registeredSupplementaryReuseIds: Set<SupplementaryReuseIdentifier> = []
    private var registeredDecorationRegistrations: Set<MosaicDecorationRegistration> = []
    var displayedSectionIdentifiers: [MosaicIdentifier] = []
    var transitionGenerationCount = 0
    var pendingGenerationCount: Int?
    private lazy var layout: MosaicCompositionalLayout =
        MosaicCompositionalLayout { [weak self] index, environment in
            guard let self else { return MosaicDefaultLayout.list(using: environment) }
            guard let resolvedSection = resolvedSection(at: index) else {
                return MosaicDefaultLayout.list(using: environment)
            }
            return resolvedSection.layout.environmentProvider(
                resolvedSection.items,
                { [weak self] indexPath in
                    self?.resolvedLayoutItem(at: indexPath)
                },
                { [weak self] indexPath, completion in
                    self?.deleteItem(at: indexPath, completion: completion)
                },
                environment
            )
        }

    #if canImport(UIKit)
    /// The underlying collection view. Exposed to allow additional
    /// configuration if needed (e.g. background views, delegate
    /// customization). In normal usage you should not assign a custom
    /// dataSource.
    public lazy var collectionView: MosaicCollectionView = .init(
        frame: .zero, collectionViewLayout: layout
    )
    #else
    /// The underlying collection view. Exposed to allow additional
    /// configuration if needed (e.g. background views, delegate
    /// customization). In normal usage you should not assign a custom
    /// dataSource.
    public lazy var collectionView: MosaicCollectionView = {
        let collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        // AppKit defaults to non-selectable, which would suppress every
        // selection delegate callback Mosaic forwards to items.
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.clear]
        return collectionView
    }()

    /// The scroll view hosting `collectionView`.
    ///
    /// `NSCollectionView` is not itself a scroll view, so Mosaic embeds it in an
    /// `NSScrollView`. On iOS the collection view *is* the scroll view, and this
    /// property does not exist.
    public lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = collectionView
        return scrollView
    }()
    #endif

    lazy var dataSource:
        MosaicDiffableDataSource<MosaicIdentifier, MosaicIdentifier> =
        makeDataSource()

    /// Optional predicate for determining whether a section item can reorder.
    public var canReorderSectionItem: ((AnyHashable, AnyHashable) -> Bool)? {
        didSet { configureReorderingHandlers() }
    }

    /// Callback invoked after items in a section are reordered.
    public var onSectionItemsReordered: ((AnyHashable, [AnyHashable]) -> Void)? {
        didSet { configureReorderingHandlers() }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Private helpers

    private func setup() {
        // On iOS the collection view scrolls itself; on macOS it is the
        // document view of an enclosing scroll view.
        #if canImport(UIKit)
        let scrollingView: MosaicPlatformView = collectionView
        #else
        let scrollingView: MosaicPlatformView = scrollView
        #endif

        addSubview(scrollingView)
        scrollingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollingView.topAnchor.constraint(equalTo: topAnchor),
            scrollingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        #if canImport(UIKit)
        collectionView.keyboardDismissMode = .interactive
        #endif
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        configureReorderingHandlers()
    }

    private func makeDataSource() -> MosaicDiffableDataSource<MosaicIdentifier, MosaicIdentifier> {
        let cellProvider = cellProvider
        let dataSource = MosaicDiffableDataSource<MosaicIdentifier, MosaicIdentifier>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemId in
            cellProvider.cell(in: collectionView, at: indexPath, itemId: itemId)
        }
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath
            -> MosaicReusableView? in
            guard let self else { return nil }
            guard let supplementaryView = resolvedSupplementaryView(
                ofKind: elementKind,
                atSection: indexPath.section
            ) else { return nil }

            let supplementaryReuseIdentifier = supplementaryView.reuseIdentifier ?? String(
                describing: supplementaryView.viewType
            )
            let reuseKey = SupplementaryReuseIdentifier(
                elementKind: elementKind,
                reuseIdentifier: supplementaryReuseIdentifier
            )

            if !registeredSupplementaryReuseIds.contains(reuseKey) {
                collectionView.mosaicRegister(
                    supplementaryViewType: supplementaryView.viewType,
                    ofKind: elementKind,
                    reuseIdentifier: supplementaryReuseIdentifier
                )
                registeredSupplementaryReuseIds.insert(reuseKey)
            }

            guard let view = collectionView.mosaicDequeueSupplementaryView(
                ofKind: elementKind,
                reuseIdentifier: supplementaryReuseIdentifier,
                for: indexPath
            ) else { return nil }
            supplementaryView.configure(view, supplementaryView.value)
            return view
        }
        return dataSource
    }

    private func buildSnapshot(
        from newModel: MosaicModel,
        baselineState: DiffableState
    ) -> SnapshotBuildResult {
        var result = SnapshotBuildResult()
        var sections: [SectionResolution] = []
        var itemsById: [MosaicIdentifier: MosaicItem] = [:]
        sections.reserveCapacity(newModel.sections.count)

        for section in newModel.sections {
            let sectionIdentifier = MosaicIdentifier(section.id)
            let resolvedSection = SectionResolution(
                id: sectionIdentifier,
                layout: section.resolvedLayout,
                items: section.items,
                supplementaryViews: section.supplementaryViews
            )
            sections.append(resolvedSection)
            result.snapshot.appendSections([sectionIdentifier])

            for item in section.items {
                let compositeId = MosaicIdentifier(
                    SectionItemIdentifier(sectionId: section.id, itemId: item.id)
                )
                result.snapshot.appendItems([compositeId], toSection: sectionIdentifier)

                if let previousItem = baselineState.item(id: compositeId),
                   previousItem.contentHash != item.contentHash
                {
                    result.reconfigureIds.append(compositeId)
                }

                itemsById[compositeId] = item
            }
        }

        result.state = DiffableState(sections: sections, itemsById: itemsById)
        if !result.reconfigureIds.isEmpty {
            // No-op where the snapshot cannot reconfigure; `notifyDidReconfigure`
            // re-runs `configure` against the visible cell instead.
            result.snapshot.mosaicReconfigureItems(result.reconfigureIds)
        }

        return result
    }

    /// Wires interactive reordering into the diffable data source.
    ///
    /// `NSCollectionViewDiffableDataSource` has no `reorderingHandlers`, so on
    /// macOS `canReorderSectionItem` and `onSectionItemsReordered` are stored
    /// but never invoked. See `MosaicPlatformCapabilities.hasInteractiveReordering`.
    private func configureReorderingHandlers() {
        #if canImport(UIKit)
        dataSource.reorderingHandlers.canReorderItem = { [weak self] itemId in
            guard let self,
                  let sectionItem = itemId.sectionItemIdentifier else { return false }
            return canReorderSectionItem?(sectionItem.sectionId, sectionItem.itemId) ?? false
        }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self else { return }
            displayedSectionIdentifiers = transaction.finalSnapshot.sectionIdentifiers
            for sectionId in transaction.finalSnapshot.sectionIdentifiers {
                let finalItems = transaction.finalSnapshot.itemIdentifiers(inSection: sectionId)
                    .compactMap(\.sectionItemIdentifier?.itemId)
                let initialItems = transaction.initialSnapshot.itemIdentifiers(inSection: sectionId)
                    .compactMap(\.sectionItemIdentifier?.itemId)
                guard finalItems != initialItems else { continue }
                onSectionItemsReordered?(sectionId.anyHashable, finalItems)
            }
        }
        #endif
    }

    private func registerDecorations(sections: [MosaicSection]) {
        for registration in sections.flatMap(\.resolvedLayout.decorationRegistrations) {
            guard !registeredDecorationRegistrations.contains(registration) else { continue }
            layout.register(registration.viewClass, forDecorationViewOfKind: registration.elementKind)
            registeredDecorationRegistrations.insert(registration)
        }
    }

    // MARK: - Public API

    /// Applies a new model to the view, computing differences from the
    /// previously applied model. Items whose `id` remains stable but whose
    /// `contentHash` changes will be reconfigured rather than replaced.
    ///
    /// - Parameters:
    ///   - newModel: The model describing the new state of the collection.
    ///   - animate: Whether to animate inserts, deletes and moves.
    public func apply(_ newModel: MosaicModel, animate: Bool = true, completion: (() -> Void)? = nil) {
        transitionGenerationCount += 1
        let generation = transitionGenerationCount
        let prefersReloadData = !animate && newModel.sections.contains {
            $0.resolvedLayout.suppliesSwipeActionsViaListConfiguration
        }
        let baselineState = pendingState ?? currentState

        registerDecorations(sections: newModel.sections)
        let result = buildSnapshot(from: newModel, baselineState: baselineState)
        cellProvider.update(itemsById: result.state.itemsById)

        if prefersReloadData {
            applyReloadSnapshot(result, completion: completion)
            return
        }

        applyAnimatedSnapshot(
            result,
            animate: animate,
            generation: generation,
            completion: completion
        )
    }

    /// Immediately deletes a single item from the data-source snapshot.
    /// Called from swipe-action handlers so UIKit can tear down the
    /// swipe-action decoration while the swipe occurrence is still active.
    /// The completion handler fires after the deletion animation finishes.
    @_spi(MosaicTesting)
    public func deleteItem(at indexPath: IndexPath, completion: (() -> Void)? = nil) {
        guard let itemId = itemIdentifier(at: indexPath) else {
            completion?()
            return
        }

        transitionGenerationCount += 1
        let generation = transitionGenerationCount
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([itemId])
        let nextState = (pendingState ?? currentState).deletingItem(id: itemId)
        cellProvider.update(itemsById: nextState.itemsById)
        pendingState = nextState
        pendingGenerationCount = generation
        displayedSectionIdentifiers = snapshot.sectionIdentifiers

        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard let self else { return }
            completeTransition(
                to: nextState,
                generation: generation,
                reconfigureIds: []
            )
            completion?()
        }
    }
}

@MainActor
private final class MosaicCellProvider {
    private static let fallbackReuseIdentifier = "MosaicFallbackCell"

    private var itemsById: [MosaicIdentifier: MosaicItem] = [:]
    private var registeredReuseIds: Set<String> = []

    func update(itemsById: [MosaicIdentifier: MosaicItem]) {
        self.itemsById = itemsById
    }

    func cell(
        in collectionView: MosaicCollectionView,
        at indexPath: IndexPath,
        itemId: MosaicIdentifier
    ) -> MosaicCell {
        guard let item = itemsById[itemId] else {
            return fallbackCell(in: collectionView, at: indexPath)
        }

        let reuseIdentifier = item.reuseIdentifier ?? String(describing: item.cellType)
        register(cellType: item.cellType, reuseIdentifier: reuseIdentifier, in: collectionView)

        let cell = collectionView.mosaicDequeueCell(reuseIdentifier: reuseIdentifier, for: indexPath)
        item.configure(cell, item.value)
        return cell
    }

    /// A blank cell for an identifier with no backing item, which can happen
    /// briefly while a snapshot is in flight.
    private func fallbackCell(
        in collectionView: MosaicCollectionView,
        at indexPath: IndexPath
    ) -> MosaicCell {
        register(
            cellType: MosaicCell.self,
            reuseIdentifier: Self.fallbackReuseIdentifier,
            in: collectionView
        )
        let cell = collectionView.mosaicDequeueCell(
            reuseIdentifier: Self.fallbackReuseIdentifier,
            for: indexPath
        )
        #if canImport(UIKit)
        cell.contentConfiguration = nil
        cell.backgroundConfiguration = nil
        #endif
        return cell
    }

    private func register(
        cellType: MosaicCell.Type,
        reuseIdentifier: String,
        in collectionView: MosaicCollectionView
    ) {
        guard registeredReuseIds.insert(reuseIdentifier).inserted else { return }
        collectionView.mosaicRegister(cellType: cellType, reuseIdentifier: reuseIdentifier)
    }
}

private struct SupplementaryReuseIdentifier: Hashable {
    let elementKind: String
    let reuseIdentifier: String
}

public extension MosaicView {
    /// Returns the currently visible cell for an item identifier in a section, if one is visible.
    ///
    /// Item identifiers are scoped to their section in Mosaic, so both identifiers
    /// are required. This method never dequeues a cell.
    func visibleCell(
        itemId: AnyHashable,
        sectionId: AnyHashable
    ) -> MosaicCell? {
        let itemIdentifier = MosaicIdentifier(
            SectionItemIdentifier(sectionId: sectionId, itemId: itemId)
        )
        guard let indexPath = dataSource.indexPath(for: itemIdentifier) else { return nil }
        return collectionView.mosaicCell(at: indexPath)
    }

    @_spi(MosaicTesting)
    func resolvedSection(at index: Int) -> SectionResolution? {
        if let sectionId = displayedSectionIdentifiers[safe: index],
           let section = resolvedSection(id: sectionId)
        {
            return section
        }

        return pendingState?.section(at: index)
            ?? currentState.section(at: index)
            ?? previousState?.section(at: index)
    }

    @_spi(MosaicTesting)
    func resolvedSection(id: MosaicIdentifier) -> SectionResolution? {
        pendingState?.section(id: id)
            ?? currentState.section(id: id)
            ?? previousState?.section(id: id)
    }

    @_spi(MosaicTesting)
    func resolvedItem(id: MosaicIdentifier) -> MosaicItem? {
        pendingState?.item(id: id)
            ?? currentState.item(id: id)
            ?? previousState?.item(id: id)
    }

    @_spi(MosaicTesting)
    func resolvedSupplementaryView(
        ofKind elementKind: String,
        atSection sectionIndex: Int
    ) -> MosaicSupplementaryView? {
        resolvedSection(at: sectionIndex)?.supplementaryView(elementKind: elementKind)
    }

    internal func resolvedItem(at indexPath: IndexPath) -> MosaicItem? {
        guard let itemId = itemIdentifier(at: indexPath) else { return nil }
        return resolvedItem(id: itemId)
    }

    @_spi(MosaicTesting)
    var hasPendingTransition: Bool {
        pendingGenerationCount != nil
    }

    @_spi(MosaicTesting)
    func isDecorationRegistered(_ registration: MosaicDecorationRegistration) -> Bool {
        registeredDecorationRegistrations.contains(registration)
    }

    @_spi(MosaicTesting)
    func willDisplay(_ cell: MosaicCell, at indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.willDisplay?(cell, item.value)
    }

    @_spi(MosaicTesting)
    func didEndDisplaying(_ cell: MosaicCell, at indexPath: IndexPath) {
        guard let item = resolvedItem(at: indexPath) else { return }
        item.didEndDisplaying?(cell, item.value)
    }

    internal func prefetchItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let item = resolvedItem(at: indexPath) else { continue }
            item.prefetchItemAt?(item.value)
        }
    }

    internal func cancelPrefetchingItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let item = resolvedItem(at: indexPath) else { continue }
            item.cancelPrefetchingForItemAt?(item.value)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
