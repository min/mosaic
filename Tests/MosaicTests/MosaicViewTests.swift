@_spi(MosaicTesting) import MosaicCore
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

private struct SelectionResults {
    let shouldHighlight: Bool
    let shouldSelect: Bool
    let shouldDeselect: Bool
}

private final class TestDecorationView: MosaicReusableView {}

private final class TestSupplementaryView: MosaicReusableView {
    var renderedValue: String?
}

private final class TestHostedSupplementaryView: MosaicPlatformView {
    var renderedValue: String?
}

@MainActor
struct MosaicViewTests {
    @Test
    func mosaicViewAppliesSnapshotAndRunsDisplayHooks() async {
        var events: [String] = []
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let indexPath = IndexPath(item: 0, section: 0)

        let item = MosaicItem(
            id: "item",
            cellType: MosaicCell.self,
            value: "value",
            contentHash: 1,
            willDisplay: { _, value in
                events.append("will:\(value as? String ?? "")")
            },
            didEndDisplaying: { _, value in
                events.append("end:\(value as? String ?? "")")
            },
            didReconfigure: { _, value in
                events.append("reconfigure:\(value as? String ?? "")")
            },
            configure: { _, _ in }
        )

        let initialModel = MosaicModel {
            MosaicSection("section") {
                item
            }
        }

        view.apply(initialModel, animate: false)
        await flushMainQueue()

        #expect(view.collectionView.numberOfSections == 1)
        #expect(view.collectionView.numberOfItems(inSection: 0) == 1)

        let cell = MosaicCell()
        view.willDisplay(cell, at: indexPath)
        view.didEndDisplaying(cell, at: indexPath)

        let updatedModel = MosaicModel {
            MosaicSection("section") {
                MosaicItem(
                    id: "item",
                    cellType: MosaicCell.self,
                    value: "updated",
                    contentHash: 2,
                    didReconfigure: { _, value in
                        events.append("reconfigure:\(value as? String ?? "")")
                    },
                    configure: { _, _ in }
                )
            }
        }

        view.apply(updatedModel, animate: false)
        await flushMainQueue()

        #expect(events.contains("will:value"))
        #expect(events.contains("end:value"))
    }

