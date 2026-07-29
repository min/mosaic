import MosaicCore
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
struct MosaicDSLTests {
    @Test
    func refreshableItemUsesStableIdentityAndRenderedStateHash() {
        let value = RefreshableTestValue(id: 7, title: "Seven", metadata: "ignored")
        let item = MosaicItem.cell(TestCell.self, value).mosaicItem
        let metadataOnlyChange = RefreshableTestValue(id: 7, title: "Seven", metadata: "changed")
        let changedItem = MosaicItem.cell(TestCell.self, metadataOnlyChange).mosaicItem

        #expect(item.id == AnyHashable(value.id))
        #expect(item.contentHash == value.mosaicRefreshValue.hashValue)
        #expect(changedItem.contentHash == item.contentHash)
    }

    @Test
    func explicitRefreshProjectionIncludesCapturedViewState() {
        let value = TestValue(id: 7, title: "Seven")
        let refreshValue = ExplicitRefreshValue(title: value.title, isSelected: true)
        let item = MosaicItem.cell(TestCell.self, value, refreshOn: refreshValue).mosaicItem

        #expect(item.id == AnyHashable(value.id))
        #expect(item.contentHash == refreshValue.hashValue)
    }

    @Test
    func typedUIKitItemConfiguresCellAndInvokesTypedHooks() {
        let value = TestValue(id: 7, title: "Seven")
        let cell = TestCell()
        let recorder = EventRecorder()

        let item = makeTypedUIKitItem(value: value, recorder: recorder)
        let (shouldSelect, shouldDeselect) = runTypedItemLifecycle(item, cell: cell)

        #expect(cell.renderedValue == value)
        #expect(item.id == AnyHashable(value.id))
        #expect(item.contentHash == value.hashValue)
        #expect(item.cellType == TestCell.self)
        #expect(shouldSelect == false)
        #expect(shouldDeselect == true)
        #expect(recorder.events == [
            "will:7",
            "end:7",
            "reconfigure:7",
            "prefetch:7",
            "cancel:7",
            "shouldSelect",
            "didSelect",
            "shouldDeselect",
            "didDeselect",
            "didHighlight",
            "didUnhighlight",
        ])
    }

    @Test
    func typeErasedHelpersPreserveTypingAndIgnoreMismatches() {
        let value = TestValue(id: 4, title: "Four")
        let cell = TestCell()
        var callbackCount = 0

        let item = MosaicItem(
            id: "typed",
            cellType: TestCell.self,
            value: value,
            contentHash: value.hashValue,
            configure: { _, _ in }
        )
        .willDisplay(TestCell.self, TestValue.self) { displayedCell, displayedValue in
            displayedCell.render(displayedValue)
            callbackCount += 1
        }
        .didEndDisplaying(TestCell.self, TestValue.self) { _, _ in
            callbackCount += 1
        }
        .prefetchItemAt(TestValue.self) { _ in
            callbackCount += 1
        }
        .cancelPrefetchingForItemAt(TestValue.self) { _ in
            callbackCount += 1
        }

        item.willDisplay?(MosaicCell(), "wrong")
        item.didEndDisplaying?(MosaicCell(), "wrong")
        item.prefetchItemAt?("wrong")
        item.cancelPrefetchingForItemAt?("wrong")

        item.willDisplay?(cell, value)
        item.didEndDisplaying?(cell, value)
        item.prefetchItemAt?(value)
        item.cancelPrefetchingForItemAt?(value)

        #expect(callbackCount == 4)
        #expect(cell.renderedValue == value)
    }

    @Test
    func swiftUIItemUsesValueHooks() {
        let value = TestValue(id: 3, title: "Three")
        let recorder = EventRecorder()

        let item = makeSwiftUIItem(value: value, recorder: recorder)

        let hostingCell = MosaicCollectionViewCell<Text>()
        let (shouldSelect, shouldDeselect) = runTypedItemLifecycle(item, cell: hostingCell)

        #expect(item.id == AnyHashable(value.id))
        #expect(item.value as? TestValue == value)
        #expect(item.cellType == MosaicCollectionViewCell<Text>.self)
        #expect(shouldSelect == true)
        #expect(shouldDeselect == false)
        #expect(recorder.events == [
            "will:3",
            "end:3",
            "reconfigure:3",
            "prefetch:3",
            "cancel:3",
            "shouldSelect",
            "didSelect",
            "shouldDeselect",
            "didDeselect",
            "didHighlight",
            "didUnhighlight",
        ])
    }

    // `defaultContentConfiguration()` and `UIListContentConfiguration` belong to
    // UIKit's list cell, which AppKit has no counterpart for.
    #if canImport(UIKit)
    @Test
    func listUIKitItemUsesListCellTyping() {
        let value = TestValue(id: 11, title: "Eleven")
        let item = MosaicItem.list(TestListCell.self, value) { cell, configuredValue in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = configuredValue.title
            cell.contentConfiguration = configuration
        }
        .mosaicItem

        let cell = TestListCell()
        item.configure(cell, value)

        let configuration = cell.contentConfiguration as? UIListContentConfiguration

        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == TestListCell.self)
        #expect(configuration?.text == value.title)
    }
    #endif

    @Test
    func swiftUIItemUsesNonListCellByDefault() {
        let value = TestValue(id: 12, title: "Twelve")
        let item = MosaicItem.cell(value) { storedValue in
            Text(storedValue.title)
        }
        .mosaicItem

        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == MosaicCollectionViewCell<Text>.self)
    }

    @Test
    func cellTypeProvidesMosaicHelper() {
        let value = TestValue(id: 13, title: "Thirteen")
        let item = MosaicItem.cell(TestCell.self, value) { cell, configuredValue in
            cell.render(configuredValue)
        }
        .mosaicItem

        let cell = TestCell()
        item.configure(cell, value)

        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == TestCell.self)
        #expect(cell.renderedValue == value)
    }

    @Test
    func typedDeleteConvenienceBuildsDeleteSwipeAction() {
        let value = TestValue(id: 9, title: "Nine")
        let item = MosaicItem.cell(TestCell.self, value)
            .onDelete(title: "Remove") { _ in }
            .mosaicItem

        let configuration = item.trailingSwipeActionsConfiguration?(value)

        #expect(configuration?.actions.count == 1)
        #expect(configuration?.actions.first?.style == .destructive)
        #expect(configuration?.actions.first?.title == "Remove")
        #expect(configuration?.performsFirstActionWithFullSwipe == true)
    }

    @Test
    func generatedHelpersBuildHostedSwiftUIItems() {
        let value = TestValue(id: 21, title: "Twenty One")

        let inferredItem = MacroValueRow.mosaicItem(value).mosaicItem
        let explicitItem = MacroStringRow.mosaicItem(id: "hero", value: "Headline").mosaicItem

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(inferredItem.cellType == MosaicCollectionViewCell<MacroValueRow>.self)
        #expect(inferredItem.value as? TestValue == value)
        #expect(explicitItem.id == AnyHashable("hero"))
        #expect(explicitItem.value as? String == "Headline")
        #expect(explicitItem.cellType == MosaicCollectionViewCell<MacroStringRow>.self)
    }

    @Test
    func generatedHelpersBuildCustomCellItems() {
        let value = TestValue(id: 22, title: "Twenty Two")
        let item = MacroCellRow.mosaicItem(value) { cell, configuredValue in
            cell.render(configuredValue)
        }
        .mosaicItem

        let cell = TestCell()
        item.configure(cell, value)

        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == TestCell.self)
        #expect(cell.renderedValue == value)
    }

    @Test
    func generatedHelpersBuildListCellItems() {
        let value = TestValue(id: 23, title: "Twenty Three")
        let inferredItem = MacroListRow.mosaicItem(value).mosaicItem
        let explicitItem = MacroListRow.mosaicItem(id: "detail", value: value).mosaicItem
        let item = MacroCustomListRow.mosaicItem(value) { cell, configuredValue in
            _ = configuredValue
            // List-cell accessories are UIKit-only.
            #if canImport(UIKit)
            cell.accessories = [.disclosureIndicator()]
            #endif
        }
        .mosaicItem

        let cell = TestListCell()
        item.configure(cell, value)

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(inferredItem.cellType == MosaicCollectionViewListCell<MacroListRow>.self)
        #expect(explicitItem.id == AnyHashable("detail"))
        #expect(explicitItem.cellType == MosaicCollectionViewListCell<MacroListRow>.self)
        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == TestListCell.self)
        #if canImport(UIKit)
        #expect(cell.accessories.count == 1)
        #endif
    }

    @Test
    func generatedHelpersBuildCustomListCellItems() {
        let value = TestValue(id: 24, title: "Twenty Four")
        let item = MacroCustomListRow.mosaicItem(value) { cell, configuredValue in
            _ = configuredValue
            // List-cell accessories are UIKit-only.
            #if canImport(UIKit)
            cell.accessories = [.disclosureIndicator()]
            #endif
        }
        .mosaicItem

        let cell = TestListCell()
        item.configure(cell, value)

        #expect(item.id == AnyHashable(value.id))
        #expect(item.cellType == TestListCell.self)
        #if canImport(UIKit)
        #expect(cell.accessories.count == 1)
        #endif
    }
}

