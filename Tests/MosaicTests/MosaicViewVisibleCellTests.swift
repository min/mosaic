import MosaicCore
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
struct MosaicViewVisibleCellTests {
    @Test
    func mosaicViewReturnsVisibleCellsForItemsWithoutDequeuing() async {
        let view = MosaicView(frame: .init(x: 0, y: 0, width: 320, height: 640))
        let value = TestValue(id: 1, title: "Visible")
        let item = MosaicItem.cell(TestCell.self, id: "item", value) { cell, value in
            cell.render(value)
        }
        let model = MosaicModel {
            MosaicSection(
                "section",
                layout: .grid(columns: 1, itemHeight: .absolute(44))
            ) {
                item
            }
        }

        await withVisibleHost(view) {
            view.apply(model, animate: false)
            await flushMainQueue()
            forceLayout(view, view.collectionView)
            await flushMainQueue()

            let visibleCell = view.visibleCell(itemId: "item", sectionId: "section")
            let typedCell = visibleCell as? TestCell

            #expect(typedCell?.renderedValue == value)
            #expect(visibleCell === typedCell)
            #expect(view.visibleCell(itemId: "missing", sectionId: "section") == nil)
        }
    }
}