    @Test
    func mosaicViewSelectionHighlightAndPrefetchHooksFlowThroughDelegateMethods() async {
        let recorder = EventRecorder()
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let collectionView = view.collectionView
        let indexPath = IndexPath(item: 0, section: 0)

        let item = selectionHookItem(recorder: recorder)

        view.apply(model(item: item), animate: false)
        await flushMainQueue()

        let results = selectionAndPrefetchResults(
            on: view,
            collectionView: collectionView,
            indexPath: indexPath
        )

        #expect(results.shouldHighlight)
        #expect(results.shouldSelect == false)
        #expect(results.shouldDeselect)
        #expect(recorder.events == [
            "didHighlight",
            "didUnhighlight",
            "shouldSelect",
            "didSelect",
            "shouldDeselect",
            "didDeselect",
            "prefetch:value",
            "cancel:value",
        ])
    }

    /// Swipe configurations are Mosaic-owned values on every platform, so the
    /// configuration an item supplies is asserted directly here. Bridging to
    /// UIKit is covered separately below.
    @Test
    func mosaicViewSuppliesSwipeActionsFromItem() {
        let item = MosaicItem(
            id: "item",
            cellType: MosaicCell.self,
            value: "value",
            contentHash: 1,
            configure: { _, _ in }
        )
        .leadingSwipeActionsConfiguration { value in
            MosaicSwipeActionsConfiguration(
                actions: [
                    MosaicSwipeAction(style: .normal, title: value as? String) { completion in
                        completion(true)
                    },
                ],
                performsFirstActionWithFullSwipe: false
            )
        }
        .onDelete(title: "Delete") { _ in }

        let leading = item.leadingSwipeActionsConfiguration?(item.value)
        let trailing = item.trailingSwipeActionsConfiguration?(item.value)

        #expect(leading?.actions.count == 1)
        #expect(leading?.actions.first?.title == "value")
        #expect(leading?.performsFirstActionWithFullSwipe == false)
        #expect(trailing?.actions.count == 1)
        #expect(trailing?.actions.first?.style == .destructive)
        #expect(trailing?.actions.first?.title == "Delete")
    }

    // Swipe actions are delivered through UIKit-only delegate callbacks; AppKit
    // has no swipe affordance, so configurations there are stored but inert.
    #if canImport(UIKit)
    @Test
    func mosaicViewBridgesItemSwipeActionsToUIKit() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let collectionView = view.collectionView
        let indexPath = IndexPath(item: 0, section: 0)

        let item = MosaicItem(
            id: "item",
            cellType: MosaicCell.self,
            value: "value",
            contentHash: 1,
            configure: { _, _ in }
        )
        .leadingSwipeActionsConfiguration { value in
            MosaicSwipeActionsConfiguration(
                actions: [
                    MosaicSwipeAction(style: .normal, title: value as? String) { completion in
                        completion(true)
                    },
                ],
                performsFirstActionWithFullSwipe: false
            )
        }
        .onDelete(title: "Delete") { _ in }

        let model = MosaicModel {
            MosaicSection("section", layout: .grid(columns: 1)) {
                item
            }
        }

        view.apply(model, animate: false)
        await flushMainQueue()

        let leading = view.collectionView(
            collectionView,
            leadingSwipeActionsConfigurationForItemAt: indexPath
        )
        let trailing = view.collectionView(
            collectionView,
            trailingSwipeActionsConfigurationForItemAt: indexPath
        )

        #expect(leading?.actions.count == 1)
        #expect(leading?.actions.first?.title == "value")
        #expect(leading?.performsFirstActionWithFullSwipe == false)
        #expect(trailing?.actions.count == 1)
        #expect(trailing?.actions.first?.style == .destructive)
        #expect(trailing?.actions.first?.title == "Delete")
    }

    @Test
    func mosaicViewDefersListSwipeActionsToListConfiguration() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let collectionView = view.collectionView
        let indexPath = IndexPath(item: 0, section: 0)

        let item = MosaicItem(
            id: "item",
            cellType: MosaicListCell.self,
            value: "value",
            contentHash: 1,
            configure: { _, _ in }
        )
        .onDelete(title: "Delete") { _ in }

        view.apply(model(item: item), animate: false)
        await flushMainQueue()

        let trailing = view.collectionView(
            collectionView,
            trailingSwipeActionsConfigurationForItemAt: indexPath
        )

        #expect(trailing == nil)
    }
    #endif

    @Test
    func mosaicViewDeleteItemKeepsResolvedStateAlignedWithSnapshot() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let model = MosaicModel {
            MosaicSection("section") {
                MosaicItem(
                    id: "one",
                    cellType: MosaicCell.self,
                    value: "one",
                    contentHash: 1,
                    configure: { _, _ in }
                )
                MosaicItem(
                    id: "two",
                    cellType: MosaicCell.self,
                    value: "two",
                    contentHash: 1,
                    configure: { _, _ in }
                )
            }
        }

        view.apply(model, animate: false)
        await flushMainQueue()

        var completionCount = 0
        view.deleteItem(at: IndexPath(item: 1, section: 0)) {
            completionCount += 1
        }
        await flushMainQueue()
        await flushMainQueue()

        let deletedId = MosaicIdentifier(
            SectionItemIdentifier(sectionId: "section", itemId: "two")
        )
        let resolvedIds = view.resolvedSection(at: 0)?.items.map(\.id) ?? []

        #expect(completionCount == 1)
        #expect(view.collectionView.numberOfItems(inSection: 0) == 1)
        #expect(resolvedIds == [AnyHashable("one")])
        #expect(view.resolvedItem(id: deletedId) == nil)
        #expect(view.hasPendingTransition == false)
    }

    @Test
    func mosaicViewHandlesRapidAnimatedSnapshotUpdates() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))

        for itemCount in 1...30 {
            let model = MosaicModel {
                MosaicSection("chat") {
                    (1...itemCount).map { itemId in
                        MosaicItem(
                            id: "m-\(itemId)",
                            cellType: MosaicCell.self,
                            value: itemId,
                            contentHash: itemId,
                            configure: { _, _ in }
                        )
                    }
                }
            }
            view.apply(model, animate: true)
            forceLayout(view)
        }

        await flushMainQueue()
        await flushMainQueue()

        #expect(view.collectionView.numberOfItems(inSection: 0) == 30)
        #expect(view.hasPendingTransition == false)
    }

    @Test
    func mosaicViewRegistersSectionDecorationViews() async {
        let decoration = MosaicDecorationRegistration(
            elementKind: "test-background",
            viewClass: TestDecorationView.self
        )
        let sectionLayout = MosaicDefaultLayout.list()
        sectionLayout.decorationItems = [
            .background(elementKind: decoration.elementKind),
        ]

        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let model = MosaicModel {
            MosaicSection(
                "section",
                layout: MosaicLayout(sectionLayout)
                    .decorated(by: decoration)
            ) {
                MosaicItem(
                    id: "item",
                    cellType: MosaicCell.self,
                    value: "value",
                    contentHash: 1,
                    configure: { _, _ in }
                )
            }
        }

        view.apply(model, animate: false)
        await flushMainQueue()

        #expect(view.isDecorationRegistered(decoration))
    }

    @Test
    func mosaicViewProvidesSectionSupplementaryViews() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let model = MosaicModel {
            MosaicSection(
                "section",
                layout: MosaicLayout.grid(columns: 1)
                    .sectionHeader(height: .absolute(44)),
                header: .header(TestSupplementaryView.self, "Header") { headerView, value in
                    headerView.renderedValue = value
                }
            ) {
                MosaicItem(
                    id: "item",
                    cellType: MosaicCell.self,
                    value: "value",
                    contentHash: 1,
                    configure: { _, _ in }
                )
            }
        }

        view.apply(model, animate: false)
        await flushMainQueue()

        let resolvedSupplementaryView = view.resolvedSupplementaryView(
            ofKind: MosaicCollectionView.elementKindSectionHeader,
            atSection: 0
        )
        let supplementaryView = TestSupplementaryView()
        resolvedSupplementaryView?.configure(
            supplementaryView,
            resolvedSupplementaryView?.value as Any
        )

        #expect(resolvedSupplementaryView?.elementKind == MosaicCollectionView.elementKindSectionHeader)
        #expect(supplementaryView.renderedValue == "Header")
    }
}

