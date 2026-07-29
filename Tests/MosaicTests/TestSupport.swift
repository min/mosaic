import Foundation
import MosaicCore
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

struct RefreshableTestValue: Hashable, MosaicRefreshable {
    let id: Int
    let title: String
    let metadata: String

    var mosaicRefreshValue: String {
        title
    }
}

struct ExplicitRefreshValue: Hashable {
    let title: String
    let isSelected: Bool
}

@MainActor
func flushMainQueue() async {
    await Task.yield()
    try? await Task.sleep(for: .milliseconds(20))
    await Task.yield()
}

/// Forces a synchronous layout pass on each view.
@MainActor
func forceLayout(_ views: MosaicPlatformView...) {
    for view in views {
        #if canImport(UIKit)
        view.layoutIfNeeded()
        #else
        view.layoutSubtreeIfNeeded()
        #endif
    }
}

/// Hosts `view` in an on-screen window so the collection view lays out and
/// dequeues real cells, runs `body`, then tears the host down.
@MainActor
func withVisibleHost(_ view: MosaicPlatformView, perform body: @MainActor () async -> Void) async {
    #if canImport(UIKit)
    let window = UIWindow(frame: view.bounds)
    window.addSubview(view)
    window.isHidden = false
    await body()
    window.isHidden = true
    #else
    // Touching `NSApplication.shared` initialises the app object the window
    // machinery expects in a test process.
    _ = NSApplication.shared
    let window = NSWindow(
        contentRect: view.bounds,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.contentView?.addSubview(view)
    window.orderFront(nil)
    await body()
    window.orderOut(nil)
    #endif
}

func assertInsets(
    _ insets: NSDirectionalEdgeInsets,
    top: CGFloat,
    leading: CGFloat,
    bottom: CGFloat,
    trailing: CGFloat
) {
    #expect(insets.top == top)
    #expect(insets.leading == leading)
    #expect(insets.bottom == bottom)
    #expect(insets.trailing == trailing)
}

struct TestValue: Hashable, Identifiable {
    let id: Int
    let title: String
}

final class TestCell: MosaicCell {
    private(set) var renderedValue: TestValue?

    func render(_ value: TestValue) {
        renderedValue = value
    }
}

final class TestListCell: MosaicListCell {}

final class MacroUIKitCell: MosaicCell {
    typealias Value = TestValue

    private(set) var renderedValue: Value?

    func render(value: Value) {
        renderedValue = value
    }
}

final class MacroUIKitListCell: MosaicListCell {
    typealias Value = TestValue

    private(set) var renderedValue: Value?

    func render(value: Value) {
        renderedValue = value
    }
}

final class MacroUIKitView: MosaicPlatformView {
    typealias Value = TestValue

    private(set) var renderedValue: Value?

    func render(value: Value) {
        renderedValue = value
    }
}

final class MacroUIKitListView: MosaicPlatformView {
    typealias Value = TestValue

    private(set) var renderedValue: Value?

    func render(value: Value) {
        renderedValue = value
    }
}

struct MacroValueRow: View {
    let value: TestValue

    var body: some View {
        Text(value.title)
    }
}

struct MacroCellRow: View {
    let value: TestValue

    var body: some View {
        Text(value.title)
    }
}

struct MacroListRow: View {
    let value: TestValue

    var body: some View {
        Text(value.title)
    }
}

struct MacroCustomListRow: View {
    let value: TestValue

    var body: some View {
        Text(value.title)
    }
}

struct MacroStringRow: View {
    let value: String

    var body: some View {
        Text(value)
    }
}

/// Mirrors macro expansion without loading the macro plugin into the iOS test bundle.
extension MacroUIKitCell {
    static func mosaicItem(id: AnyHashable, value: Value) -> TypedMosaicItem<MacroUIKitCell, Value> {
        MosaicItem.cell(MacroUIKitCell.self, id: id, value) { cell, value in
            cell.render(value: value)
        }
    }

    static func mosaicItem(_ value: Value) -> TypedMosaicItem<MacroUIKitCell, Value> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroUIKitListCell {
    static func mosaicItem(id: AnyHashable, value: Value) -> TypedMosaicItem<MacroUIKitListCell, Value> {
        MosaicItem.list(MacroUIKitListCell.self, id: id, value) { cell, value in
            cell.render(value: value)
        }
    }

    static func mosaicItem(_ value: Value) -> TypedMosaicItem<MacroUIKitListCell, Value> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroUIKitView {
    static func mosaicItem(
        id: AnyHashable,
        value: Value
    ) -> TypedMosaicItem<MosaicCollectionViewHostedViewCell<MacroUIKitView>, Value> {
        MosaicItem.cell(MosaicCollectionViewHostedViewCell<MacroUIKitView>.self, id: id, value) { cell, value in
            cell.hostedView.render(value: value)
        }
    }

    static func mosaicItem(
        _ value: Value
    ) -> TypedMosaicItem<MosaicCollectionViewHostedViewCell<MacroUIKitView>, Value> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroUIKitListView {
    static func mosaicItem(
        id: AnyHashable,
        value: Value
    ) -> TypedMosaicItem<MosaicCollectionViewHostedListCell<MacroUIKitListView>, Value> {
        MosaicItem.list(MosaicCollectionViewHostedListCell<MacroUIKitListView>.self, id: id, value) { cell, value in
            cell.hostedView.render(value: value)
        }
    }

    static func mosaicItem(
        _ value: Value
    ) -> TypedMosaicItem<MosaicCollectionViewHostedListCell<MacroUIKitListView>, Value> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroValueRow {
    static func mosaicItem(
        id: AnyHashable,
        value: TestValue
    ) -> TypedMosaicItem<MosaicCollectionViewCell<MacroValueRow>, TestValue> {
        MosaicItem.cell(
            MosaicCollectionViewCell<MacroValueRow>.self,
            id: id,
            value,
            content: Self.init(value:)
        )
    }

    static func mosaicItem(_ value: TestValue) -> TypedMosaicItem<MosaicCollectionViewCell<MacroValueRow>, TestValue> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroCellRow {
    static func mosaicItem(
        id: AnyHashable,
        value: TestValue,
        configure: @escaping @MainActor (TestCell, TestValue) -> Void = { _, _ in }
    ) -> TypedMosaicItem<TestCell, TestValue> {
        MosaicItem.cell(
            TestCell.self,
            id: id,
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }

    static func mosaicItem(
        _ value: TestValue,
        configure: @escaping @MainActor (TestCell, TestValue) -> Void = { _, _ in }
    ) -> TypedMosaicItem<TestCell, TestValue> {
        MosaicItem.cell(
            TestCell.self,
            id: MosaicItem.inferredId(value: value),
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }
}

extension MacroListRow {
    static func mosaicItem(
        id: AnyHashable,
        value: TestValue
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<MacroListRow>, TestValue> {
        MosaicItem.list(
            MosaicCollectionViewListCell<MacroListRow>.self,
            id: id,
            value,
            content: Self.init(value:)
        )
    }

    static func mosaicItem(
        _ value: TestValue
    ) -> TypedMosaicItem<MosaicCollectionViewListCell<MacroListRow>, TestValue> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

extension MacroCustomListRow {
    static func mosaicItem(
        id: AnyHashable,
        value: TestValue,
        configure: @escaping @MainActor (TestListCell, TestValue) -> Void = { _, _ in }
    ) -> TypedMosaicItem<TestListCell, TestValue> {
        MosaicItem.list(
            TestListCell.self,
            id: id,
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }

    static func mosaicItem(
        _ value: TestValue,
        configure: @escaping @MainActor (TestListCell, TestValue) -> Void = { _, _ in }
    ) -> TypedMosaicItem<TestListCell, TestValue> {
        MosaicItem.list(
            TestListCell.self,
            id: MosaicItem.inferredId(value: value),
            value,
            configure: configure,
            content: Self.init(value:)
        )
    }
}

extension MacroStringRow {
    static func mosaicItem(
        id: AnyHashable,
        value: String
    ) -> TypedMosaicItem<MosaicCollectionViewCell<MacroStringRow>, String> {
        MosaicItem.cell(
            MosaicCollectionViewCell<MacroStringRow>.self,
            id: id,
            value,
            content: Self.init(value:)
        )
    }

    static func mosaicItem(_ value: String) -> TypedMosaicItem<MosaicCollectionViewCell<MacroStringRow>, String> {
        mosaicItem(id: MosaicItem.inferredId(value: value), value: value)
    }
}

final class EventRecorder {
    private(set) var events: [String] = []

    func append(_ event: String) {
        events.append(event)
    }
}
