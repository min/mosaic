import MosaicCore
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
struct MosaicModelDSLTests {
    @Test
    func modelBuildersSupportConditionalsLoopsAndLookup() {
        let values = [
            TestValue(id: 1, title: "One"),
            TestValue(id: 2, title: "Two"),
        ]

        let model = MosaicModel {
            MosaicSection("primary", layout: .grid(columns: 2, spacing: 12)) {
                MosaicItem.cell(TestCell.self, values[0]) { cell, value in
                    cell.render(value)
                }
                if true {
                    MosaicItem.cell(values[1]) { value in
                        Text(value.title)
                    }
                }
                for value in values {
                    MosaicItem.cell(TestCell.self, id: "loop-\(value.id)", value)
                }
                [
                    MosaicItem.cell(TestCell.self, id: "array-1", values[0]),
                    MosaicItem.cell(TestCell.self, id: "array-2", values[1]),
                ]
            }

            if true {
                MosaicSection("secondary") {
                    MosaicItem.cell(TestCell.self, id: "secondary-\(values[0].id)", values[0])
                }
            }
        }

        #expect(model.sections.count == 2)
        #expect(model.sections[0].items.count == 6)
        #expect(model.sections[1].items.count == 1)
        #expect(model.item(itemId: values[0].id)?.id == AnyHashable(values[0].id))
        #expect(model.item(itemId: values[1].id, sectionId: "primary")?.id == AnyHashable(values[1].id))
        #expect(model.item(itemId: "missing") == nil)
        #expect(model.item(itemId: values[0].id, sectionId: "missing") == nil)
    }

    @Test
    func sectionsCompareAndHashByIdentifier() {
        let first = MosaicSection("shared", layout: .list()) {
            MosaicItem.cell(TestCell.self, TestValue(id: 1, title: "One"))
        }
        let second = MosaicSection("shared", layout: .carousel(itemHeight: .absolute(80))) {
            MosaicItem.cell(TestCell.self, TestValue(id: 2, title: "Two"))
        }

        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }
}

extension MosaicDSLTests {
    func makeTypedUIKitItem(value: TestValue, recorder: EventRecorder) -> MosaicItem {
        MosaicItem.cell(TestCell.self, value) { configuredCell, configuredValue in
            configuredCell.render(configuredValue)
        }
        .willDisplay { displayedCell, displayedValue in
            displayedCell.render(displayedValue)
            recorder.append("will:\(displayedValue.id)")
        }
        .didEndDisplaying { _, displayedValue in
            recorder.append("end:\(displayedValue.id)")
        }
        .didReconfigure { _, displayedValue in
            recorder.append("reconfigure:\(displayedValue.id)")
        }
        .prefetchItemAt { prefetchedValue in
            recorder.append("prefetch:\(prefetchedValue.id)")
        }
        .cancelPrefetchingForItemAt { canceledValue in
            recorder.append("cancel:\(canceledValue.id)")
        }
        .shouldSelectItemAt {
            recorder.append("shouldSelect")
            return false
        }
        .didSelectItemAt {
            recorder.append("didSelect")
        }
        .shouldDeselectItemAt {
            recorder.append("shouldDeselect")
            return true
        }
        .didDeselectItemAt {
            recorder.append("didDeselect")
        }
        .didHighlightItemAt {
            recorder.append("didHighlight")
        }
        .didUnhighlightItemAt {
            recorder.append("didUnhighlight")
        }
        .mosaicItem
    }

    func makeSwiftUIItem(value: TestValue, recorder: EventRecorder) -> MosaicItem {
        MosaicItem.cell(value) { storedValue in
            Text(storedValue.title)
        }
        .willDisplay { displayedValue in
            recorder.append("will:\(displayedValue.id)")
        }
        .didEndDisplaying { displayedValue in
            recorder.append("end:\(displayedValue.id)")
        }
        .didReconfigure { displayedValue in
            recorder.append("reconfigure:\(displayedValue.id)")
        }
        .prefetchItemAt { prefetchedValue in
            recorder.append("prefetch:\(prefetchedValue.id)")
        }
        .cancelPrefetchingForItemAt { canceledValue in
            recorder.append("cancel:\(canceledValue.id)")
        }
        .shouldSelectItemAt {
            recorder.append("shouldSelect")
            return true
        }
        .didSelectItemAt {
            recorder.append("didSelect")
        }
        .shouldDeselectItemAt {
            recorder.append("shouldDeselect")
            return false
        }
        .didDeselectItemAt {
            recorder.append("didDeselect")
        }
        .didHighlightItemAt {
            recorder.append("didHighlight")
        }
        .didUnhighlightItemAt {
            recorder.append("didUnhighlight")
        }
        .mosaicItem
    }

    func runTypedItemLifecycle(_ item: MosaicItem, cell: MosaicCell) -> (Bool?, Bool?) {
        item.configure(cell, item.value)
        item.willDisplay?(cell, item.value)
        item.didEndDisplaying?(cell, item.value)
        item.didReconfigure?(cell, item.value)
        item.prefetchItemAt?(item.value)
        item.cancelPrefetchingForItemAt?(item.value)
        let shouldSelect = item.shouldSelectItemAt?()
        item.didSelectItemAt?()
        let shouldDeselect = item.shouldDeselectItemAt?()
        item.didDeselectItemAt?()
        item.didHighlightItemAt?()
        item.didUnhighlightItemAt?()
        return (shouldSelect, shouldDeselect)
    }
}