@MainActor
struct MosaicUIKitGeneratedHelperTests {
    @Test
    func generatedHelpersBuildUIKitCellItems() {
        let value = TestValue(id: 25, title: "Twenty Five")
        let inferredItem = MacroUIKitCell.mosaicItem(value).mosaicItem
        let explicitItem = MacroUIKitCell.mosaicItem(id: "settings", value: value).mosaicItem

        let cell = MacroUIKitCell()
        inferredItem.configure(cell, value)

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(inferredItem.cellType == MacroUIKitCell.self)
        #expect(explicitItem.id == AnyHashable("settings"))
        #expect(explicitItem.cellType == MacroUIKitCell.self)
        #expect(cell.renderedValue == value)
    }

    @Test
    func generatedHelpersBuildUIKitListCellItems() {
        let value = TestValue(id: 26, title: "Twenty Six")
        let inferredItem = MacroUIKitListCell.mosaicItem(value).mosaicItem
        let explicitItem = MacroUIKitListCell.mosaicItem(id: "profile", value: value).mosaicItem

        let cell = MacroUIKitListCell()
        inferredItem.configure(cell, value)

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(inferredItem.cellType == MacroUIKitListCell.self)
        #expect(explicitItem.id == AnyHashable("profile"))
        #expect(explicitItem.cellType == MacroUIKitListCell.self)
        #expect(cell.renderedValue == value)
    }