@MainActor
extension MosaicViewTests {
    @Test
    func supplementaryUIViewFactoriesHostPlainUIViews() {
        let header = MosaicSupplementaryView.header(
            TestHostedSupplementaryView.self,
            "Header"
        ) { headerView, value in
            headerView.renderedValue = value
        }

        let reusableView = MosaicCollectionReusableHostedView<TestHostedSupplementaryView>()
        header.configure(reusableView, header.value)

        #expect(header.viewType == MosaicCollectionReusableHostedView<TestHostedSupplementaryView>.self)
        #expect(reusableView.hostedView.superview === reusableView)
        #expect(reusableView.hostedView.renderedValue == "Header")
    }
}

private extension MosaicViewTests {
    func model(item: MosaicItem) -> MosaicModel {
        MosaicModel {
            MosaicSection("section") {
                item
            }
        }
    }

    func selectionHookItem(recorder: EventRecorder) -> MosaicItem {
        MosaicItem(
            id: "item",
            cellType: MosaicCell.self,
            value: "value",
            contentHash: 1,
            prefetchItemAt: { value in
                recorder.append("prefetch:\(value as? String ?? "")")
            },
            cancelPrefetchingForItemAt: { value in
                recorder.append("cancel:\(value as? String ?? "")")
            },
            shouldSelectItemAt: {
                recorder.append("shouldSelect")
                return false
            },
            didSelectItemAt: {
                recorder.append("didSelect")
            },
            shouldDeselectItemAt: {
                recorder.append("shouldDeselect")
                return true
            },
            didDeselectItemAt: {
                recorder.append("didDeselect")
            },
            didHighlightItemAt: {
                recorder.append("didHighlight")
            },
            didUnhighlightItemAt: {
                recorder.append("didUnhighlight")
            },
            configure: { _, _ in }
        )
    }

    func selectionAndPrefetchResults(
        on view: MosaicView,
        collectionView: MosaicCollectionView,
        indexPath: IndexPath
    ) -> SelectionResults {
        // AppKit's delegate is set-based where UIKit's is per-index-path, so the
        // same sequence of hooks is driven through each platform's shape.
        #if canImport(UIKit)
        let shouldHighlight = view.collectionView(collectionView, shouldHighlightItemAt: indexPath)
        view.collectionView(collectionView, didHighlightItemAt: indexPath)
        view.collectionView(collectionView, didUnhighlightItemAt: indexPath)
        let shouldSelect = view.collectionView(collectionView, shouldSelectItemAt: indexPath)
        view.collectionView(collectionView, didSelectItemAt: indexPath)
        let shouldDeselect = view.collectionView(collectionView, shouldDeselectItemAt: indexPath)
        view.collectionView(collectionView, didDeselectItemAt: indexPath)
        #else
        let indexPaths: Set<IndexPath> = [indexPath]
        let shouldHighlight = !view.collectionView(
            collectionView,
            shouldChangeItemsAt: indexPaths,
            to: .forSelection
        ).isEmpty
        view.collectionView(collectionView, didChangeItemsAt: indexPaths, to: .forSelection)
        view.collectionView(collectionView, didChangeItemsAt: indexPaths, to: .none)
        let shouldSelect = !view.collectionView(collectionView, shouldSelectItemsAt: indexPaths).isEmpty
        view.collectionView(collectionView, didSelectItemsAt: indexPaths)
        let shouldDeselect = !view.collectionView(collectionView, shouldDeselectItemsAt: indexPaths).isEmpty
        view.collectionView(collectionView, didDeselectItemsAt: indexPaths)
        #endif
        view.collectionView(collectionView, prefetchItemsAt: [indexPath])
        view.collectionView(collectionView, cancelPrefetchingForItemsAt: [indexPath])
        return SelectionResults(
            shouldHighlight: shouldHighlight,
            shouldSelect: shouldSelect,
            shouldDeselect: shouldDeselect
        )
    }
}