    @Test
    func generatedHelpersBuildUIKitViewItems() {
        let value = TestValue(id: 27, title: "Twenty Seven")
        let inferredItem = MacroUIKitView.mosaicItem(value).mosaicItem
        let explicitItem = MacroUIKitView.mosaicItem(id: "dashboard", value: value).mosaicItem

        let cell = MosaicCollectionViewHostedViewCell<MacroUIKitView>()
        inferredItem.configure(cell, value)
        let view = cell.hostedView

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(inferredItem.cellType == MosaicCollectionViewHostedViewCell<MacroUIKitView>.self)
        #expect(explicitItem.id == AnyHashable("dashboard"))
        #expect(explicitItem.cellType == MosaicCollectionViewHostedViewCell<MacroUIKitView>.self)
        #expect(view.renderedValue == value)
        #expect(view.superview === cell.hostedViewContainer)
    }

    @Test
    func generatedHelpersBuildUIKitListViewItems() {
        let value = TestValue(id: 28, title: "Twenty Eight")
        let inferredItem = MacroUIKitListView.mosaicItem(value).mosaicItem
        let explicitItem = MacroUIKitListView.mosaicItem(id: "library", value: value).mosaicItem

        let cell = MosaicCollectionViewHostedListCell<MacroUIKitListView>()
        inferredItem.configure(cell, value)
        let view = cell.hostedView

        #expect(inferredItem.id == AnyHashable(value.id))
        #expect(explicitItem.id == AnyHashable("library"))
        #expect(view.renderedValue == value)
        #expect(view.superview === cell.hostedViewContainer)
        #expect(inferredItem.cellType == MosaicCollectionViewHostedListCell<MacroUIKitListView>.self)
        #expect(explicitItem.cellType == MosaicCollectionViewHostedListCell<MacroUIKitListView>.self)
    }
}
